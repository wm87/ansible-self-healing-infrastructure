#!/bin/bash

# ---------------------
# Ordnerstruktur
# ---------------------

DIRS=(
	$PROJECT_MT/roles/{prometheus,loki,telegraf,alloy,grafana,alertmanager}/{files,tasks,handlers,templates,vars}
	$PROJECT_MT/roles/grafana/provisioning/dashboards
	$PROJECT_MT/group_vars/all
)

for dir in "${DIRS[@]}"; do
	mkdir -p "$dir"
done
