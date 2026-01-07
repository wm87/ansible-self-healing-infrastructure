#!/bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/files/alert_rules.yml" <<'EOL'

# =====================
# MySQL Alerts
# =====================
- name: mysql
  rules:
    - alert: MySQLDown
      expr: mysql_up == 0
      for: 1m
      labels:
        severity: critical
        service: mysql
        scenario: restart
        approval: "false"
        dry_run: "false"
      annotations:
        summary: "MySQL down"
        description: "MySQL auf {{ $labels.instance }} nicht erreichbar"

    - alert: MySQLTooManyConnections
      expr: mysql_global_status_threads_connected / mysql_global_variables_max_connections > 0.9
      for: 5m
      labels:
        severity: warning
        service: mysql
        approval: "false"
        dry_run: "false"
      annotations:
        summary: "MySQL viele Verbindungen"
        description: "MySQL auf {{ $labels.instance }} >90% der max Connections"

EOL
