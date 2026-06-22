#!/bin/bash
#------------------------------------------------------------
#  * Copyright (c) 2001-2026 Christopher Gray
#  * All rights reserved.  Proprietary and Confidential.
# Version: 0.1.1
# Updated: 6/21/2026
#------------------------------------------------------------
#
# Finds every container on this host (docker-compose managed or
# plain `docker run`) using a given image, pulls the new version,
# recreates each one with its original configuration, health-checks
# it, and automatically rolls back any container that fails its
# health check. Asks for confirmation before touching anything.
#
# Usage:
#   ./update_docker_image.sh nginx          # any tag of nginx
#   ./update_docker_image.sh nginx:alpine   # only that exact tag
#
# Install:
#   curl -fsSL -o "update_docker_image.sh" \
#       "https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_docker_image.sh" \
#       && chmod u+x update_docker_image.sh
#
#------------------------------------------------------------

set -u

IMAGE_ARG="${1:-}"
if [ -z "$IMAGE_ARG" ]; then
    echo "Usage: $0 <image>[:tag]"
    echo "Example: $0 nginx"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

ROLLBACK_DIR="/var/log/docker_image_update"
mkdir -p "$ROLLBACK_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
SAFE_NAME="$(echo "$IMAGE_ARG" | tr '/:' '_')"
ROLLBACK_LOG="$ROLLBACK_DIR/${SAFE_NAME}_${TIMESTAMP}.log"

# --- Strip the tag (not the registry port) off an image reference ---
strip_tag() {
    local ref="${1%@*}"
    local last_segment="${ref##*/}"
    if [[ "$last_segment" == *:* ]]; then
        local tag="${last_segment##*:}"
        echo "${ref%:"$tag"}"
    else
        echo "$ref"
    fi
}

# --- Does a container's image reference match what the user asked for? ---
image_matches() {
    local container_image="$1"
    if [[ "$IMAGE_ARG" == *:* ]]; then
        [ "$container_image" = "$IMAGE_ARG" ]
    else
        [ "$(strip_tag "$container_image")" = "$IMAGE_ARG" ]
    fi
}

# --- Wait for a container to report healthy, or just stay running if it has no healthcheck ---
wait_for_healthy() {
    local id_or_name="$1"
    local timeout="${2:-60}"
    local has_health
    has_health="$(docker inspect --format '{{if .Config.Healthcheck}}yes{{end}}' "$id_or_name" 2>/dev/null)"
    local waited=0
    if [ "$has_health" = "yes" ]; then
        while [ "$waited" -lt "$timeout" ]; do
            status="$(docker inspect --format '{{.State.Health.Status}}' "$id_or_name" 2>/dev/null)"
            case "$status" in
                healthy) return 0 ;;
                unhealthy) return 1 ;;
            esac
            sleep 2
            waited=$((waited + 2))
        done
        return 1
    else
        sleep 10
        [ "$(docker inspect --format '{{.State.Running}}' "$id_or_name" 2>/dev/null)" = "true" ]
    fi
}

echo "Scanning containers for image '$IMAGE_ARG'..."
mapfile -t ALL_IDS < <(docker ps -a --format '{{.ID}}')

MATCH_IDS=()
for cid in "${ALL_IDS[@]}"; do
    img="$(docker inspect --format '{{.Config.Image}}' "$cid" 2>/dev/null)"
    [ -z "$img" ] && continue
    if image_matches "$img"; then
        MATCH_IDS+=("$cid")
    fi
done

if [ "${#MATCH_IDS[@]}" -eq 0 ]; then
    echo "No containers found using image '$IMAGE_ARG'. Nothing to do."
    exit 0
fi

# --- Gather per-container info up front ---
declare -A C_NAME C_IMAGE C_DIGEST C_COMPOSE C_WORKDIR C_SERVICE

echo ""
echo "-----------------------------------------------------------------------"
echo "The following containers use image '$IMAGE_ARG':"
echo "-----------------------------------------------------------------------"
for cid in "${MATCH_IDS[@]}"; do
    name="$(docker inspect --format '{{.Name}}' "$cid" | sed 's#^/##')"
    img="$(docker inspect --format '{{.Config.Image}}' "$cid")"
    digest="$(docker inspect --format '{{.Image}}' "$cid")"
    project="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' "$cid" 2>/dev/null)"
    workdir="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$cid" 2>/dev/null)"
    service="$(docker inspect --format '{{index .Config.Labels "com.docker.compose.service"}}' "$cid" 2>/dev/null)"

    C_NAME[$cid]="$name"
    C_IMAGE[$cid]="$img"
    C_DIGEST[$cid]="$digest"
    C_WORKDIR[$cid]="$workdir"
    C_SERVICE[$cid]="$service"

    if [ -n "$project" ] && [ -n "$workdir" ]; then
        C_COMPOSE[$cid]="1"
        echo "  $name  ($img)  [compose: $service in $workdir]"
    else
        C_COMPOSE[$cid]="0"
        echo "  $name  ($img)  [plain docker-run]"
    fi
done
echo "-----------------------------------------------------------------------"
echo ""

