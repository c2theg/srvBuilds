#!/usr/bin/env bash
set -Eeuo pipefail

echo "
 _____             _         _    _          _                                   
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|                                  
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _                                   
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|                                  
                                     |___|                                       
                                                                                 
 _____ _       _     _           _              _____    __    _____             
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _ 
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|

\r\n \r\n

"

VERSION="2.1.0"

SCRIPT_PATH="$(readlink -f -- "$0" 2>/dev/null || realpath "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)"

# ---------------------------------------------------------------------------
# Backup configuration
# Adjust these defaults before enabling the timer on a real server.
# ---------------------------------------------------------------------------

SOURCE_DIRS=(
    "/etc"
    "/home"
    "/root"
    "/usr/local"
    "/opt"
    "/srv"
)
BACKUP_ROOT="/srv/backups/sys_cleanup_snapshots"
SNAPSHOT_PREFIX="backup"
LOG_FILE="/var/log/sys_cleanup_backup.log"
LOCK_FILE="/var/lock/sys_cleanup_backup.lock"
STATE_FILE="/var/lib/sys_cleanup_backup/last_successful_backup.state"
EXCLUDES_FILE="/etc/sys_cleanup/backup-excludes.txt"
RETENTION_COUNT=4
BACKUP_MIN_DAYS=14
BACKUP_ROOT_MARKER_NAME=".sys_cleanup_backup_root"

# Leave self-update disabled by default. A local customized script should not
# overwrite itself from a remote URL unless you explicitly re-enable it.
ENABLE_SELF_UPDATE=false
SELF_UPDATE_URL="https://raw.githubusercontent.com/c2theg/srvBuilds/master/sys_cleanup.sh"

# Restore examples:
#   rsync -aHAX /srv/backups/sys_cleanup_snapshots/snapshots/backup-2026-04-05_07-00-00/etc/nginx/nginx.conf /etc/nginx/nginx.conf
#   rsync -aHAX /srv/backups/sys_cleanup_snapshots/snapshots/backup-2026-04-05_07-00-00/home/ubuntu/ /home/ubuntu/

# ---------------------------------------------------------------------------
# Runtime flags
# ---------------------------------------------------------------------------

RUN_MODE="cleanup"
DRY_RUN=false
FORCE_BACKUP=false

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------

LOG_FILE_READY=false
BACKUP_ROOT_REAL=""
SNAPSHOT_DIR=""
SNAPSHOT_DIR_REAL=""
INCOMPLETE_SNAPSHOT_DIR=""
LOCK_FD=""
LOCK_DIR_FALLBACK=""
SUMMARY=()

# ---------------------------------------------------------------------------
# Root requirement
# ---------------------------------------------------------------------------

require_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        echo "sys_cleanup.sh must be run as root." >&2
        echo "Manual cleanup run : sudo bash $0" >&2
        echo "Manual backup run  : sudo bash $0 --backup-only --force" >&2
        echo "Root cron for cleanup: sudo crontab -e" >&2
        exit 1
    fi
}

require_root

# Keep the existing `sudo ...` call sites working when already running as root.
sudo() { "$@"; }

# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------

timestamp() { date '+%Y-%m-%d %H:%M:%S %Z'; }

log_line() {
    local level="$1"
    shift
    local line
    line="[$(timestamp)] [$level] $*"
    printf '%s\n' "$line"
    if $LOG_FILE_READY; then
        printf '%s\n' "$line" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

log_info() { log_line "INFO" "$@"; }
log_warn() { log_line "WARN" "$@"; }
log_error() { log_line "ERROR" "$@"; }

die() {
    log_error "$@"
    exit 1
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

resolve_path_any() {
    readlink -f -- "$1" 2>/dev/null || realpath -m -- "$1"
}

resolve_path_existing() {
    readlink -f -- "$1" 2>/dev/null || realpath -e -- "$1"
}

path_is_same_or_under() {
    local candidate="$1"
    local parent="$2"
    [ "$candidate" = "$parent" ] || [[ "$candidate" == "$parent/"* ]]
}

free_space() { df -P -B1 / | awk 'NR==2 {print $4}'; }
ram_used() { free -b | awk '/Mem/ {print $3}'; }

usage() {
    cat <<EOF
Usage:
  $0
  $0 --backup-only [--dry-run] [--force]
  $0 --prune-only [--dry-run]
  $0 --help

Modes:
  default         Run the cleanup workflow only.
  --backup-only   Run the rsync snapshot backup workflow only.
  --prune-only    Run retention pruning only; do not create a new snapshot.

Options:
  --dry-run       Pass --dry-run to rsync and log prune actions without deleting.
  --force         Ignore the ${BACKUP_MIN_DAYS}-day backup wait window.
  --help          Show this help text.
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --backup-only)
                RUN_MODE="backup"
                ;;
            --prune-only)
                RUN_MODE="prune"
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --force)
                FORCE_BACKUP=true
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
        shift
    done

    if [ "$RUN_MODE" = "cleanup" ] && { $DRY_RUN || $FORCE_BACKUP; }; then
        die "--dry-run and --force are only valid with --backup-only or --prune-only"
    fi
}

cleanup_on_exit() {
    if [ -n "${INCOMPLETE_SNAPSHOT_DIR:-}" ] && [ -d "$INCOMPLETE_SNAPSHOT_DIR" ]; then
        rm -rf -- "$INCOMPLETE_SNAPSHOT_DIR" 2>/dev/null || true
        log_warn "Removed incomplete snapshot directory: $INCOMPLETE_SNAPSHOT_DIR"
    fi

    if [ -n "${LOCK_FD:-}" ]; then
        eval "exec ${LOCK_FD}>&-" 2>/dev/null || true
        LOCK_FD=""
    fi

    if [ -n "${LOCK_DIR_FALLBACK:-}" ] && [ -d "$LOCK_DIR_FALLBACK" ]; then
        rmdir "$LOCK_DIR_FALLBACK" 2>/dev/null || true
        LOCK_DIR_FALLBACK=""
    fi
}

on_error() {
    local exit_code=$?
    local line_no="$1"
    local command_text="${2:-unknown}"
    log_error "Command failed at line ${line_no} with exit ${exit_code}: ${command_text}"
    exit "$exit_code"
}

