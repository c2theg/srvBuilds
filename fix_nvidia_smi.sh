#!/usr/bin/env bash
#---------------------------------------------------------------------------------------------------------
# fix_nvidia_smi.sh — diagnose + repair "nvidia-smi couldn't communicate with the
# NVIDIA driver" on a Proxmox VM with an NVIDIA GPU passed through (PCI passthrough).
# Written for/tested on Ubuntu 24.04 (apt-based); the diagnostics work on most
# modern Debian-derivatives, but Tier 4's reinstall step assumes apt + ubuntu-drivers.
#
# Version: 0.2.0
# Updated: 2026-08-18
# Updated by: AI (Claude)
#  - [2026-08-18 v0.2.0] Genericized for public release: dropped the org-specific
#    header and the hardcoded name of one particular updater script; the recurring-
#    updater detection in STEP 2 now matches generically on command patterns
#    ('apt upgrade'/'full-upgrade'/'ubuntu-drivers' in cron/timers) instead of one
#    specific script's filename, so it's useful regardless of what your own
#    automation is called.
#  - [2026-08-18 v0.1.0] Initial creation.
#
# Why a Proxmox/passthrough VM needs a different playbook than bare metal:
# "nvidia-smi keeps getting messed up" here is usually NOT plain driver corruption —
# it's almost always (a) an unattended apt upgrade rebuilding the DKMS module against
# a new driver/kernel version with nobody watching whether the build actually
# succeeded, or (b) the passed-through device not getting a clean reset across a VM
# restart. This script targets both: STEP 2 looks for (a) (any cron job or systemd
# timer that could be silently upgrading the driver), and Tier 3 attempts a live fix
# for (b) from inside the guest, without needing to touch the Proxmox host.
#
# What this does, in order (stops as soon as nvidia-smi works):
#   0. Confirms this is a VM with a passed-through GPU (context for everything else)
#   1. Snapshots current state (nvidia-smi, lspci binding, loaded modules)
#   2. Gathers root-cause evidence: dmesg NVRM/Xid errors, DKMS status, installed
#      package churn (apt history), and any cron job / systemd timer that could be
#      silently upgrading the driver
#   3. Tier 1: reload the kernel modules (cheapest; fixes a crashed-but-installed driver)
#   4. Tier 2: DKMS rebuild (fixes a kernel/module version mismatch after a kernel update)
#   5. Tier 3: guest-side PCI function-level reset (fixes a hung passthrough device
#      without needing a host reboot — most Turing-and-newer NVIDIA GPUs support FLR)
#   6. Tier 4 (asks first — pass -y to skip the prompt): clean purge + one deliberate
#      driver install, instead of repeated blind 'ubuntu-drivers autoinstall'
#   7. On success: apt-mark hold the driver package set so the next scheduled apt
#      upgrade (cron, unattended-upgrades, or anything else) can't silently swap it
#
# Usage:
#   sudo ./fix_nvidia_smi.sh          # interactive — asks before Tier 4 (purge+reinstall)
#   sudo ./fix_nvidia_smi.sh -y       # non-interactive — auto-approves Tier 4 if needed
#   sudo ./fix_nvidia_smi.sh --diagnose-only   # steps 0-2 only, no repair attempted
#---------------------------------------------------------------------------------------------------------
set -uo pipefail   # deliberately not -e: a failed diagnostic check must not abort the script

c_b=$'\033[1m'; c_g=$'\033[32m'; c_y=$'\033[33m'; c_r=$'\033[31m'; c_0=$'\033[0m'
log()  { printf '%s\n' "${c_g}[fix_nvidia_smi]${c_0} $*"; }
warn() { printf '%s\n' "${c_y}[fix_nvidia_smi] WARNING:${c_0} $*" >&2; }
err()  { printf '%s\n' "${c_r}[fix_nvidia_smi] ERROR:${c_0} $*" >&2; }
step() { printf '\n%s\n' "${c_b}== $* ==${c_0}"; }

AUTO_YES=0
DIAGNOSE_ONLY=0
for a in "$@"; do
  case "$a" in
    -y|--yes)            AUTO_YES=1 ;;
    --diagnose-only)     DIAGNOSE_ONLY=1 ;;
    -h|--help)
      awk '/^#!/{next} /^#---/{c++; if(c==2) exit; next} /^#/{sub(/^# ?/,""); print}' "$0"
      exit 0 ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  err "Run as root: sudo $0 $*"
  exit 1
fi

printf '%s\n' "${c_b}fix_nvidia_smi.sh v0.2.0${c_0}"

