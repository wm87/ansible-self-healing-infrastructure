#!/bin/bash

set -e

# -------------------------------
# Basisvariablen
# -------------------------------
PROJECT="${PROJECT:-/tmp/self-healing}"
ROLE_DIR="$PROJECT/roles/telegraf"
TASKS_DIR="$ROLE_DIR/tasks"
VARS_DIR="$ROLE_DIR/vars"
HANDLERS_DIR="$ROLE_DIR/handlers"
FILES_DIR="$ROLE_DIR/files"

mkdir -p "$TASKS_DIR" "$VARS_DIR" "$HANDLERS_DIR" "$FILES_DIR"

# -------------------------------
# Variablen main.yml
# -------------------------------
cat >"$VARS_DIR/main.yml" <<'EOF'
telegraf_version: "1.37.0"
grafana_dashboard_dir: "/var/lib/grafana/dashboards"
EOF

# -------------------------------
# Handlers main.yml
# -------------------------------
cat >"$HANDLERS_DIR/main.yml" <<'EOF'
- name: restart telegraf
  systemd:
    name: telegraf
    state: restarted
EOF

# -------------------------------
# Telegraf Hauptconfig
# -------------------------------
cat >"$FILES_DIR/telegraf.conf" <<'EOF'
# -------------------------------
# Syslog Input
# -------------------------------
[[inputs.syslog]]
  server = "udp://:6514"
  syslog_standard = "RFC3164"
  best_effort = true

# -------------------------------
# Apache Logs Input
# -------------------------------
[[inputs.tail]]
  files = ["/var/log/apache2/access.log", "/var/log/apache2/error.log"]
  from_beginning = false
  name_override = "apache"
  data_format = "grok"
  grok_patterns = ["%{COMBINED_LOG_FORMAT}"]

# -------------------------------
# MapServer Logs Input
# -------------------------------
[[inputs.tail]]
  files = ["/var/log/mapserver/mapserver.log"]
  from_beginning = false
  name_override = "mapserver"
  data_format = "grok"
  grok_patterns = ["%{COMMON_LOG_FORMAT}"]

# -------------------------------
# Fail2Ban Logs Input
# -------------------------------
[[inputs.tail]]
  files = ["/var/log/fail2ban.log"]
  from_beginning = false
  name_override = "fail2ban"
  data_format = "grok"
  grok_patterns = ["%{SYSLOGBASE}"]

# -------------------------------
# GPU Manager Logs Input
# -------------------------------
[[inputs.tail]]
  files = ["/var/log/gpu-manager.log"]
  from_beginning = false
  name_override = "gpu-manager"
  data_format = "grok"
  grok_patterns = ["%{SYSLOGBASE}"]

# -------------------------------
# Auth Logs Input
# -------------------------------
[[inputs.tail]]
  files = ["/var/log/auth.log"]
  from_beginning = false
  name_override = "auth"
  data_format = "grok"
  grok_patterns = ["%{SYSLOGBASE}"]

# -------------------------------
# Boot Logs Input
# -------------------------------
[[inputs.tail]]
  files = ["/var/log/boot.log"]
  from_beginning = false
  name_override = "boot"
  data_format = "grok"
  grok_patterns = ["%{SYSLOGBASE}"]

# -------------------------------
# Loki Output
# -------------------------------
[[outputs.loki]]
  domain = "http://localhost:3100"
  username = "admin"
  password = "admin"
  namepass = ["syslog","apache","mapserver","fail2ban","gpu-manager","auth","boot"]
EOF


# -------------------------------
# Tasks main.yml
# -------------------------------
cat >"$TASKS_DIR/main.yml" <<'EOF'
# -------------------------------------------------
# Install dependencies
# -------------------------------------------------
- name: Ensure wget and tar are installed
  apt:
    name:
      - wget
      - tar
    state: present
    update_cache: yes

# -------------------------------------------------
# Download Telegraf release
# -------------------------------------------------
- name: Download Telegraf tar.gz
  get_url:
    url: "https://dl.influxdata.com/telegraf/releases/telegraf-{{ telegraf_version }}_linux_amd64.tar.gz"
    dest: "/tmp/telegraf-{{ telegraf_version }}_linux_amd64.tar.gz"
    mode: '0644'

- name: Ensure Telegraf extract directory exists
  file:
    path: "/tmp/telegraf_{{ telegraf_version }}"
    state: directory
    mode: '0755'

- name: Extract Telegraf
  unarchive:
    src: "/tmp/telegraf-{{ telegraf_version }}_linux_amd64.tar.gz"
    dest: "/tmp/telegraf_{{ telegraf_version }}"
    remote_src: yes

- name: Deploy Telegraf filesystem
  copy:
    src: "/tmp/telegraf_{{ telegraf_version }}/telegraf-{{ telegraf_version }}/"
    dest: "/"
    owner: root
    group: root
    mode: '0755'

- name: Cleanup Telegraf temp files
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - "/tmp/telegraf-{{ telegraf_version }}_linux_amd64.tar.gz"
    - "/tmp/telegraf_{{ telegraf_version }}"

# -------------------------------------------------
# Hauptconfig für Telegraf
# -------------------------------------------------
- name: Deploy telegraf.conf
  copy:
    src: telegraf.conf
    dest: /etc/telegraf/telegraf.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart telegraf

# -------------------------------------------------
# Systemd service for Telegraf
# -------------------------------------------------
- name: Create telegraf systemd service
  copy:
    dest: /etc/systemd/system/telegraf.service
    mode: '0644'
    content: |
      [Unit]
      Description=Telegraf
      After=network.target

      [Service]
      ExecStart=/usr/bin/telegraf --config /etc/telegraf/telegraf.conf
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start Telegraf
  systemd:
    name: telegraf
    enabled: yes
    state: started

# -------------------------------------------------
# Grafana Dashboards
# -------------------------------------------------
- name: Download dashboards with telegraf datasources
  get_url:
    url: "https://grafana.com/api/dashboards/{{ item.id }}/revisions/{{ item.rev }}/download"
    dest: "{{ grafana_dashboard_dir }}/{{ item.name }}.json"
  loop:
    - { name: syslog, id: 16061, rev: 3 }

- name: Find dashboards
  find:
    paths: "{{ grafana_dashboard_dir }}"
    patterns: "*.json"
  register: grafana_dashboard_files

# -------------------------------------------------
# Patch Loki datasource variable DS_SHIFT-LOGS
# -------------------------------------------------
- name: Patch DS_SHIFT-LOGS to Loki
  replace:
    path: "{{ item.path }}"
    regexp: '\$\{DS_SHIFT-LOGS\}'
    replace: Loki
  loop: "{{ grafana_dashboard_files.files }}"
  loop_control:
    label: "{{ item.path | basename }}"

EOF
