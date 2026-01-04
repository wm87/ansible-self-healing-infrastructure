#!/bin/bash

set -e

# -------------------------------
# Basisvariablen
# -------------------------------
PROJECT="${PROJECT:-/tmp/self-healing}"
LOKI_VERSION="3.6.3"

ROLES_DIR="$PROJECT/roles/loki"
TASKS_DIR="$ROLES_DIR/tasks"
VARS_DIR="$ROLES_DIR/vars"
HANDLERS_DIR="$ROLES_DIR/handlers"
FILES_DIR="$ROLES_DIR/files"

LOKI_BIN="/usr/local/bin/loki"
LOKI_CONFIG="/etc/loki.yaml"
LOKI_SERVICE="/etc/systemd/system/loki.service"

LOKI_USER="loki"
LOKI_GROUP="loki"
LOKI_DATA_DIR="/var/lib/loki"
LOKI_CHUNKS_DIR="$LOKI_DATA_DIR/chunks"
LOKI_RULES_DIR="$LOKI_DATA_DIR/rules"

GRAFANA_URL="http://localhost:3000"
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="admin"

grafana_dashboard_dir="/var/lib/grafana/dashboards"

# -------------------------------
# Verzeichnisse anlegen
# -------------------------------
mkdir -p "$TASKS_DIR" "$VARS_DIR" "$HANDLERS_DIR" "$FILES_DIR"

# -------------------------------
# Variablen main.yml
# -------------------------------
cat >"$VARS_DIR/main.yml" <<EOL
loki_version: "$LOKI_VERSION"
loki_user: "$LOKI_USER"
loki_group: "$LOKI_GROUP"
loki_bin: "$LOKI_BIN"
loki_config: "$LOKI_CONFIG"
loki_service: "$LOKI_SERVICE"

loki_data_dir: "$LOKI_DATA_DIR"
loki_chunks_dir: "$LOKI_CHUNKS_DIR"
loki_rules_dir: "$LOKI_RULES_DIR"

grafana_url: "$GRAFANA_URL"
grafana_admin_user: "$GRAFANA_ADMIN_USER"
grafana_admin_password: "$GRAFANA_ADMIN_PASSWORD"

grafana_dashboard_dir: "$grafana_dashboard_dir"
EOL

# -------------------------------
# Handler main.yml
# -------------------------------
cat >"$HANDLERS_DIR/main.yml" <<EOL
- name: restart loki
  systemd:
    name: loki
    state: restarted
EOL

# -------------------------------
# Tasks main.yml
# -------------------------------
cat >"$TASKS_DIR/main.yml" <<'EOL'
# -------------------------------
# Loki User & Verzeichnisse
# -------------------------------
- name: Ensure Loki user exists
  user:
    name: "{{ loki_user }}"
    system: yes
    shell: /usr/sbin/nologin

- name: Create Loki directories
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ loki_user }}"
    group: "{{ loki_group }}"
    mode: '0755'
  loop:
    - "{{ loki_data_dir }}"
    - "{{ loki_chunks_dir }}"
    - "{{ loki_rules_dir }}"

# -------------------------------
# Loki Download & Installation
# -------------------------------
- name: Download Loki zip
  get_url:
    url: "https://github.com/grafana/loki/releases/download/v{{ loki_version }}/loki-linux-amd64.zip"
    dest: "{{ ansible_env.HOME }}/loki.zip"
    mode: '0644'

- name: Unzip Loki binary
  unarchive:
    src: "{{ ansible_env.HOME }}/loki.zip"
    dest: /usr/local/bin/
    remote_src: yes
    creates: /usr/local/bin/loki-linux-amd64

- name: Rename Loki binary
  command: mv /usr/local/bin/loki-linux-amd64 /usr/local/bin/loki
  args:
    creates: /usr/local/bin/loki

- name: Make Loki executable
  file:
    path: /usr/local/bin/loki
    mode: '0755'

- name: Remove Loki zip
  file:
    path: "{{ ansible_env.HOME }}/loki.zip"
    state: absent

# -------------------------------
# Loki Config
# -------------------------------
- name: Deploy Loki config
  copy:
    dest: "{{ loki_config }}"
    content: |
      auth_enabled: false

      server:
        http_listen_port: 3100

      common:
        path_prefix: {{ loki_data_dir }}
        storage:
          filesystem:
            chunks_directory: {{ loki_chunks_dir }}
            rules_directory: {{ loki_rules_dir }}
        replication_factor: 1
        ring:
          kvstore:
            store: inmemory

      schema_config:
        configs:
          - from: 2024-01-01
            store: tsdb
            object_store: filesystem
            schema: v13
            index:
              prefix: index_
              period: 24h
    owner: "{{ loki_user }}"
    group: "{{ loki_group }}"
    mode: '0640'

# -------------------------------
# Systemd Service
# -------------------------------
- name: Deploy Loki systemd service
  copy:
    dest: "{{ loki_service }}"
    content: |
      [Unit]
      Description=Loki Log Aggregation System
      After=network.target

      [Service]
      User={{ loki_user }}
      Group={{ loki_group }}
      Type=simple
      ExecStart={{ loki_bin }} -config.file={{ loki_config }}
      Restart=always
      LimitNOFILE=1048576

      [Install]
      WantedBy=multi-user.target
    mode: '0644'

- name: Enable and start Loki service
  systemd:
    name: loki
    enabled: yes
    state: started

# -------------------------------
# Grafana Datasource
# -------------------------------
- name: Add Loki datasource to Grafana
  uri:
    url: "{{ grafana_url }}/api/datasources"
    method: POST
    user: "{{ grafana_admin_user }}"
    password: "{{ grafana_admin_password }}"
    force_basic_auth: yes
    status_code: 200,409
    body: |
      {
        "name": "Loki",
        "type": "loki",
        "access": "proxy",
        "url": "http://localhost:3100",
        "isDefault": false
      }
    body_format: json

# -------------------------------
# Dashboard Logs-ServiceName
# -------------------------------
- name: Download dashboards with loki datasource
  get_url:
    url: "https://grafana.com/api/dashboards/{{ item.id }}/revisions/{{ item.rev }}/download"
    dest: "{{ grafana_dashboard_dir }}/{{ item.name }}.json"
  loop:
    - { name: logs_servicename, id: 23129, rev: 2 }
  notify: restart grafana

- name: Find dashboards
  find:
    paths: "{{ grafana_dashboard_dir }}"
    patterns: "*.json"
  register: grafana_dashboard_files

# -------------------------------------------------
# Patch Loki datasource variable DS_LOKI
# -------------------------------------------------
- name: Patch DS_LOKI to Loki
  replace:
    path: "{{ item.path }}"
    regexp: '\$\{DS_LOKI\}'
    replace: Loki
  loop: "{{ grafana_dashboard_files.files }}"
  loop_control:
    label: "{{ item.path | basename }}"

EOL
