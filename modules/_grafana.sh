#!/bin/bash

set -e

# ---------------------
# Setup für Grafana Rolle inkl. Dashboard-Provisioning
# ---------------------

# Basisverzeichnisse
PROVISIONING_DIR="$PROJECT/roles/grafana/templates/provisioning/dashboards"
TASKS_DIR="$PROJECT/roles/grafana/tasks"
VARS_DIR="$PROJECT/roles/grafana/vars"
HANDLERS_DIR="$PROJECT/roles/grafana/handlers"

mkdir -p "$PROVISIONING_DIR" "$TASKS_DIR" "$VARS_DIR" "$HANDLERS_DIR"

# -------------------------------
# Grafana Variablen
# -------------------------------
cat >"$VARS_DIR/main.yml" <<EOL
prometheus_ds: "Prometheus"
prometheus_url: "http://localhost:9090"

grafana_url: "http://localhost:3000"
grafana_admin_user: "admin"
grafana_admin_password: "admin"

grafana_dashboard_dir: /var/lib/grafana/dashboards
grafana_provisioning_dir: /etc/grafana/provisioning/dashboards

EOL

# -------------------------------
# Handler
# -------------------------------
cat >"$HANDLERS_DIR/main.yml" <<EOL
- name: restart grafana
  service:
    name: grafana-server
    state: restarted
EOL

# -------------------------------
# Provisioning Template
# -------------------------------
cat >"$PROVISIONING_DIR/dashboard.yml.j2" <<'EOL'
apiVersion: 1
providers:
  - name: 'Provisioned Dashboards'
    orgId: 1
    folder: ""
    type: file
    editable: true
    options:
      path: {{ grafana_dashboard_dir }}
EOL

# -------------------------------
# Haupttasks main.yml
# -------------------------------
cat >"$TASKS_DIR/main.yml" <<'EOL'
# -------------------------------------------------
# INSTALL & START
# -------------------------------------------------
- name: Install required packages
  apt:
    name:
      - apt-transport-https
      - software-properties-common
      - wget
      - adduser
      - libfontconfig1
    state: present
    update_cache: yes

- name: Download Grafana Enterprise
  get_url:
    url: https://dl.grafana.com/grafana-enterprise/release/12.3.1/grafana-enterprise_12.3.1_20271043721_linux_amd64.deb
    dest: /tmp/grafana.deb

- name: Install Grafana
  command: dpkg -i /tmp/grafana.deb
  ignore_errors: yes

- name: Fix dependencies
  command: apt-get install -f -y

- name: Ensure Grafana running
  service:
    name: grafana-server
    state: started
    enabled: yes

- name: Wait for Grafana API
  uri:
    url: "{{ grafana_url }}/api/health"
    status_code: 200
  register: grafana_health
  retries: 10
  delay: 5
  until: grafana_health.status == 200

# -------------------------------------------------
# DATASOURCE
# -------------------------------------------------
- name: Create Prometheus datasource
  community.grafana.grafana_datasource:
    name: "{{ prometheus_ds }}"
    ds_type: prometheus
    ds_url: "{{ prometheus_url }}"
    access: proxy
    state: present
    grafana_user: "{{ grafana_admin_user }}"
    grafana_password: "{{ grafana_admin_password }}"
    grafana_url: "{{ grafana_url }}"

# -------------------------------------------------
# PROVISIONING
# -------------------------------------------------
- name: Ensure dashboard directory
  file:
    path: "{{ grafana_dashboard_dir }}"
    state: directory
    owner: grafana
    group: grafana

- name: Ensure provisioning directory
  file:
    path: "{{ grafana_provisioning_dir }}"
    state: directory

- name: Deploy provisioning config
  template:
    src: provisioning/dashboards/dashboard.yml.j2
    dest: "{{ grafana_provisioning_dir }}/dashboards.yml"
  notify: restart grafana

EOL
