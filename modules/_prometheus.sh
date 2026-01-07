#!/bin/bash

set -e

# ---------------------
# Prometheus Rolle
# ---------------------

cat >"$PROJECT_MT/roles/prometheus/vars/main.yml" <<EOL
# Prometheus Defaults
EOL

cat >"$PROJECT_MT/roles/prometheus/handlers/main.yml" <<'EOL'
- name: Validate Prometheus config
  command: promtool check config /etc/prometheus/prometheus.yml
  changed_when: false

- name: Reload Prometheus
  systemd:
    name: prometheus
    state: reloaded
EOL

cat >"$PROJECT_MT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# Prometheus
# ---------------------

- name: Stop Prometheus if installed
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: stopped
  loop:
    - prometheus
  when: ansible_facts.services[item] is defined

- name: Purge Prometheus packages
  apt:
    name:
      - prometheus
    state: absent
    purge: yes
    autoremove: yes

- name: Remove Prometheus directories
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - /etc/prometheus
    - /var/lib/prometheus
    - /var/log/prometheus

- name: Reload systemd
  command: systemctl daemon-reexec

- name: Install Prometheus server
  apt:
    name:
      - prometheus
    state: present
    update_cache: yes

EOL

cat >"$PROJECT_MT/roles/prometheus/files/alert_rules.yml" <<'EOL'
groups:
EOL

# Import default Alert Rules
#source "modules/alerts/_alert_selfheal.sh"
source "modules/alerts/_alert_host.sh"

cat >>"$PROJECT_MT/roles/prometheus/tasks/main.yml" <<'EOL'
- name: Deploy alert rules
  copy:
    src: files/alert_rules.yml
    dest: /etc/prometheus/alert_rules.yml
    owner: prometheus
    group: prometheus
    mode: '0644'
EOL

# =====================
# PROMETHEUS CONFIG
# =====================
cat >"$PROJECT_MT/roles/prometheus/templates/prometheus.yml.j2" <<'EOL'
global:
  scrape_interval: 10s
  evaluation_interval: 10s

# =====================
# Alerts
# =====================
rule_files:
  - /etc/prometheus/alert_rules.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - "localhost:9093"  # oder IP/DNS vom Alertmanager

# =====================
# Scrape Targets
# =====================
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'selfheal'
    honor_labels: true
    static_configs:
      - targets: ['localhost:9091']
EOL

cat >>"$PROJECT_MT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# Prometheus config deployment
# ---------------------
- name: Deploy Prometheus config
  template:
    src: prometheus.yml.j2
    dest: /etc/prometheus/prometheus.yml
    owner: prometheus
    group: prometheus
    mode: '0644'
  notify:
    - Validate Prometheus config
    - Reload Prometheus
EOL
