#!bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'

  - job_name: 'cadvisor'
    static_configs:
      - targets:
          - 'localhost:9050'

EOL
