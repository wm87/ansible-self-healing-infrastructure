#!bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'

  - job_name: 'snmp'
    scrape_interval: 60s
    metrics_path: /snmp
    params:
      module: [if_mib]
    static_configs:
      - targets:
          - 127.0.0.1        # localhost via snmpd
          - 192.168.1.1      # Gateway
          - 192.168.1.2      # Switch
          - 192.168.1.3      # Unifi AP
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9116

  # Global exporter-level metrics
  - job_name: 'snmp_exporter'
    static_configs:
      - targets: ['localhost:9116']
EOL
