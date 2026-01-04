#!/bin/bash

set -euo pipefail

echo "🛠 Starte Ansible Self-Healing Demo .."
DRY_RUN=false SERVICE=all SEVERITY=critical SCENARIO=auto APPROVAL=true ./setup/selfhealing_szenario.sh
