#!bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'

  - job_name: apache_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: apache_logs
          __path__: /var/log/apache2/*.log

EOL