# ─────────────────────────── 0. confirm the environment ───────────────────────────
step "Environment"
VIRT="$(systemd-detect-virt 2>/dev/null || echo unknown)"
log "systemd-detect-virt: ${VIRT}"
if [ "${VIRT}" = "kvm" ] || [ "${VIRT}" = "qemu" ]; then
  log "Confirmed: this is a KVM/QEMU VM (Proxmox), not bare metal."
  warn "That changes the diagnosis: 'nvidia-smi keeps getting messed up' on a GPU-"
  warn "passthrough VM is usually NOT plain driver corruption — it's almost always"
  warn "(a) the DKMS module getting rebuilt against a new kernel/driver version by"
  warn "an unattended apt upgrade, or (b) the passed-through device not getting a"
  warn "clean reset across a VM restart. This script targets both; STEP 2 below"
  warn "looks specifically for (a), and Tier 3 (STEP 5) attempts a live fix for (b)"
  warn "from inside the guest, without needing to touch the Proxmox host."
else
  warn "systemd-detect-virt did not report kvm/qemu (got '${VIRT}') — if this really"
  warn "is bare metal, some of this script's framing (esp. Tier 3's PCI reset) is"
  warn "still safe to run but less likely to be the actual fix."
fi

GPU_PCI="$(lspci -nn 2>/dev/null | grep -i nvidia | grep -iE 'vga|3d controller' | awk '{print $1}' | head -1)"
if [ -z "${GPU_PCI}" ]; then
  err "No NVIDIA GPU found in 'lspci' at all — the device isn't visible to this VM"
  err "right now. That's a HOST-side problem (Proxmox VM hardware config / PCI"
  err "passthrough), not something this script can fix from inside the guest."
  err "Check on the Proxmox host: qm config <vmid> | grep hostpci"
  exit 1
fi
log "GPU PCI address: ${GPU_PCI} ($(lspci -s "${GPU_PCI}" | cut -d: -f3-))"

# ─────────────────────────── 1. current state ──────────────────────────────────────
step "Current state"
if nvidia-smi >/tmp/fixnv_smi_out 2>&1; then
  log "nvidia-smi already works:"
  sed 's/^/    /' /tmp/fixnv_smi_out
  log "Nothing to fix. Jumping to the pinning step to make sure it stays working."
  ALREADY_WORKING=1
else
  ALREADY_WORKING=0
  log "nvidia-smi output:"
  sed 's/^/    /' /tmp/fixnv_smi_out
fi

log "PCI kernel driver binding:"
lspci -k -s "${GPU_PCI}" | sed 's/^/    /'
BOUND_DRIVER="$(lspci -k -s "${GPU_PCI}" | awk -F': ' '/Kernel driver in use/{print $2}')"
log "Kernel driver in use: ${BOUND_DRIVER:-<none>}"

log "Loaded nvidia kernel modules:"
lsmod | grep -i nvidia | sed 's/^/    /' || echo "    (none loaded)"

log "Device nodes:"
ls -la /dev/nvidia* 2>/dev/null | sed 's/^/    /' || echo "    (none present)"

# ─────────────────────────── 2. root-cause evidence ────────────────────────────────
step "Root-cause evidence"

log "Recent NVRM/Xid messages in dmesg (a real driver crash shows here):"
dmesg 2>/dev/null | grep -iE 'nvrm|nvidia|xid' | tail -30 | sed 's/^/    /' || echo "    (none — or dmesg needs a wider ring buffer / this is a fresh boot)"

log "DKMS status (module built for the WRONG kernel is a classic recurring cause):"
RUNNING_KERNEL="$(uname -r)"
log "  Running kernel: ${RUNNING_KERNEL}"
if command -v dkms >/dev/null 2>&1; then
  dkms status 2>/dev/null | sed 's/^/    /' || echo "    (dkms status returned nothing)"
else
  warn "  dkms not installed — the driver may be the non-DKMS/precompiled variant, or missing entirely."
fi

log "Installed nvidia/libnvidia packages:"
dpkg -l 2>/dev/null | grep -iE 'nvidia' | awk '{printf "    %-4s %-45s %s\n", $1, $2, $3}'

HELD="$(apt-mark showhold 2>/dev/null)"
if [ -n "${HELD}" ]; then
  log "Currently held packages (apt upgrade will skip these):"
  echo "${HELD}" | sed 's/^/    /'
else
  log "No packages currently held — nothing is protecting the driver from the next apt upgrade."
fi

log "Recent apt history touching nvidia (shows the actual install/remove churn):"
{ zgrep -iEh 'nvidia' /var/log/apt/history.log /var/log/apt/history.log.*.gz 2>/dev/null; \
  grep -iE 'nvidia' /var/log/apt/history.log 2>/dev/null; } | tail -40 | sed 's/^/    /' \
  || echo "    (no apt history found, or no nvidia-related entries)"