trap 'on_error $LINENO "$BASH_COMMAND"' ERR
trap cleanup_on_exit EXIT

# ---------------------------------------------------------------------------
# Cleanup helpers
# ---------------------------------------------------------------------------

LIVE_LOG_DELETE_BYTES=$((10 * 1024 * 1024))
LIVE_LOG_REMOVED_LAST=0
MAILBOX_TRIMMED_LAST=0

delete_live_logs_over_limit() {
    LIVE_LOG_REMOVED_LAST=0
    local log_path size_bytes
    for log_path in "$@"; do
        [ -f "$log_path" ] || continue
        size_bytes=$(stat -c '%s' "$log_path" 2>/dev/null || echo 0)
        if [ "${size_bytes:-0}" -gt "$LIVE_LOG_DELETE_BYTES" ]; then
            rm -f -- "$log_path" 2>/dev/null || true
            if [ ! -e "$log_path" ]; then
                LIVE_LOG_REMOVED_LAST=$(( LIVE_LOG_REMOVED_LAST + 1 ))
                echo "    [>] removed live log >10MiB: $log_path"
            fi
        fi
    done
}

delete_rotated_logs_in_dir() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -type f \
        \( -name "*.log.*" -o -name "*.gz" -o -name "*.old" \) \
        -delete 2>/dev/null || true
}

delete_live_logs_in_dir_over_limit() {
    LIVE_LOG_REMOVED_LAST=0
    local dir="$1" log_path size_bytes
    [ -d "$dir" ] || return 0
    while IFS= read -r -d '' log_path; do
        size_bytes=$(stat -c '%s' "$log_path" 2>/dev/null || echo 0)
        if [ "${size_bytes:-0}" -gt "$LIVE_LOG_DELETE_BYTES" ]; then
            rm -f -- "$log_path" 2>/dev/null || true
            if [ ! -e "$log_path" ]; then
                LIVE_LOG_REMOVED_LAST=$(( LIVE_LOG_REMOVED_LAST + 1 ))
                echo "    [>] removed live log >10MiB: $log_path"
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -type f -print0 2>/dev/null)
}

trim_mailbox_to_limit() {
    MAILBOX_TRIMMED_LAST=0
    local mailbox_path="$1" size_bytes temp_file new_size
    [ -f "$mailbox_path" ] || return 0

    size_bytes=$(stat -c '%s' "$mailbox_path" 2>/dev/null || echo 0)
    [ "${size_bytes:-0}" -gt "$LIVE_LOG_DELETE_BYTES" ] || return 0

    temp_file=$(mktemp /tmp/sys_cleanup_mailbox.XXXXXX 2>/dev/null || true)
    if [ -z "${temp_file:-}" ]; then
        echo "    [!] could not create temp file for mailbox trim: $mailbox_path"
        return 0
    fi

    if LC_ALL=C awk -v max_bytes="$LIVE_LOG_DELETE_BYTES" '
        function flush_msg() {
            if (in_msg) {
                msg_count++
                msgs[msg_count] = msg
                lens[msg_count] = length(msg)
                msg = ""
            }
        }
        /^From / {
            flush_msg()
            in_msg = 1
            msg = $0 ORS
            next
        }
        {
            if (in_msg) {
                msg = msg $0 ORS
            }
        }
        END {
            flush_msg()
            if (msg_count == 0) {
                exit 2
            }

            kept_bytes = 0
            start_idx = msg_count
            for (i = msg_count; i >= 1; i--) {
                if (kept_bytes + lens[i] > max_bytes) {
                    break
                }
                start_idx = i
                kept_bytes += lens[i]
            }

            if (kept_bytes > 0) {
                for (i = start_idx; i <= msg_count; i++) {
                    printf "%s", msgs[i]
                }
                exit 0
            }

            exit 3
        }
    ' "$mailbox_path" > "$temp_file"; then
        if cat -- "$temp_file" > "$mailbox_path"; then
            new_size=$(stat -c '%s' "$mailbox_path" 2>/dev/null || echo 0)
            if [ "${new_size:-0}" -le "$LIVE_LOG_DELETE_BYTES" ]; then
                MAILBOX_TRIMMED_LAST=1
                echo "    [>] trimmed mailbox to newest full messages <=10MiB: $mailbox_path"
            fi
        fi
    elif tail -c "$LIVE_LOG_DELETE_BYTES" -- "$mailbox_path" > "$temp_file" \
        && cat -- "$temp_file" > "$mailbox_path"; then
        MAILBOX_TRIMMED_LAST=1
        echo "    [>] byte-trimmed mailbox to newest 10MiB: $mailbox_path"
    fi

    rm -f -- "$temp_file"
}

report_freed() {
    local label="$1" before="$2" after="$3"
    local diff=$(( after - before ))
    if [ "$diff" -gt 1048576 ]; then
        local human
        human=$(numfmt --to=iec-i --suffix=B "$diff")
        echo "  [+] $label - freed $human"
        SUMMARY+=("$label|$human")
    fi
}

show_cleanup_banner() {
    local now
    now=$(date)
    echo "Running sys_cleanup.sh at $now"
    cat <<EOF

Version:  $VERSION

Cleanup Cron Example:
sudo crontab -e
10 2 * * 7 /bin/bash $SCRIPT_PATH

Backup Timer:
See deployments/systemd/sys_cleanup_backup.service
See deployments/systemd/sys_cleanup_backup.timer

EOF
}

# ---------------------------------------------------------------------------
# Backup helpers
# ---------------------------------------------------------------------------

