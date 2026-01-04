#!/bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/files/alert_rules.yml" <<'EOL'
# =====================
# Selfheal Alerts
# =====================
- name: selfheal-alerts
  rules:
    - alert: SelfhealFailed
      expr: selfheal_repair_success == 0
      for: 1m
      labels:
        severity: critical
        service: selfheal
        scenario: auto
        dry_run: "true"
      annotations:
        summary: "Self-Healing fehlgeschlagen auf {{ $labels.host }}"
        description: "Service {{ $labels.service }} konnte nicht repariert werden."

    - alert: SelfhealSucceeded
      expr: selfheal_repair_success == 1
      for: 0m
      labels:
        severity: info
        service: selfheal
        scenario: auto
        dry_run: "true"
      annotations:
        summary: "Self-Healing erfolgreich auf {{ $labels.host }}"
        description: "Service {{ $labels.service }} repariert."
EOL