log "Checking for scheduled jobs that could be re-triggering this (cron + systemd timers):"
FOUND_CULPRIT=0
CRON_PATTERN='apt (upgrade|full-upgrade|dist-upgrade)|ubuntu-drivers|apt-get (upgrade|full-upgrade|dist-upgrade)'
for cronsrc in "/var/spool/cron/crontabs/root" "/etc/crontab" /etc/cron.d/*; do
  [ -f "${cronsrc}" ] || continue
  if grep -qE "${CRON_PATTERN}" "${cronsrc}" 2>/dev/null; then
    warn "  ${cronsrc} runs something that looks like a system/driver updater:"
    grep -nE "${CRON_PATTERN}" "${cronsrc}" | sed 's/^/      /'
    FOUND_CULPRIT=1
  fi
done
if crontab -l 2>/dev/null | grep -qE "${CRON_PATTERN}"; then
  warn "  root's crontab runs something that looks like a system/driver updater:"
  crontab -l 2>/dev/null | grep -nE "${CRON_PATTERN}" | sed 's/^/      /'
  FOUND_CULPRIT=1
fi
if systemctl list-timers --all 2>/dev/null | grep -qi 'apt-daily-upgrade\|unattended'; then
  warn "  apt-daily-upgrade.timer / unattended-upgrades is active on this box — an"
  warn "  independent path that can upgrade the driver even if no cron job does."
  warn "  Check: systemctl status unattended-upgrades apt-daily-upgrade.timer"
  FOUND_CULPRIT=1
fi
if [ "${FOUND_CULPRIT}" -eq 1 ]; then
  warn "  Any of the above running unattended is the most common reason a passthrough"
  warn "  VM's driver 'keeps getting messed up over and over' — a new driver package"
  warn "  means a fresh DKMS rebuild with nobody watching whether it actually worked."
  warn "  Once this script gets nvidia-smi working again, it apt-mark holds the"
  warn "  driver packages so none of the above can silently swap them out."
else
  log "  No obvious recurring updater found. If this keeps happening anyway, check"
  log "  for anything else on a schedule: systemctl list-timers --all | less"
fi

if [ "${DIAGNOSE_ONLY}" -eq 1 ]; then
  log "Diagnose-only mode — stopping here."
  exit 0
fi
if [ "${ALREADY_WORKING}" -eq 1 ]; then
  : # already working — fall straight through to the pinning step below
else

# ─────────────────────────── 3. tier 1: reload modules ─────────────────────────────
step "Tier 1 — reload kernel modules"
HOLDERS="$(fuser -v /dev/nvidia* 2>&1 | grep -v '^$' || true)"
if [ -n "${HOLDERS}" ]; then
  warn "Processes currently holding /dev/nvidia* open (module reload may fail until"
  warn "these exit — usually a docker container using --gpus):"
  echo "${HOLDERS}" | sed 's/^/    /'
fi
for mod in nvidia_uvm nvidia_drm nvidia_modeset nvidia; do
  rmmod "${mod}" 2>/dev/null && log "  unloaded ${mod}" || true
done
modprobe nvidia 2>/dev/null && log "  loaded nvidia" || warn "  modprobe nvidia failed — module likely isn't installed/built (see Tier 2)"
if nvidia-smi >/tmp/fixnv_smi_out 2>&1; then
  log "Fixed by a module reload. nvidia-smi:"
  sed 's/^/    /' /tmp/fixnv_smi_out
else

# ─────────────────────────── 4. tier 2: dkms rebuild ────────────────────────────────
step "Tier 2 — DKMS rebuild for the running kernel"
if command -v dkms >/dev/null 2>&1; then
  log "Running: dkms autoinstall (rebuilds any module not yet built for ${RUNNING_KERNEL})"
  dkms autoinstall 2>&1 | sed 's/^/    /'
  modprobe nvidia 2>/dev/null || true
else
  warn "dkms not installed — skipping (apt install dkms if this box should have it)."
fi
if nvidia-smi >/tmp/fixnv_smi_out 2>&1; then
  log "Fixed by a DKMS rebuild. nvidia-smi:"
  sed 's/^/    /' /tmp/fixnv_smi_out
else

# ─────────────────────────── 5. tier 3: guest-side PCI reset ───────────────────────
step "Tier 3 — PCI function-level reset (fixes a hung passthrough device)"
RESET_FILE="/sys/bus/pci/devices/0000:${GPU_PCI}/reset"
if [ -w "${RESET_FILE}" ]; then
  log "Resetting ${GPU_PCI} via ${RESET_FILE} …"
  for mod in nvidia_uvm nvidia_drm nvidia_modeset nvidia; do rmmod "${mod}" 2>/dev/null || true; done
  echo 1 > "${RESET_FILE}" 2>/tmp/fixnv_reset_err
  if [ -s /tmp/fixnv_reset_err ]; then
    warn "Reset write failed:"; sed 's/^/    /' /tmp/fixnv_reset_err
  else
    log "Reset issued."
  fi
  sleep 2
  modprobe nvidia 2>/dev/null || true
else
  warn "${RESET_FILE} not writable/present — this GPU (or this kernel's vfio/PCI"
  warn "config) doesn't expose a guest-triggerable reset. Not fatal — falls through"
  warn "to Tier 4 below."
fi
if nvidia-smi >/tmp/fixnv_smi_out 2>&1; then
  log "Fixed by a PCI reset. nvidia-smi:"
  sed 's/^/    /' /tmp/fixnv_smi_out
else

# ─────────────────────────── 5b. tier 4: clean reinstall ───────────────────────────
step "Tier 4 — clean purge + one deliberate driver install"
warn "This is the most invasive step: it purges every nvidia*/libnvidia* package"
warn "and reinstalls ONE explicit version (not a blind 'autoinstall' re-run, which"
warn "is what likely got this box into a flip-flopping state in the first place)."
PROCEED=0
if [ "${AUTO_YES}" -eq 1 ]; then
  PROCEED=1