snapshot_name_is_valid() {
    local snapshot_name="$1"
    [[ "$snapshot_name" =~ ^${SNAPSHOT_PREFIX}-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]
}

source_to_snapshot_rel() {
    local source_path="$1"
    if [ "$source_path" = "/" ]; then
        printf 'rootfs\n'
    else
        printf '%s\n' "${source_path#/}"
    fi
}

build_snapshot_name() {
    # Snapshot names use local server time to match the systemd schedule and logs.
    printf '%s-%s\n' "$SNAPSHOT_PREFIX" "$(date '+%Y-%m-%d_%H-%M-%S')"
}

require_backup_command() {
    have_cmd "$1" || die "Required command not found: $1"
}

validate_backup_config() {
    [[ "$SNAPSHOT_PREFIX" =~ ^[A-Za-z0-9._-]+$ ]] || die "SNAPSHOT_PREFIX contains unsafe characters: $SNAPSHOT_PREFIX"
    [ -n "$BACKUP_ROOT" ] || die "BACKUP_ROOT cannot be empty"
    [ "$BACKUP_ROOT" != "/" ] || die "BACKUP_ROOT cannot be /"
    [ -n "$LOG_FILE" ] || die "LOG_FILE cannot be empty"
    [ -n "$LOCK_FILE" ] || die "LOCK_FILE cannot be empty"
    [ -n "$STATE_FILE" ] || die "STATE_FILE cannot be empty"
    [ "${#SOURCE_DIRS[@]}" -gt 0 ] || die "SOURCE_DIRS must contain at least one source directory"
    [ "$RETENTION_COUNT" -ge 1 ] || die "RETENTION_COUNT must be >= 1"
    [ "$BACKUP_MIN_DAYS" -ge 1 ] || die "BACKUP_MIN_DAYS must be >= 1"

    require_backup_command rsync
    require_backup_command find
    require_backup_command sort
    require_backup_command stat

    local source_dir source_real
    for source_dir in "${SOURCE_DIRS[@]}"; do
        [ -d "$source_dir" ] || die "SOURCE_DIR does not exist or is not a directory: $source_dir"
        source_real=$(resolve_path_existing "$source_dir")
        [ -n "$source_real" ] || die "Failed to resolve SOURCE_DIR: $source_dir"
    done
}

prepare_backup_environment() {
    local source_dir source_real

    validate_backup_config

    BACKUP_ROOT_REAL=$(resolve_path_any "$BACKUP_ROOT")
    [ -n "$BACKUP_ROOT_REAL" ] || die "Failed to resolve BACKUP_ROOT: $BACKUP_ROOT"
    [ "$BACKUP_ROOT_REAL" != "/" ] || die "Resolved BACKUP_ROOT cannot be /"
    [ -d "$BACKUP_ROOT_REAL" ] || die "BACKUP_ROOT must exist before running backups: $BACKUP_ROOT_REAL"
    [ -f "$BACKUP_ROOT_REAL/$BACKUP_ROOT_MARKER_NAME" ] || die \
        "Refusing to use BACKUP_ROOT without marker file: $BACKUP_ROOT_REAL/$BACKUP_ROOT_MARKER_NAME"

    SNAPSHOT_DIR="$BACKUP_ROOT_REAL/snapshots"
    mkdir -p -- "$SNAPSHOT_DIR"
    SNAPSHOT_DIR_REAL=$(resolve_path_any "$SNAPSHOT_DIR")
    path_is_same_or_under "$SNAPSHOT_DIR_REAL" "$BACKUP_ROOT_REAL" || die \
        "Snapshot directory escaped BACKUP_ROOT: $SNAPSHOT_DIR_REAL"

    mkdir -p -- "$(dirname "$LOG_FILE")" "$(dirname "$LOCK_FILE")" "$(dirname "$STATE_FILE")"
    touch "$LOG_FILE"
    chmod 0600 "$LOG_FILE" 2>/dev/null || true
    LOG_FILE_READY=true

    log_info "Backup root: $BACKUP_ROOT_REAL"
    log_info "Snapshot directory: $SNAPSHOT_DIR_REAL"
    log_info "Retention count: $RETENTION_COUNT"
    log_info "Minimum days between successful backups: $BACKUP_MIN_DAYS"

    for source_dir in "${SOURCE_DIRS[@]}"; do
        source_real=$(resolve_path_existing "$source_dir")
        if path_is_same_or_under "$source_real" "$BACKUP_ROOT_REAL"; then
            die "SOURCE_DIR cannot be inside BACKUP_ROOT: $source_real"
        fi
    done

    if [ -f "$EXCLUDES_FILE" ]; then
        log_info "Using excludes file: $EXCLUDES_FILE"
    else
        log_warn "Excludes file not found; proceeding without excludes: $EXCLUDES_FILE"
    fi
}

acquire_backup_lock() {
    if have_cmd flock; then
        exec {LOCK_FD}>"$LOCK_FILE"
        flock -n "$LOCK_FD" || die "Another backup/prune run is already active: $LOCK_FILE"
        log_info "Acquired flock lock: $LOCK_FILE"
    else
        LOCK_DIR_FALLBACK="${LOCK_FILE}.d"
        mkdir "$LOCK_DIR_FALLBACK" 2>/dev/null || die \
            "Another backup/prune run is already active: $LOCK_DIR_FALLBACK"
        log_warn "flock not available; using mkdir lock: $LOCK_DIR_FALLBACK"
    fi
}

list_completed_snapshots() {
    [ -d "$SNAPSHOT_DIR_REAL" ] || return 0
    find "$SNAPSHOT_DIR_REAL" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
        | while read -r snapshot_name; do
            snapshot_name_is_valid "$snapshot_name" && printf '%s\n' "$snapshot_name"
        done \
        | LC_ALL=C sort
}

latest_completed_snapshot() {
    local latest_snapshot=""
    while read -r snapshot_name; do
        latest_snapshot="$snapshot_name"
    done < <(list_completed_snapshots)
    printf '%s\n' "$latest_snapshot"
}

read_last_success_epoch() {
    [ -f "$STATE_FILE" ] || return 1
    awk -F= '/^last_success_epoch=/{print $2; exit}' "$STATE_FILE"
}

backup_is_due() {
    if $FORCE_BACKUP; then
        log_info "--force supplied; bypassing ${BACKUP_MIN_DAYS}-day gate"
        return 0
    fi

    local last_success_epoch now_epoch next_due_epoch
    if ! last_success_epoch=$(read_last_success_epoch 2>/dev/null); then
        log_info "No previous successful backup state found; backup is due"
        return 0
    fi

    if ! [[ "$last_success_epoch" =~ ^[0-9]+$ ]]; then
        log_warn "State file is invalid; proceeding with a backup: $STATE_FILE"
        return 0
    fi

    now_epoch=$(date +%s)
    next_due_epoch=$(( last_success_epoch + BACKUP_MIN_DAYS * 86400 ))
    if [ "$now_epoch" -ge "$next_due_epoch" ]; then
        return 0
    fi

    log_info "Skipping backup: last successful run is still inside the ${BACKUP_MIN_DAYS}-day window"
    log_info "Next eligible backup time: $(date -d "@$next_due_epoch" '+%Y-%m-%d %H:%M:%S %Z')"
    return 1
}

write_last_success_state() {
    local snapshot_name="$1"
    local temp_state
    temp_state=$(mktemp "${STATE_FILE}.XXXXXX")
    {
        printf 'last_success_epoch=%s\n' "$(date +%s)"
        printf 'last_success_iso=%s\n' "$(date -Is)"
        printf 'last_success_snapshot=%s\n' "$snapshot_name"
    } > "$temp_state"
    mv -f -- "$temp_state" "$STATE_FILE"
    chmod 0600 "$STATE_FILE" 2>/dev/null || true
}

ensure_safe_snapshot_delete_target() {
    local snapshot_name="$1"
    local snapshot_path="$SNAPSHOT_DIR_REAL/$snapshot_name"

    snapshot_name_is_valid "$snapshot_name" || die "Refusing to delete non-snapshot directory name: $snapshot_name"
    [ -d "$snapshot_path" ] || die "Refusing to delete missing snapshot directory: $snapshot_path"
    path_is_same_or_under "$snapshot_path" "$SNAPSHOT_DIR_REAL" || die \
        "Refusing to delete path outside SNAPSHOT_DIR: $snapshot_path"
}

prune_old_snapshots() {
    local snapshots=()
    local snapshot_name delete_count i

    while read -r snapshot_name; do
        [ -n "$snapshot_name" ] && snapshots+=("$snapshot_name")
    done < <(list_completed_snapshots)

    if [ "${#snapshots[@]}" -le "$RETENTION_COUNT" ]; then
        log_info "Retention check: ${#snapshots[@]} completed snapshot(s), nothing to prune"
        return 0
    fi

    delete_count=$(( ${#snapshots[@]} - RETENTION_COUNT ))
    for (( i=0; i<delete_count; i++ )); do
        snapshot_name="${snapshots[$i]}"
        ensure_safe_snapshot_delete_target "$snapshot_name"
        if $DRY_RUN; then
            log_info "[dry-run] would remove old snapshot: $SNAPSHOT_DIR_REAL/$snapshot_name"
        else
            log_info "Removing old snapshot: $SNAPSHOT_DIR_REAL/$snapshot_name"
            rm -rf -- "$SNAPSHOT_DIR_REAL/$snapshot_name"
        fi
    done
}

append_source_scoped_exclude() {
    local source_real="$1"
    local target_path="$2"
    local target_real rel_path

    [ -n "$target_path" ] || return 0
    target_real=$(resolve_path_any "$target_path")
    if path_is_same_or_under "$target_real" "$source_real"; then
        rel_path="${target_real#"$source_real"}"
        rel_path="${rel_path#/}"
        [ -n "$rel_path" ] || return 0
        printf '/%s\n' "$rel_path"
    fi
}

run_rsync_for_source() {
    local source_real="$1"
    local previous_snapshot="$2"
    local rel_path dest_dir previous_dir
    local -a rsync_args extra_excludes

    rel_path=$(source_to_snapshot_rel "$source_real")
    dest_dir="$INCOMPLETE_SNAPSHOT_DIR/$rel_path"
    mkdir -p -- "$dest_dir"

    rsync_args=(
        -aHAX
        --numeric-ids
        # --delete is safe here because each run writes into a fresh temporary
        # snapshot directory before the final rename.
        --delete
    )

    if [ -n "$previous_snapshot" ]; then
        previous_dir="$SNAPSHOT_DIR_REAL/$previous_snapshot/$rel_path"
        if [ -d "$previous_dir" ]; then
            rsync_args+=( "--link-dest=$previous_dir" )
        fi
    fi

    if [ -f "$EXCLUDES_FILE" ]; then
        rsync_args+=( "--exclude-from=$EXCLUDES_FILE" )
    fi

    while read -r exclude_rule; do
        [ -n "$exclude_rule" ] && extra_excludes+=("$exclude_rule")
    done < <(
        append_source_scoped_exclude "$source_real" "$BACKUP_ROOT_REAL"
        append_source_scoped_exclude "$source_real" "$LOG_FILE"
        append_source_scoped_exclude "$source_real" "$LOCK_FILE"
        append_source_scoped_exclude "$source_real" "$STATE_FILE"
    )

    local exclude_rule
    for exclude_rule in "${extra_excludes[@]}"; do
        rsync_args+=( "--exclude=$exclude_rule" )
    done

    if $DRY_RUN; then
        rsync_args+=( --dry-run --itemize-changes )
    fi

    log_info "Syncing source: $source_real -> $dest_dir"
    rsync "${rsync_args[@]}" "$source_real"/ "$dest_dir"/
}

write_snapshot_metadata() {
    local snapshot_dir="$1"
    local metadata_file="$snapshot_dir/.snapshot-info"
    {
        printf 'created_at_local=%s\n' "$(timestamp)"
        printf 'created_at_iso=%s\n' "$(date -Is)"
        printf 'created_by=%s\n' "$SCRIPT_PATH"
        printf 'snapshot_prefix=%s\n' "$SNAPSHOT_PREFIX"
        printf 'dry_run=%s\n' "$DRY_RUN"
        printf 'retention_count=%s\n' "$RETENTION_COUNT"
        printf 'source_dirs=%s\n' "${SOURCE_DIRS[*]}"
    } > "$metadata_file"
}

create_snapshot_backup() {
    local snapshot_name previous_snapshot

    if ! backup_is_due; then
        prune_old_snapshots
        return 0
    fi

    snapshot_name=$(build_snapshot_name)
    while [ -e "$SNAPSHOT_DIR_REAL/$snapshot_name" ] || [ -e "$SNAPSHOT_DIR_REAL/.incomplete-$snapshot_name" ]; do
        sleep 1
        snapshot_name=$(build_snapshot_name)
    done

    INCOMPLETE_SNAPSHOT_DIR="$SNAPSHOT_DIR_REAL/.incomplete-$snapshot_name"
    mkdir -p -- "$INCOMPLETE_SNAPSHOT_DIR"

    previous_snapshot=$(latest_completed_snapshot)
    if [ -n "$previous_snapshot" ]; then
        log_info "Using --link-dest against previous snapshot: $previous_snapshot"
    else
        log_info "No previous snapshot found; first backup will be a full copy"
    fi

    local source_dir source_real
    for source_dir in "${SOURCE_DIRS[@]}"; do
        source_real=$(resolve_path_existing "$source_dir")
        run_rsync_for_source "$source_real" "$previous_snapshot"
    done

    write_snapshot_metadata "$INCOMPLETE_SNAPSHOT_DIR"

    if $DRY_RUN; then
        log_info "Dry run complete; no snapshot was committed"
        rm -rf -- "$INCOMPLETE_SNAPSHOT_DIR"
        INCOMPLETE_SNAPSHOT_DIR=""
        prune_old_snapshots
        return 0
    fi

    mv -- "$INCOMPLETE_SNAPSHOT_DIR" "$SNAPSHOT_DIR_REAL/$snapshot_name"
    INCOMPLETE_SNAPSHOT_DIR=""
    write_last_success_state "$snapshot_name"
    log_info "Snapshot completed successfully: $SNAPSHOT_DIR_REAL/$snapshot_name"
    prune_old_snapshots
}

run_backup_mode() {
    prepare_backup_environment
    acquire_backup_lock

    case "$RUN_MODE" in
        backup)
            log_info "Starting backup-only mode"
            create_snapshot_backup
            ;;
        prune)
            log_info "Starting prune-only mode"
            prune_old_snapshots
            ;;
        *)
            die "Unsupported backup mode: $RUN_MODE"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Cleanup workflow
# ---------------------------------------------------------------------------

run_cleanup() {
    local start_free_space start_ram_used end_free_space end_ram_used
    local total_disk_diff total_ram_diff
    local _B _A _RAM_B _RAM_A _ram_diff _ram_human
    local _held _truncated fd_num proc_fd _swap_cleared SWAP_USED RAM_FREE
    local current latest label amount sync_root snapshot_item

    SUMMARY=()
    show_cleanup_banner

    start_free_space=$(free_space)
    start_ram_used=$(ram_used)

    echo "Disk free at start : $(df -Ph / | awk 'NR==2 {print $4}')"
    echo "RAM used  at start : $(free -h | awk '/Mem/ {print $3}')"
    echo ""

    echo "Files larger than 500MB:"
    find / -type f -size +500M 2>/dev/null || true
    echo ""

    echo " APT cache "
    _B=$(free_space)
    apt-get clean -q
    rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock
    _A=$(free_space)
    report_freed "APT cache" "$_B" "$_A"

    echo " Old kernels (keep running kernel) "
    _B=$(free_space)
    dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V \
        | sed -n '/'$(uname -r)'/q;p' | xargs -r apt-get -y purge -q 2>/dev/null || true
    dpkg --list | grep linux-image-extra | awk '{ print $2 }' | sort -V \
        | sed -n '/'$(uname -r)'/q;p' | xargs -r apt-get -y purge -q 2>/dev/null || true
    update-grub2 > /dev/null 2>&1 || update-grub > /dev/null 2>&1 || true
    _A=$(free_space)
    report_freed "Old kernels" "$_B" "$_A"

    echo " /var/log - all service log sections in one measurement "
    _B=$(free_space)
    local _rsyslog_reopen=false

    echo " -- Core "
    rm -f /var/log/error.* /var/log/pm-powersave.log*
    rm -f /var/log/alternatives.log.* /var/log/dpkg.log.*
    rm -f /var/log/kern.log.* /var/log/debug.* /var/log/daemon.log.*
    rm -f /var/log/cron.log.* /var/log/boot.log.* /var/log/messages.*
    rm -f /var/log/apport.log.*
    rm -f /var/log/aptitude.* /var/log/vmware-vmsvc.*
    rm -f /var/log/apt/term.log.* /var/log/apt/history.log.*
    find /var/log/upstart -mindepth 1 -type f \( -name "*.log.*" -o -name "*.gz" -o -name "*.old" \) \
        -delete 2>/dev/null || true
    rm -f /var/log/syslog.* /var/log/ubuntu-advantage.log.* /var/log/ubuntu-advantage-timer.log.*
    rm -f /var/log/installer/*.log.*
    rm -f /var/log/vmware-vmsvc-root.* /var/log/vmware-vmtoolsd-root.*
    rm -f /var/log/dmesg.* /var/log/netserver.debug_*
    delete_live_logs_over_limit \
        /var/log/error \
        /var/log/network.log \
        /var/log/alternatives.log \
        /var/log/dpkg.log \
        /var/log/kern.log \
        /var/log/debug \
        /var/log/daemon.log \
        /var/log/cron.log \
        /var/log/boot.log \
        /var/log/messages \
        /var/log/apport.log \
        /var/log/syslog \
        /var/log/ubuntu-advantage.log \
        /var/log/ubuntu-advantage-timer.log \
        /var/log/apt/term.log \
        /var/log/apt/history.log \
        /var/log/crypto.txt \
        /var/log/apcupsd.events \
        /var/log/cloud-init.log
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && _rsyslog_reopen=true
    if [ -d "/var/log/cups/" ]; then
        delete_rotated_logs_in_dir "/var/log/cups"
        delete_live_logs_in_dir_over_limit "/var/log/cups"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart cups 2>/dev/null || true
    fi
    if [ -d "/var/log/unattended-upgrades/" ]; then
        delete_rotated_logs_in_dir "/var/log/unattended-upgrades"
        delete_live_logs_in_dir_over_limit "/var/log/unattended-upgrades"
    fi
    if [ -d "/var/log/samba/" ]; then
        delete_rotated_logs_in_dir "/var/log/samba"
        delete_live_logs_in_dir_over_limit "/var/log/samba"
        if [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ]; then
            systemctl restart smbd 2>/dev/null || true
            systemctl restart nmbd 2>/dev/null || true
        fi
    fi

    echo " -- Security "
    rm -f /var/log/user.log.* /var/log/auth.log.*
    rm -f /var/log/fail2ban.log.*
    delete_live_logs_over_limit /var/log/user.log /var/log/auth.log
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && _rsyslog_reopen=true
    delete_live_logs_over_limit /var/log/fail2ban.log
    [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart fail2ban 2>/dev/null || true
    if [ -d "/var/log/clamav/" ]; then
        delete_rotated_logs_in_dir "/var/log/clamav"
        delete_live_logs_over_limit /var/log/clamav/clamav.log /var/log/clamav/freshclam.log
        if [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ]; then
            systemctl restart clamav-daemon 2>/dev/null || true
            systemctl restart clamav-freshclam 2>/dev/null || true
        fi
        rm -f /var/log/install_clamav.log
    fi

    echo " -- Databases "
    local _mysql_logs_removed=0
    if [ -d "/var/log/mysql/" ]; then
        delete_rotated_logs_in_dir "/var/log/mysql"
        delete_live_logs_in_dir_over_limit "/var/log/mysql"
        _mysql_logs_removed=$(( _mysql_logs_removed + LIVE_LOG_REMOVED_LAST ))
    fi
    rm -f /var/log/mysql.log.*
    delete_live_logs_over_limit /var/log/mysql.log
    _mysql_logs_removed=$(( _mysql_logs_removed + LIVE_LOG_REMOVED_LAST ))
    [ "$_mysql_logs_removed" -gt 0 ] && systemctl restart mysql 2>/dev/null || true
    if [ -d "/var/log/mongodb/" ]; then
        delete_rotated_logs_in_dir "/var/log/mongodb"
        delete_live_logs_in_dir_over_limit "/var/log/mongodb"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart mongodb 2>/dev/null || true
    fi
    if [ -d "/var/log/mongdb/" ]; then
        delete_rotated_logs_in_dir "/var/log/mongdb"
        delete_live_logs_in_dir_over_limit "/var/log/mongdb"
    fi
    if [ -d "/var/log/redis/" ]; then
        delete_rotated_logs_in_dir "/var/log/redis"
        delete_live_logs_in_dir_over_limit "/var/log/redis"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart redis-server 2>/dev/null || true
    fi

    echo " -- ELK "
    if [ -d "/var/log/kibana/" ]; then
        delete_rotated_logs_in_dir "/var/log/kibana"
        delete_live_logs_in_dir_over_limit "/var/log/kibana"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart kibana 2>/dev/null || true
    fi
    if [ -d "/var/log/logstash/" ]; then
        delete_rotated_logs_in_dir "/var/log/logstash"
        delete_live_logs_in_dir_over_limit "/var/log/logstash"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart logstash 2>/dev/null || true
    fi
    if [ -d "/var/log/elasticsearch/" ]; then
        delete_rotated_logs_in_dir "/var/log/elasticsearch"
        delete_live_logs_in_dir_over_limit "/var/log/elasticsearch"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart elasticsearch 2>/dev/null || true
    fi
    if [ -d "/var/log/metricbeat/" ]; then
        delete_rotated_logs_in_dir "/var/log/metricbeat"
        delete_live_logs_in_dir_over_limit "/var/log/metricbeat"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart metricbeat 2>/dev/null || true
    fi

    echo " -- Mail "
    if [ -d "/var/log/mail/" ] || [ -f "/var/log/mail.log" ] || [ -f "/var/log/mail.err" ]; then
        rm -f /var/log/mail.log.* /var/log/mail.err.*
        delete_live_logs_over_limit /var/log/mail.log /var/log/mail.err
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && _rsyslog_reopen=true
        postsuper -d ALL 2>/dev/null || true
        systemctl restart postfix 2>/dev/null || true
    fi
    trim_mailbox_to_limit /var/mail/root
    if $_rsyslog_reopen; then
        systemctl kill -s HUP rsyslog 2>/dev/null || systemctl restart rsyslog 2>/dev/null || true
    fi

    echo " -- Web / HTTP "
    if [ -d "/var/log/letsencrypt/" ]; then
        delete_rotated_logs_in_dir "/var/log/letsencrypt"
        delete_live_logs_in_dir_over_limit "/var/log/letsencrypt"
    fi
    if [ -d "/var/log/apache2/" ]; then
        delete_rotated_logs_in_dir "/var/log/apache2"
        delete_live_logs_in_dir_over_limit "/var/log/apache2"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart apache2 2>/dev/null || true
    fi
    if [ -d "/var/log/lighttpd/" ]; then
        delete_rotated_logs_in_dir "/var/log/lighttpd"
        delete_live_logs_in_dir_over_limit "/var/log/lighttpd"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart lighttpd 2>/dev/null || true
    fi
    if [ -d "/var/log/nginx/" ]; then
        local _php_fpm_logs_removed=0
        delete_rotated_logs_in_dir "/var/log/nginx"
        delete_live_logs_in_dir_over_limit "/var/log/nginx"
        [ "$LIVE_LOG_REMOVED_LAST" -gt 0 ] && systemctl restart nginx 2>/dev/null || true
        rm -f /var/log/php*-fpm.log.*
        delete_live_logs_over_limit /var/log/php*-fpm.log
        _php_fpm_logs_removed=$LIVE_LOG_REMOVED_LAST
        if [ "$_php_fpm_logs_removed" -gt 0 ]; then
            while read -r php_fpm; do
                [ -n "$php_fpm" ] || continue
                systemctl restart "$php_fpm" 2>/dev/null || true
            done < <(
                systemctl list-units --type=service --state=active --no-legend 2>/dev/null \
                    | awk '$1 ~ /php.*-fpm/ {print $1}'
            )
        fi
    fi

    echo " -- Pi-Hole "
    if [ -d "/var/log/pihole/" ]; then
        pihole -f 2>/dev/null || true
        systemctl stop pihole-FTL dnsmasq 2>/dev/null || true
        delete_rotated_logs_in_dir "/var/log/pihole"
        delete_live_logs_in_dir_over_limit "/var/log/pihole"
        rm -f /var/log/pihole/pihole_updateGravity.log
        rm -f /var/log/update_blocklists_local_servers.log
        systemctl restart dnsmasq 2>/dev/null || true
        systemctl restart pihole-FTL 2>/dev/null || true
    fi

    echo " -- Misc "
    rm -f /var/log/update_core.log /var/log/update_ubuntu.log
    rm -f /var/log/sys_cleanup.log* /var/log/vmware-network.*

    echo " -- Large log files (>1GB) "
    find /var/log -type f \
        \( -name "*.log.*" -o -name "*.gz" -o -name "*.old" \) \
        -size +1G -delete 2>/dev/null

    _A=$(free_space)
    report_freed "/var/log cleanup" "$_B" "$_A"

    echo " -- /tmp "
    _B=$(free_space)
    rm -rf /tmp/pip-* /tmp/systemd-private-*
    rm -rf /tmp/resilio_dumps/
    _A=$(free_space)
    report_freed "/tmp cleanup" "$_B" "$_A"

    echo " -- /var/tmp - stale files older than 30 days "
    _B=$(free_space)
    if [ -d "/var/tmp" ]; then
        find /var/tmp -xdev -mindepth 1 \( -type f -o -type l \) \
            -mtime +30 -delete 2>/dev/null || true
        find /var/tmp -xdev -depth -mindepth 1 -type d -empty \
            -delete 2>/dev/null || true
    fi
    _A=$(free_space)
    report_freed "/var/tmp stale files" "$_B" "$_A"

    echo " -- Resilio Sync - logs, metadata, and .sync/Archive folders "
    _B=$(free_space)
    if [ -d "/var/lib/resilio-sync/" ]; then
        rm -f /var/lib/resilio-sync/sync.log /var/lib/resilio-sync/sync.log.*
        rm -rf /var/lib/resilio-sync/torrents/ /var/lib/resilio-sync/storage/
    fi
    local RESILIO_SYNC_ROOTS="/home /mnt /data /srv"
    for sync_root in $RESILIO_SYNC_ROOTS; do
        [ -d "$sync_root" ] && find "$sync_root" -type d -name "Archive" \
            -path "*/.sync/Archive" -exec rm -rf {} + 2>/dev/null
    done
    _A=$(free_space)
    report_freed "Resilio Sync archives" "$_B" "$_A"

    echo " -- Systemd journal vacuum "
    _B=$(free_space)
    journalctl --vacuum-time=7d 2>/dev/null || true
    journalctl --vacuum-size=500M 2>/dev/null || true
    _A=$(free_space)
    report_freed "systemd journal" "$_B" "$_A"

    echo " -- Compressed / numerically-rotated old logs "
    _B=$(free_space)
    find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.2" \
         -o -name "*.3" -o -name "*.old" \) -delete 2>/dev/null || true
    _A=$(free_space)
    report_freed "Rotated/compressed logs" "$_B" "$_A"

    echo " -- Docker "
    if [ -d "/var/lib/docker/" ]; then
        _B=$(free_space)
        docker system prune -a --volumes -f 2>/dev/null || true
        find /var/lib/docker/containers -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
        _A=$(free_space)
        report_freed "Docker" "$_B" "$_A"
    fi

    echo " -- Ollama - model blobs older than 90 days "
    if [ -d "/usr/share/ollama/.ollama/models/blobs/" ]; then
        _B=$(free_space)
        find "/usr/share/ollama/.ollama/models/blobs" -type f -mtime +90 -exec rm -f {} \;
        _A=$(free_space)
        report_freed "Ollama model blobs (>90 days)" "$_B" "$_A"
    fi

    echo " -- Python cache "
    _B=$(free_space)
    rm -rf ~/.cache/pip
    rm -rf /home/ubuntu/.cache/pip/ /root/.cache/pip/ /root/.local/lib/
    _A=$(free_space)
    report_freed "Python pip cache" "$_B" "$_A"

    echo " -- Crash dumps "
    _B=$(free_space)
    [ -d "/var/crash" ] && find /var/crash -xdev -type f -mtime +7 -delete 2>/dev/null || true
    [ -d "/var/lib/systemd/coredump" ] && find /var/lib/systemd/coredump -xdev \
        -type f -mtime +7 -delete 2>/dev/null || true
    if have_cmd coredumpctl; then
        coredumpctl --vacuum-time=7d >/dev/null 2>&1 || true
    fi
    _A=$(free_space)
    report_freed "Crash dumps" "$_B" "$_A"

    echo " -- Snap - remove old disabled revisions "
    _B=$(free_space)
    snap list --all | awk '/disabled/{print $1, $3}' | \
        while read -r snapname revision; do
            snap remove "$snapname" --revision="$revision" 2>/dev/null || true
            sleep 1
        done
    _A=$(free_space)
    report_freed "Snap old revisions" "$_B" "$_A"

    echo " -- Deleted-but-held-open files: truncate via /proc/<pid>/fd "
    _B=$(free_space)
    _held=0
    _truncated=0
    if have_cmd lsof; then
        while read -r pid fd; do
            [ -n "${pid:-}" ] || continue
            [ -n "${fd:-}" ] || continue
            _held=$(( _held + 1 ))
            fd_num="${fd//[^0-9]/}"
            [ -n "$fd_num" ] || continue
            proc_fd="/proc/$pid/fd/$fd_num"
            if [ -e "$proc_fd" ] && truncate -s 0 "$proc_fd" 2>/dev/null; then
                _truncated=$(( _truncated + 1 ))
            fi
        done < <(
            lsof -nP +L1 2>/dev/null \
                | awk 'NR > 1 && $5 == "REG" && $4 ~ /^[0-9]+[A-Za-z]*$/ {print $2, $4}'
        )
    else
        echo "  [!] lsof not installed; skipping held-open file scan"
    fi
    _A=$(free_space)
    report_freed "Held-open deleted files" "$_B" "$_A"
    if [ "$_held" -gt 0 ]; then
        echo "  (${_truncated}/${_held} held-open deleted regular file descriptors truncated)"
    fi

    echo " -- RAM / Page cache "
    _RAM_B=$(ram_used)
    sync
    echo 3 | tee /proc/sys/vm/drop_caches > /dev/null
    echo 1 | tee /proc/sys/vm/compact_memory > /dev/null 2>&1 || true

    _swap_cleared=false
    SWAP_USED=$(free -b | awk '/Swap/ {print $3}')
    RAM_FREE=$(free -b | awk '/Mem/ {print $4}')
    if [ "${SWAP_USED:-0}" -gt 0 ] && [ "${RAM_FREE:-0}" -gt "${SWAP_USED:-0}" ]; then
        swapoff -a && swapon -a
        _swap_cleared=true
    fi

    _RAM_A=$(ram_used)
    _ram_diff=$(( _RAM_B - _RAM_A ))
    if [ "$_ram_diff" -gt 1048576 ]; then
        _ram_human=$(numfmt --to=iec-i --suffix=B "$_ram_diff")
        echo "  [+] RAM freed - ${_ram_human} (page cache drop + compaction)"
        SUMMARY+=("RAM page cache|${_ram_human}")
    fi
    if $_swap_cleared; then
        echo "  [+] Swap cleared"
        SUMMARY+=("Swap|cleared")
    fi

    echo " -- APT housekeeping (after cleanup so indexes are fresh) "
    _B=$(free_space)
    apt-get autoremove -y -q 2>/dev/null || true
    apt-get autoclean -q 2>/dev/null || true
    apt-get -f install -y -q 2>/dev/null || true
    apt-get update -q 2>/dev/null || true
    apt-get upgrade -y -q 2>/dev/null || true
    apt-get dist-upgrade -y -q 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
    apt-get install -y -q ncdu traceroute rsync 2>/dev/null || true
    _A=$(free_space)
    report_freed "APT autoremove/upgrade" "$_B" "$_A"

    echo "--- Removing all but the current and latest kernel --- "
    current=$(uname -r)
    latest=$(dpkg -l 'linux-image-[0-9]*-generic' \
        | awk '/^ii/ {print $2}' \
        | sort -V \
        | tail -1 \
        | sed 's/linux-image-//')
    echo "  Keeping: $current (running)"
    [ "$latest" != "$current" ] && echo "  Keeping: $latest (latest)"

    dpkg -l 'linux-image-[0-9]*-generic' \
        | awk '/^ii/ {print $2}' \
        | grep -vF -- "$current" \
        | grep -vF -- "$latest" \
        | xargs -r apt-get -y purge || true

    dpkg -l \
        | awk '/^(ii|rc)/ && $2 ~ /^linux-(image|modules|headers)-[0-9]/ { print $2 }' \
        | grep -vF -- "$current" \
        | grep -vF -- "$latest" \
        | xargs -r dpkg --purge || true

    apt-get -y autoremove --purge 2>/dev/null || true

    echo " -- SUMMARY REPORT "
    end_free_space=$(free_space)
    end_ram_used=$(ram_used)
    total_disk_diff=$(( end_free_space - start_free_space ))
    total_ram_diff=$(( start_ram_used - end_ram_used ))

    echo ""
    echo "============================================================"
    echo "  CLEANUP REPORT"
    echo "============================================================"

    if [ "${#SUMMARY[@]}" -eq 0 ]; then
        echo "  No section freed more than 1MB - system was already clean."
    else
        printf "  %-36s  %s\n" "Section" "Freed"
        echo "  ----------------------------------------------------"
        for snapshot_item in "${SUMMARY[@]}"; do
            label="${snapshot_item%%|*}"
            amount="${snapshot_item##*|}"
            printf "  %-36s  %s\n" "$label" "$amount"
        done
    fi

    echo ""
    echo "  ----------------------------------------------------"
    if [ "$total_disk_diff" -ge 0 ]; then
        printf "  %-36s  %s\n" "Total disk reclaimed" \
            "$(numfmt --to=iec-i --suffix=B "$total_disk_diff")"
    else
        printf "  %-36s  -%s (upgrades used disk)\n" "Total disk reclaimed" \
            "$(numfmt --to=iec-i --suffix=B "$(( -total_disk_diff ))")"
    fi

    if [ "$total_ram_diff" -gt 0 ]; then
        printf "  %-36s  %s\n" "Total RAM freed" \
            "$(numfmt --to=iec-i --suffix=B "$total_ram_diff")"
    fi

    echo ""
    printf "  %-20s  %s  ->  %s\n" "Disk free" \
        "$(numfmt --to=iec-i --suffix=B "$start_free_space")" \
        "$(df -Ph / | awk 'NR==2 {print $4}')"
    printf "  %-20s  %s  ->  %s\n" "RAM used" \
        "$(numfmt --to=iec-i --suffix=B "$start_ram_used")" \
        "$(free -h | awk '/Mem/ {print $3}')"
    echo "============================================================"
    echo ""

    echo " -- Diagnostics "
    echo "Top 10 largest items in /var/log:"
    du -ah /var/log 2>/dev/null | sort -nr | awk 'NR <= 10 { print }' || true

    echo ""
    echo "Top 10 largest items on /:"
    du -ah / 2>/dev/null | sort -nr | awk 'NR <= 10 { print }' || true

    echo ""
    echo "Files still larger than 500MB:"
    find / -type f -size +500M 2>/dev/null || true

    echo ""
    echo "Installed kernel images (running: $(uname -r)):"
    dpkg --list | grep linux-image || true
    echo "To remove a specific old kernel: apt-get purge linux-image-x.x.x.x-generic"

    echo ""
    echo "To run an interactive filesize viewer:  ncdu /"
    echo ""

    echo " -- Self-update "
    if $ENABLE_SELF_UPDATE; then
        wget -q "$SELF_UPDATE_URL" -O "$SCRIPT_PATH" \
            && chmod u+x "$SCRIPT_PATH" \
            && echo "Script updated at $SCRIPT_PATH" \
            || echo "Script self-update failed - check network connectivity"
    else
        echo "Self-update disabled. Re-enable ENABLE_SELF_UPDATE=true only if you control the source URL."
    fi

    echo ""
    echo "DONE!"
    echo ""
    echo "#--- DEPRECATION NOTE ----"
    echo "If you get 'DEPRECATION section in apt-key(8)' run:"
    echo "  cd /etc/apt && cp trusted.gpg trusted.gpg.d"
    echo ""

    df -h
}

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

main() {
    parse_args "$@"

    case "$RUN_MODE" in
        cleanup)
            run_cleanup
            ;;
        backup|prune)
            run_backup_mode
            ;;
        *)
            die "Unsupported mode: $RUN_MODE"
            ;;
    esac
}

main "$@"
