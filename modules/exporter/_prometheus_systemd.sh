#!bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'

  - job_name: 'systemd'
    static_configs:
      - targets:
          - 'localhost:9558'

EOL
