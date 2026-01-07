#!/bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/files/alert_rules.yml" <<'EOL'

# =====================
# Host Alerts
# =====================
- name: host
  rules:

  # ---------------------
  # Host down
  # ---------------------
  - alert: HostDown
    expr: up == 0
    for: 2m
    labels:
      severity: critical
      service: all
      scenario: network_heal
    annotations:
      summary: "🚨 Host down"
      description: "Host {{ $labels.instance }} ist nicht erreichbar"

  # ---------------------
  # Disk space
  # ---------------------
  - alert: DiskAlmostFull
    expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1
    for: 10m
    labels:
      severity: warning
      service: all
      scenario: cleanup
    annotations:
      summary: "⚠️ Disk fast voll"
      description: "Host {{ $labels.instance }} hat weniger als 10% Speicher frei"

  # ---------------------
  # CPU usage
  # ---------------------
  - alert: CPUHigh
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
    for: 5m
    labels:
      severity: warning
      service: all
      scenario: cleanup
    annotations:
      summary: "🔥 Hohe CPU-Auslastung"
      description: "Host {{ $labels.instance }} CPU-Auslastung > 85%"

  # ---------------------
  # Network down (per Interface)
  # ---------------------
  - alert: NetworkDown
    expr: rate(node_network_receive_bytes_total{device="ens32"}[5m]) < 100
    for: 5m
    labels:
      severity: critical
      service: all
      scenario: network_heal
    annotations:
      summary: "🚨 Netzwerk down (ens32)"
      description: |
        Host: {{ $labels.instance }}
        Interface: {{ $labels.device }}
        Status: Kein eingehender Traffic seit über 5 Minuten
        Ursache: Netzwerkproblem oder Interface down
        Empfehlung: Interface prüfen, Kabel und Switch überprüfen

  # ---------------------
  # Network high traffic
  # ---------------------
  - alert: NetworkHigh
    expr: rate(node_network_receive_bytes_total[5m]) > 100000000
    for: 5m
    labels:
      severity: warning
      service: host
      scenario: auto
    annotations:
      summary: "⚠️ Hoher Netzwerktraffic"
      description: "Host {{ $labels.instance }} hat >100MB/s eingehenden Traffic"

  # =========================================================
  # Memory Recovery
  # =========================================================
  - alert: HighMemoryPressure
    expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
    for: 3m
    labels:
      severity: critical
      service: all
      scenario: memory_recovery
    annotations:
      summary: "Memory Druck"
      description: "Caches & Swap werden bereinigt"

  # =========================================================
  # FSCK Approval (MANUELL!)
  # =========================================================
  - alert: FilesystemReadonly
    expr: node_filesystem_readonly == 1
    for: 1m
    labels:
      severity: critical
      service: all
      scenario: fsck_approval
    annotations:
      summary: "Filesystem Read-Only"
      description: "Manuelle Freigabe für fsck erforderlich"
EOL
