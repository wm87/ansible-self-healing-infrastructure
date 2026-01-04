#!bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'

  - job_name: 'postgres'
    static_configs:
      - targets:
          - 'localhost:9187'

EOL