read -r -p "Proceed with updating ${#MATCH_IDS[@]} container(s)? [y/N] " CONFIRM
case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *) echo "Aborted. No changes made."; exit 0 ;;
esac

# --- Capture rollback info BEFORE touching anything ---
{
    echo "# Rollback log for image '$IMAGE_ARG' - $(date)"
} > "$ROLLBACK_LOG"

declare -A C_RUNLIKE
for cid in "${MATCH_IDS[@]}"; do
    if [ "${C_COMPOSE[$cid]}" = "1" ]; then
        echo "COMPOSE|$cid|${C_NAME[$cid]}|${C_IMAGE[$cid]}|${C_DIGEST[$cid]}|${C_WORKDIR[$cid]}|${C_SERVICE[$cid]}" >> "$ROLLBACK_LOG"
    else
        # Use runlike to reconstruct the exact original `docker run` command
        # instead of hand-rebuilding flags from `docker inspect` - it's a
        # well-established trick and far less error-prone for arbitrary
        # env/volumes/ports/network combinations.
        runlike_cmd="$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike "${C_NAME[$cid]}" 2>/dev/null)"
        C_RUNLIKE[$cid]="$runlike_cmd"
        echo "PLAIN|$cid|${C_NAME[$cid]}|${C_IMAGE[$cid]}|${C_DIGEST[$cid]}|$runlike_cmd" >> "$ROLLBACK_LOG"
    fi
done
echo "Rollback info saved to $ROLLBACK_LOG"
echo ""

# --- Pull each distinct image:tag actually in use ---
declare -A PULLED
for cid in "${MATCH_IDS[@]}"; do
    img="${C_IMAGE[$cid]}"
    if [ -z "${PULLED[$img]:-}" ]; then
        echo "Pulling $img..."
        docker pull "$img"
        PULLED[$img]="1"
    fi
done
echo ""

# --- Recreate + health check + auto-rollback, straight through ---
declare -a SUMMARY=()

for cid in "${MATCH_IDS[@]}"; do
    name="${C_NAME[$cid]}"
    img="${C_IMAGE[$cid]}"
    old_digest="${C_DIGEST[$cid]}"
    action="none"
    result="unknown"

    if [ "${C_COMPOSE[$cid]}" = "1" ]; then
        workdir="${C_WORKDIR[$cid]}"
        service="${C_SERVICE[$cid]}"
        echo "Updating compose service '$service' in $workdir..."
        ( cd "$workdir" && docker compose pull "$service" && docker compose up -d --no-deps "$service" )

        if wait_for_healthy "$name" 60; then
            result="healthy"
        else
            echo "  Health check failed for $name - rolling back to previous image..."
            override_file="$workdir/docker-compose.override.ROLLBACK-PINNED.yml"
            {
                echo "services:"
                echo "  ${service}:"
                echo "    image: ${old_digest}"
            } > "$override_file"
            ( cd "$workdir" && docker compose -f docker-compose.yml -f "$override_file" up -d --no-deps "$service" )
            if wait_for_healthy "$name" 30; then
                result="rolled back (healthy)"
            else
                result="rolled back (still unhealthy - manual intervention needed)"
            fi
            action="rolled back - pinned at $override_file"
        fi
    else
        runlike_cmd="${C_RUNLIKE[$cid]:-}"
        if [ -z "$runlike_cmd" ]; then
            echo "Skipping $name - could not capture its original docker run command (is assaflavie/runlike reachable?)."
            SUMMARY+=("$name|$img|SKIPPED - could not capture run command|none")
            continue
        fi

        echo "Updating plain docker-run container '$name'..."
        docker stop "$cid" >/dev/null 2>&1
        docker rm "$cid" >/dev/null 2>&1
        eval "$runlike_cmd"

        if wait_for_healthy "$name" 60; then
            result="healthy"
        else
            echo "  Health check failed for $name - rolling back to previous image..."
            rollback_cmd="${runlike_cmd/$img/$old_digest}"
            docker stop "$name" >/dev/null 2>&1
            docker rm "$name" >/dev/null 2>&1
            eval "$rollback_cmd"
            if wait_for_healthy "$name" 30; then
                result="rolled back (healthy)"
            else
                result="rolled back (still unhealthy - manual intervention needed)"
            fi
            action="rolled back to previous digest"
        fi
    fi

    SUMMARY+=("$name|$img|$result|$action")
done

echo ""
echo "-----------------------------------------------------------------------"
echo "Update summary for '$IMAGE_ARG':"
echo "-----------------------------------------------------------------------"
printf '%-30s %-22s %-40s %s\n' "CONTAINER" "IMAGE" "RESULT" "ACTION"
ANY_ROLLBACK=0
for row in "${SUMMARY[@]}"; do
    IFS='|' read -r r_name r_img r_result r_action <<< "$row"
    printf '%-30s %-22s %-40s %s\n' "$r_name" "$r_img" "$r_result" "$r_action"
    case "$r_result" in
        *"rolled back"*|*SKIPPED*) ANY_ROLLBACK=1 ;;
    esac
done
echo "-----------------------------------------------------------------------"
echo "Rollback log: $ROLLBACK_LOG"

if [ "$ANY_ROLLBACK" = "1" ]; then
    exit 1
fi
exit 0
