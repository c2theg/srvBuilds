#!/usr/bin/env bash
set -euo pipefail
VERSION="0.2.3"
LAST_UPDATED="2026-04-16"

# Great use-case is running this in a Proxmox VM with a Nvidia GPU connected via PCIx or Opulink


curl -O "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_ollama_in_containers.sh" # update yourself with each run

readonly PORT_OLLAMA=11434
readonly PORT_OPENWEBUI=3000

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

run_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    fail "This step requires root privileges, and sudo is not installed."
  fi
}

OS_NAME="$(uname -s)"
ARCH_NAME="$(uname -m)"
PLATFORM="unknown"
GPU_BACKEND="no-gpu"
STACK_DIR="/usr/share/ollama"
COMPOSE_FILE=""
OLLAMA_IMAGE="ollama/ollama:latest"
DOCKER_CMD=(docker)
COMPOSE_CMD=()

detect_platform_and_gpu() {
  case "${OS_NAME}" in
    Darwin)
      STACK_DIR="/usr/local/share/ollama"
      if [[ "${ARCH_NAME}" == "arm64" ]]; then
        PLATFORM="apple-silicon"
      else
        PLATFORM="apple-intel"
      fi
      GPU_BACKEND="no-gpu"
      ;;
    Linux)
      STACK_DIR="/usr/share/ollama"
      PLATFORM="linux"
      GPU_BACKEND="no-gpu"

      if command -v nvidia-smi >/dev/null 2>&1; then
        GPU_BACKEND="nvidia"
        return
      fi

      if command -v lspci >/dev/null 2>&1; then
        local gpu_info
        gpu_info="$(lspci -nn 2>/dev/null | grep -Ei 'VGA|3D|Display' || true)"

        if echo "${gpu_info}" | grep -qi 'nvidia'; then
          GPU_BACKEND="nvidia"
          return
        fi

        if echo "${gpu_info}" | grep -qiE 'AMD|Advanced Micro Devices|Radeon'; then
          GPU_BACKEND="amd"
          return
        fi
      fi
      ;;
    *)
      fail "Unsupported operating system: ${OS_NAME}"
      ;;
  esac
}

ensure_docker() {
  if command -v docker >/dev/null 2>&1; then
    return
  fi

  if [[ "${OS_NAME}" == "Linux" ]]; then
    log "Docker not found. Installing Docker Engine using get.docker.com..."
    curl -fsSL https://get.docker.com | run_root sh

    if command -v systemctl >/dev/null 2>&1; then
      run_root systemctl enable --now docker >/dev/null 2>&1 || true
    fi
  else
    fail "Docker is not installed. Install Docker Desktop first, then rerun this script."
  fi
}

set_docker_command() {
  DOCKER_CMD=(docker)

  if ! docker info >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
      DOCKER_CMD=(sudo docker)
    fi
  fi

  if ! "${DOCKER_CMD[@]}" info >/dev/null 2>&1; then
    fail "Cannot talk to Docker daemon. Start Docker and verify permissions."
  fi
}

set_compose_command() {
  if "${DOCKER_CMD[@]}" compose version >/dev/null 2>&1; then
    COMPOSE_CMD=("${DOCKER_CMD[@]}" compose)
    return
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    if [[ "${DOCKER_CMD[0]}" == "sudo" ]]; then
      COMPOSE_CMD=(sudo docker-compose)
    else
      COMPOSE_CMD=(docker-compose)
    fi
    return
  fi

  if [[ "${OS_NAME}" == "Linux" ]] && command -v apt-get >/dev/null 2>&1; then
    log "Docker Compose not found. Installing docker-compose-plugin..."
    run_root apt-get update
    run_root apt-get install -y docker-compose-plugin

    if "${DOCKER_CMD[@]}" compose version >/dev/null 2>&1; then
      COMPOSE_CMD=("${DOCKER_CMD[@]}" compose)
      return
    fi
  fi

  fail "Docker Compose is required but was not found."
}

select_ollama_image() {
  if [[ "${GPU_BACKEND}" == "amd" ]]; then
    OLLAMA_IMAGE="ollama/ollama:rocm"
  else
    OLLAMA_IMAGE="ollama/ollama:latest"
  fi
}

