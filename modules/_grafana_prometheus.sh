#!/bin/bash

set -e

cat >"$TASKS_DIR/main.yml" <<'EOL'

# -------------------------------------------------
# DASHBOARDS
# -------------------------------------------------

- name: Download dashboards
  get_url:
    url: "https://grafana.com/api/dashboards/{{ item.id }}/revisions/{{ item.rev }}/download"
    dest: "{{ grafana_dashboard_dir }}/{{ item.name }}.json"
  loop:
    - { name: alerts_1, id: 11098, rev: 1 }
    - { name: alerts_2, id: 16420, rev: 5 }
    - { name: apache2, id: 3894, rev: 7 }
    - { name: docker, id: 893, rev: 5 }
    - { name: mysql, id: 7362, rev: 5 }
    - { name: netdata, id: 7107, rev: 1 }
    - { name: node_exporter_full, id: 1860, rev: 42 }
    - { name: node_exporter_summary, id: 23819, rev: 1 }
    - { name: postgresql, id: 9628, rev: 8 }
    - { name: prometheus, id: 24110, rev: 1 }
    - { name: systemd, id: 23844, rev: 3 }
  notify: restart grafana

# SNMP Dashboards (optional)
# - { name: prometheus_network, id: 15297, rev: 4 }
# - { name: snmp_interface, id: 12492, rev: 4 }
# - { name: synology_snmp, id: 18643, rev: 1 }

- name: Find dashboards
  find:
    paths: "{{ grafana_dashboard_dir }}"
    patterns: "*.json"
  register: grafana_dashboard_files

# -------------------------------------------------
# Patch ALL Prometheus datasource variables to "Prometheus"
# -------------------------------------------------
- name: Patch all Prometheus datasource placeholders robustly, including spaces
  replace:
    path: "{{ item.path }}"
    # Matcht ${DS_…} oder ${ds_…} mit Buchstaben, Zahlen, Unterstrich, Punkt, Klammern und Leerzeichen
    regexp: '\$\{[Dd][Ss]_[A-Za-z0-9_\.() ]+\}'
    replace: Prometheus
  loop: "{{ grafana_dashboard_files.files }}"
  loop_control:
    label: "{{ item.path | basename }}"

EOL
