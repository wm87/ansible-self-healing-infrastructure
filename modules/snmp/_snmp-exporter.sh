#!/bin/bash

set -e

SNMP_EXPORTER_VERSION="0.29.0"
SNMP_EXPORTER_PORT=9116
SNMP_COMMUNITY="public"

# -------------------------------
# Variablen
# -------------------------------
cat >>"$PROJECT/roles/prometheus/vars/main.yml" <<EOL
snmp_exporter_version: "$SNMP_EXPORTER_VERSION"
snmp_exporter_port: $SNMP_EXPORTER_PORT
snmp_community: "$SNMP_COMMUNITY"
EOL

cp modules/snmp/snmp.yml "$PROJECT/roles/prometheus/files/snmp.yml"

# -------------------------------
# Tasks
# -------------------------------
cat >>"$PROJECT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# SNMP Exporter
# ---------------------

- name: Stop snmp_exporter if installed
  ansible.builtin.systemd:
    name: snmp_exporter
    state: stopped
  ignore_errors: yes

- name: Remove old snmp_exporter service
  file:
    path: /etc/systemd/system/snmp_exporter.service
    state: absent

- name: Create SNMP Exporter config directory
  file:
    path: /etc/snmp_exporter
    state: directory
    owner: prometheus
    group: prometheus
    mode: '0755'

- name: Copy external snmp.yml to target
  copy:
    src: ./snmp.yml
    dest: /etc/snmp_exporter/snmp.yml
    owner: prometheus
    group: prometheus
    mode: '0644'

- name: Download SNMP Exporter
  get_url:
    url: "https://github.com/prometheus/snmp_exporter/releases/download/v{{ snmp_exporter_version }}/snmp_exporter-{{ snmp_exporter_version }}.linux-amd64.tar.gz"
    dest: /tmp/snmp_exporter.tar.gz

- name: Extract SNMP Exporter
  unarchive:
    src: /tmp/snmp_exporter.tar.gz
    dest: /usr/local/bin/
    remote_src: yes
    extra_opts: [--strip-components=1]

- name: Create SNMP Exporter systemd service
  copy:
    dest: /etc/systemd/system/snmp_exporter.service
    content: |
      [Unit]
      Description=SNMP Exporter
      After=network-online.target

      [Service]
      User=prometheus
      Restart=on-failure
      ExecStart=/usr/local/bin/snmp_exporter \
        --config.file=/etc/snmp_exporter/snmp.yml \
        --web.listen-address=:{{ snmp_exporter_port }}

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start SNMP Exporter
  systemd:
    name: snmp_exporter
    enabled: yes
    state: started
EOL