write_compose_file() {
  COMPOSE_FILE="${STACK_DIR}/docker-compose.yml"
  run_root mkdir -p "${STACK_DIR}"

  local env_extra=""
  local gpu_extra=""
  local image_line="image: ${OLLAMA_IMAGE}"

  if [[ "${GPU_BACKEND}" == "nvidia" ]]; then
    env_extra=$'      - NVIDIA_VISIBLE_DEVICES=all\n      - NVIDIA_DRIVER_CAPABILITIES=compute,utility'
    gpu_extra=$'    gpus: all'
  elif [[ "${GPU_BACKEND}" == "amd" ]]; then
    gpu_extra=$'    devices:\n      - /dev/kfd:/dev/kfd\n      - /dev/dri:/dev/dri\n    group_add:\n      - render\n      - video'
  fi

  local tmp_compose
  tmp_compose="$(mktemp)"

  cat > "${tmp_compose}" <<EOF_COMPOSE
services:
  ollama:
    container_name: "ollama"
    ${image_line}
    restart: unless-stopped
    ports:
      - "0.0.0.0:${PORT_OLLAMA}:${PORT_OLLAMA}"
    volumes:
      - ollama-data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
${env_extra}
${gpu_extra}
    healthcheck:
      test: ["CMD", "ollama", "list"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s

  open-webui:
    container_name: "ollama_openwebui"
    image: ghcr.io/open-webui/open-webui:main
    restart: unless-stopped
    depends_on:
      ollama:
        condition: service_healthy
    ports:
      - "0.0.0.0:${PORT_OPENWEBUI}:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:${PORT_OLLAMA}
    volumes:
      - open-webui-data:/app/backend/data

volumes:
  ollama-data:
  open-webui-data:
EOF_COMPOSE

  run_root cp "${tmp_compose}" "${COMPOSE_FILE}"
  rm -f "${tmp_compose}"
}

setup_linux_firewall_rfc1918() {
  if ! command -v iptables >/dev/null 2>&1; then
    log "WARNING: iptables not found; skipping RFC1918 firewall restriction for Docker ports."
    return
  fi

  local chain4="OLLAMA_RFC1918"
  local chain6="OLLAMA_IPV6_BLOCK"

  run_root iptables -N "${chain4}" 2>/dev/null || true
  run_root iptables -F "${chain4}"

  if ! run_root iptables -nL DOCKER-USER >/dev/null 2>&1; then
    run_root iptables -N DOCKER-USER 2>/dev/null || true
    run_root iptables -C FORWARD -j DOCKER-USER >/dev/null 2>&1 || run_root iptables -I FORWARD 1 -j DOCKER-USER
    run_root iptables -C DOCKER-USER -j RETURN >/dev/null 2>&1 || run_root iptables -A DOCKER-USER -j RETURN
  fi

  while run_root iptables -C DOCKER-USER -j "${chain4}" >/dev/null 2>&1; do
    run_root iptables -D DOCKER-USER -j "${chain4}"
  done
  run_root iptables -I DOCKER-USER 1 -j "${chain4}"

  for cidr in 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
    run_root iptables -A "${chain4}" -p tcp -s "${cidr}" --dport "${PORT_OLLAMA}" -j RETURN
    run_root iptables -A "${chain4}" -p tcp -s "${cidr}" --dport "${PORT_OPENWEBUI}" -j RETURN
  done

  run_root iptables -A "${chain4}" -p tcp --dport "${PORT_OLLAMA}" -j REJECT --reject-with tcp-reset
  run_root iptables -A "${chain4}" -p tcp --dport "${PORT_OPENWEBUI}" -j REJECT --reject-with tcp-reset
  run_root iptables -A "${chain4}" -j RETURN

  if command -v ip6tables >/dev/null 2>&1; then
    run_root ip6tables -N "${chain6}" 2>/dev/null || true
    run_root ip6tables -F "${chain6}"

    if ! run_root ip6tables -nL DOCKER-USER >/dev/null 2>&1; then
      run_root ip6tables -N DOCKER-USER 2>/dev/null || true
      run_root ip6tables -C FORWARD -j DOCKER-USER >/dev/null 2>&1 || run_root ip6tables -I FORWARD 1 -j DOCKER-USER
      run_root ip6tables -C DOCKER-USER -j RETURN >/dev/null 2>&1 || run_root ip6tables -A DOCKER-USER -j RETURN
    fi

    while run_root ip6tables -C DOCKER-USER -j "${chain6}" >/dev/null 2>&1; do
      run_root ip6tables -D DOCKER-USER -j "${chain6}"
    done
    run_root ip6tables -I DOCKER-USER 1 -j "${chain6}"

    run_root ip6tables -A "${chain6}" -p tcp -s ::1/128 --dport "${PORT_OLLAMA}" -j RETURN
    run_root ip6tables -A "${chain6}" -p tcp -s ::1/128 --dport "${PORT_OPENWEBUI}" -j RETURN
    run_root ip6tables -A "${chain6}" -p tcp --dport "${PORT_OLLAMA}" -j REJECT
    run_root ip6tables -A "${chain6}" -p tcp --dport "${PORT_OPENWEBUI}" -j REJECT
    run_root ip6tables -A "${chain6}" -j RETURN
  fi
}

setup_macos_firewall_rfc1918() {
  local anchor_name="com.ollama_rfc1918"
  local anchor_file="/etc/pf.anchors/${anchor_name}"
  local pf_conf="/etc/pf.conf"

  run_root mkdir -p /etc/pf.anchors

  run_root tee "${anchor_file}" >/dev/null <<EOF_PF
# Allow only RFC1918/private-space IPv4 sources to Ollama/OpenWebUI.
table <ollama_private_nets> const { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 }
pass in quick inet proto tcp from <ollama_private_nets> to any port { ${PORT_OLLAMA}, ${PORT_OPENWEBUI} }
block in quick inet proto tcp from any to any port { ${PORT_OLLAMA}, ${PORT_OPENWEBUI} }
EOF_PF

  if ! run_root grep -q "anchor \"${anchor_name}\"" "${pf_conf}"; then
    log "Adding PF anchor '${anchor_name}' to ${pf_conf}."
    run_root tee -a "${pf_conf}" >/dev/null <<EOF_PFCONF

anchor "${anchor_name}"
load anchor "${anchor_name}" from "${anchor_file}"
EOF_PFCONF
  fi

  run_root pfctl -f "${pf_conf}" >/dev/null
  run_root pfctl -E >/dev/null 2>&1 || true
}

apply_firewall_policy() {
  case "${OS_NAME}" in
    Linux)
      setup_linux_firewall_rfc1918
      ;;
    Darwin)
      setup_macos_firewall_rfc1918
      ;;
  esac
}

