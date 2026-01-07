#!/bin/bash

set -euo pipefail

export PROJECT_SH="$(pwd)/selfhealing"

echo "🛠 Starte Ansible Self-Healing Demo .."
DRY_RUN=false SERVICE=all SEVERITY=critical SCENARIO=auto APPROVAL=true ./setup/selfhealing_szenario.sh
