#!/bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/files/alert_rules.yml" <<'EOL'

# =====================
# PostgreSQL Alerts
# =====================
- name: postgresql
  rules:
    - alert: PostgreSQLDown
      expr: pg_up == 0
      for: 1m
      labels:
        severity: critical
        service: postgresql
        scenario: restart
      annotations:
        summary: "PostgreSQL down"
        description: "PostgreSQL auf {{ $labels.instance }} nicht erreichbar"

EOL
