#!bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'

  - job_name: 'apache'
    static_configs:
      - targets:
          - 'localhost:9117'

EOL
