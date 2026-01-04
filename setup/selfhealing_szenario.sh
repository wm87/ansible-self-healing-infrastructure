#!/bin/bash
# run_healing.sh – Self-Healing Orchestrator
set -e

ANSIBLE_DIR="$(pwd)/selfhealing"
PLAYBOOK="$ANSIBLE_DIR/playbooks/selfheal.yml"
INVENTORY="${INVENTORY:-$ANSIBLE_DIR/inventory/hosts.ini}"

LOG_DIR="${LOG_DIR:-$HOME/.selfheal/log}"
LOCK_DIR="${LOCK_DIR:-$HOME/.selfheal/run}"
COOLDOWN_SECONDS=20

ANSIBLE_BIN=ansible-playbook
mkdir -p "$LOG_DIR" "$LOCK_DIR"

HOST="${HOST:-$(hostname)}"
SERVICE="${SERVICE:-all}"
SEVERITY="${SEVERITY:-warning}"
SCENARIO="${SCENARIO:-auto}"
APPROVAL="${APPROVAL:-false}"
DRY_RUN="${DRY_RUN:-false}"
SOURCE="${SOURCE:-manual}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOGFILE="$LOG_DIR/selfheal-${HOST}-${SERVICE}-${TIMESTAMP}.log"
LOCKFILE="$LOCK_DIR/${HOST}-${SERVICE}.lock"

log() {
    echo "[$(date --iso-8601=seconds)] $*" | tee -a "$LOGFILE"
}

# -------------------------
# Cooldown
# -------------------------
if [[ -f "$LOCKFILE" ]]; then
    LAST_RUN=$(cat "$LOCKFILE")
    NOW=$(date +%s)
    DELTA=$((NOW - LAST_RUN))
    if [[ $DELTA -lt $COOLDOWN_SECONDS ]]; then
        log "Cooldown aktiv (${DELTA}s < ${COOLDOWN_SECONDS}s) – Abbruch"
        exit 0
    fi
fi
date +%s >"$LOCKFILE"

# -------------------------
# Extra Vars
# -------------------------
EXTRA_VARS=(
    "-e" "selfheal_service=${SERVICE}"
    "-e" "selfheal_approval=${APPROVAL}"
    "-e" "selfheal_source=${SOURCE}"
    "-e" "selfheal_severity=${SEVERITY}"
)

case "$SCENARIO" in
memory) EXTRA_VARS+=("-e" "force_memory_recovery=true") ;;
disk) EXTRA_VARS+=("-e" "force_fsck=true") ;;
network) EXTRA_VARS+=("-e" "force_network_heal=true") ;;
service|restart) EXTRA_VARS+=("-e" "force_service_restart=true") ;;  # restart für PostgreSQL
auto) ;;  # State Machine entscheidet selbst
*) log "Unbekanntes Szenario: $SCENARIO"; exit 1 ;;
esac

# Policy für kritische Alerts
if [[ "$SEVERITY" == "critical" && "$APPROVAL" != "true" ]]; then
    EXTRA_VARS+=("-e" "policy_block_risky_actions=true")
fi

# Dry-Run
ANSIBLE_OPTS=()
if [[ "$DRY_RUN" == "true" ]]; then
    ANSIBLE_OPTS+=(--check --diff)
    log "Dry-Run aktiviert"
fi

# -------------------------
# Start Self-Healing
# -------------------------
log "=============================================="
log "Self-Healing START"
log "Host      : $HOST"
log "Service   : $SERVICE"
log "Severity  : $SEVERITY"
log "Scenario  : $SCENARIO"
log "Approval  : $APPROVAL"
log "Source    : $SOURCE"
log "=============================================="

cd "$ANSIBLE_DIR" || { log "Fehler: Ansible-Verzeichnis '$ANSIBLE_DIR' nicht gefunden."; exit 1; }

ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --limit "$HOST" "${ANSIBLE_OPTS[@]}" "${EXTRA_VARS[@]}" | tee -a "$LOGFILE"
RC=${PIPESTATUS[0]}

if [[ $RC -eq 0 ]]; then
    log "Self-Healing ERFOLGREICH abgeschlossen"
else
    log "Self-Healing FEHLGESCHLAGEN (RC=$RC)"
fi

date +%s >"$LOCKFILE"
log "Self-Healing ENDE"
exit $RC