deploy_or_update_stack() {
  local compose_project="ollama-stack"

  log "Pulling latest images for Ollama and OpenWebUI..."
  if [[ "${GPU_BACKEND}" == "amd" ]]; then
    if ! "${COMPOSE_CMD[@]}" -p "${compose_project}" -f "${COMPOSE_FILE}" pull ollama; then
      log "AMD ROCm tag pull failed. Falling back to ollama/ollama:latest."
      OLLAMA_IMAGE="ollama/ollama:latest"
      write_compose_file
      "${COMPOSE_CMD[@]}" -p "${compose_project}" -f "${COMPOSE_FILE}" pull ollama
    fi
    "${COMPOSE_CMD[@]}" -p "${compose_project}" -f "${COMPOSE_FILE}" pull open-webui
  else
    "${COMPOSE_CMD[@]}" -p "${compose_project}" -f "${COMPOSE_FILE}" pull ollama open-webui
  fi

  log "Starting/updating containers (idempotent)."
  "${COMPOSE_CMD[@]}" -p "${compose_project}" -f "${COMPOSE_FILE}" up -d --remove-orphans
}

print_summary() {
  cat <<EOF_SUMMARY

Install/update complete.

Version:       ${VERSION}
Last Updated:  ${LAST_UPDATED}
OS:            ${OS_NAME}
Arch:          ${ARCH_NAME}
Platform:      ${PLATFORM}
GPU Backend:   ${GPU_BACKEND}
Compose File:  ${COMPOSE_FILE}

Bound ports:
- Ollama API:  0.0.0.0:${PORT_OLLAMA} (restricted to RFC1918/private source IPs)
- OpenWebUI:   0.0.0.0:${PORT_OPENWEBUI} (restricted to RFC1918/private source IPs)

Useful checks:
- ${DOCKER_CMD[*]} ps
- ${COMPOSE_CMD[*]} -p ollama-stack -f ${COMPOSE_FILE} logs -f

Add models to Ollama:
- ${DOCKER_CMD[*]} exec -it ollama ollama pull gemma4:e2b
- ${DOCKER_CMD[*]} exec -it ollama ollama pull gemma4:e4b

---- a little older ----
- ${DOCKER_CMD[*]} exec -it ollama ollama pull llama3.2:latest
- ${DOCKER_CMD[*]} exec -it ollama ollama pull qwen3.5:latest
- ${DOCKER_CMD[*]} exec -it ollama ollama list

API example (host):
- curl http://127.0.0.1:${PORT_OLLAMA}/api/tags
EOF_SUMMARY
}

main() {
  log "Installing/updating Ollama + OpenWebUI containers."
  detect_platform_and_gpu
  ensure_docker
  set_docker_command
  set_compose_command
  select_ollama_image
  write_compose_file
  apply_firewall_policy
  deploy_or_update_stack
  print_summary
}

main "$@"
