#!/bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/files/alert_rules.yml" <<'EOL'

# =====================
# Apache Alerts
# =====================
- name: apache
  rules:

    # ---------------------
    # Apache down
    # ---------------------
    - alert: ApacheDown
      expr: apache_up == 0
      for: 1m
      labels:
        severity: critical
        service: apache2
        scenario: restart
      annotations:
        summary: "Apache down"
        description: |
          Apache auf {{ $labels.instance }} nicht erreichbar
          Status: Nicht verfügbar
          Dauer: > 1 Minute

    # ---------------------
    # Apache high 5xx error rate
    # ---------------------
    - alert: ApacheHigh5xxRate
      expr: rate(apache_http_requests_total{status=~"5.."}[5m]) / rate(apache_http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
        service: apache2
        scenario: reload
      annotations:
        summary: "⚠️ Hohe Apache 5xx-Fehler"
        description: |
          Apache liefert viele 5xx Fehler auf {{ $labels.instance }}
          Anteil 5xx Fehler: > 5%
          Empfehlung: Logs prüfen, mögliche Fehlkonfiguration oder Überlastung

EOL
