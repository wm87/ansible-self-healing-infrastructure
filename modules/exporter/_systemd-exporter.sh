#!/bin/bash

set -e

cat >>"$PROJECT_MT/roles/prometheus/tasks/main.yml" <<'EOL'

# ---------------------
# Systemd Exporter
# ---------------------

- name: Gather service facts
  service_facts:

- name: Stop systemd_exporter if installed
  ansible.builtin.systemd:
    name: systemd_exporter
    state: stopped
  when: "'systemd_exporter.service' in ansible_facts.services"

- name: Remove old systemd_exporter service
  file:
    path: /etc/systemd/system/systemd_exporter.service
    state: absent

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Download systemd_exporter
  get_url:
    url: "https://github.com/prometheus-community/systemd_exporter/releases/download/v0.7.0/systemd_exporter-0.7.0.linux-amd64.tar.gz"
    dest: /tmp/systemd_exporter.tar.gz

- name: Extract systemd_exporter
  unarchive:
    src: /tmp/systemd_exporter.tar.gz
    dest: /tmp/
    remote_src: yes

- name: Install systemd_exporter binary
  copy:
    src: /tmp/systemd_exporter-0.7.0.linux-amd64/systemd_exporter
    dest: /usr/local/bin/systemd_exporter
    mode: '0755'
    remote_src: yes

- name: Create systemd_exporter service
  copy:
    dest: /etc/systemd/system/systemd_exporter.service
    content: |
      [Unit]
      Description=Prometheus Systemd Exporter
      After=network.target

      [Service]
      User=prometheus
      Group=prometheus
      ExecStart=/usr/local/bin/systemd_exporter
      Restart=always

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start systemd_exporter
  systemd:
    name: systemd_exporter
    enabled: yes
    state: started

EOL