else
  read -r -p "Proceed with purge + reinstall? [y/N] " ans
  case "${ans}" in [yY]*) PROCEED=1 ;; esac
fi

if [ "${PROCEED}" -eq 1 ]; then
  log "Purging existing nvidia packages…"
  apt-mark unhold $(dpkg -l | awk '/^.i.*nvidia/{print $2}') >/dev/null 2>&1 || true
  apt-get purge -y '*nvidia*' >/dev/null 2>&1 || true
  apt-get autoremove -y >/dev/null 2>&1 || true

  apt-get update
  apt-get install -y ubuntu-drivers-common

  log "Detected drivers (recommended marked):"
  ubuntu-drivers devices | sed 's/^/    /'
  RECOMMENDED_PKG="$(ubuntu-drivers devices 2>/dev/null | awk '/recommended/{for(i=1;i<=NF;i++) if ($i ~ /^nvidia-driver-/) print $i}' | head -1)"

  if [ -n "${RECOMMENDED_PKG}" ]; then
    log "Installing exactly one driver package: ${RECOMMENDED_PKG}"
    apt-get install -y "${RECOMMENDED_PKG}"
  else
    warn "Could not parse a specific recommended package — falling back to 'ubuntu-drivers autoinstall'."
    ubuntu-drivers autoinstall
  fi

  command -v dkms >/dev/null 2>&1 && dkms autoinstall 2>&1 | sed 's/^/    /'
  modprobe nvidia 2>/dev/null || true

  if nvidia-smi >/tmp/fixnv_smi_out 2>&1; then
    log "Driver reinstalled and working:"
    sed 's/^/    /' /tmp/fixnv_smi_out
  else
    err "Still not working after a clean reinstall. nvidia-smi:"
    sed 's/^/    /' /tmp/fixnv_smi_out
    err "This usually means a reboot is required (new kernel module needs the"
    err "device re-initialized) — reboot the VM, then re-run this script."
    err ""
    err "If it's STILL broken after a reboot: the device likely isn't cleanly"
    err "passed through THIS boot at the hypervisor level — that's Proxmox-side,"
    err "not fixable from in here. On the Proxmox host: qm config <vmid> | grep"
    err "hostpci, and check the host's own 'dmesg | grep -i vfio' for reset errors."
    exit 1
  fi
else
  err "Skipped (declined). Re-run with -y to auto-approve, or fix manually:"
  err "  apt-get purge -y '*nvidia*' && apt-get autoremove -y"
  err "  ubuntu-drivers devices   # pick one, then: apt-get install -y <package>"
  exit 1
fi

fi  # tier 3
fi  # tier 2
fi  # tier 1
fi  # already-working

# ─────────────────────────── 6. pin it ──────────────────────────────────────────────
step "Pinning the driver so it stops flip-flopping"
NVIDIA_PKGS="$(dpkg -l | awk '/^.i.*nvidia/{print $2}')"
if [ -n "${NVIDIA_PKGS}" ]; then
  log "Holding these packages (apt upgrade / full-upgrade will now skip them):"
  echo "${NVIDIA_PKGS}" | sed 's/^/    /'
  # shellcheck disable=SC2086
  apt-mark hold ${NVIDIA_PKGS} >/dev/null
  log "Done. This is what stops a scheduled apt upgrade — cron, unattended-upgrades,"
  log "or anything else — from silently pulling in the next driver point release"
  log "and rebuilding DKMS against it unattended."
  log ""
  log "To intentionally upgrade later: apt-mark unhold ${NVIDIA_PKGS}, upgrade,"
  log "then re-run this script to re-pin whatever version you land on."
else
  warn "No installed nvidia packages found to hold — unexpected if nvidia-smi just"
  warn "reported success above; double-check with: dpkg -l | grep nvidia"
fi

log "Final state:"
nvidia-smi
