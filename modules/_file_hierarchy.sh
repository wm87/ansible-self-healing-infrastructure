#!/bin/bash

# ---------------------
# Ordnerstruktur
# ---------------------

DIRS=(
	"$PROJECT/roles/hardening/tasks"
	"$PROJECT/roles/hardening/handlers"
	"$PROJECT/roles/hardening/templates"

	"$PROJECT/roles/prometheus/files"
	"$PROJECT/roles/prometheus/tasks"
	"$PROJECT/roles/prometheus/handlers"
	"$PROJECT/roles/prometheus/templates"
	"$PROJECT/roles/prometheus/vars"

	"$PROJECT/roles/loki/files"
	"$PROJECT/roles/loki/tasks"
	"$PROJECT/roles/loki/handlers"
	"$PROJECT/roles/loki/templates"
	"$PROJECT/roles/loki/vars"

	"$PROJECT/roles/telegraf/files"
	"$PROJECT/roles/telegraf/tasks"
	"$PROJECT/roles/telegraf/handlers"
	"$PROJECT/roles/telegraf/templates"
	"$PROJECT/roles/telegraf/vars"

	"$PROJECT/roles/alloy/files"
	"$PROJECT/roles/alloy/tasks"
	"$PROJECT/roles/alloy/handlers"
	"$PROJECT/roles/alloy/templates"
	"$PROJECT/roles/alloy/vars"
	
	"$PROJECT/roles/grafana/tasks"
	"$PROJECT/roles/grafana/templates"
	"$PROJECT/roles/grafana/provisioning/dashboards"
	"$PROJECT/roles/grafana/templates/provisioning/dashboards"
	"$PROJECT/roles/grafana/vars"

	"$PROJECT/roles/alertmanager/tasks"
	"$PROJECT/roles/alertmanager/handlers"
	"$PROJECT/roles/alertmanager/templates"

	"$PROJECT/group_vars/all"
)

for dir in "${DIRS[@]}"; do
	mkdir -p "$dir"
done
