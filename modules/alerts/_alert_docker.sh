#!/bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/files/alert_rules.yml" <<'EOL'

# =========================================================
# Docker
# =========================================================
- name: docker-selfheal
  rules:
    - alert: DockerDaemonDown
      expr: engine_daemon_engine_info == 0
      for: 1m
      labels:
        severity: critical
        service: docker
        scenario: restart
      annotations:
        summary: "Docker daemon down"
        description: "Docker nicht erreichbar"

EOL
