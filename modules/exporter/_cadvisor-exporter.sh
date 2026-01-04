#!/bin/bash
set -e

cat >>"$PROJECT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# cAdvisor Exporter
# ---------------------

- name: Gather service facts
  service_facts:

- name: Stop and disable cadvisor if exists
  ansible.builtin.systemd:
    name: cadvisor
    state: stopped
    enabled: no
  when: "'cadvisor.service' in ansible_facts.services"
  ignore_errors: yes

- name: Remove old cadvisor service file
  ansible.builtin.file:
    path: /etc/systemd/system/cadvisor.service
    state: absent

- name: Reload systemd after removal
  ansible.builtin.systemd:
    daemon_reload: yes

- name: Download cAdvisor binary
  ansible.builtin.get_url:
    url: https://github.com/google/cadvisor/releases/download/v0.55.1/cadvisor-v0.55.1-linux-amd64
    dest: /usr/local/bin/cadvisor
    mode: '0755'

- name: Create systemd service for cAdvisor
  ansible.builtin.copy:
    dest: /etc/systemd/system/cadvisor.service
    mode: '0644'
    content: |
      [Unit]
      Description=cAdvisor
      Wants=network-online.target
      After=network-online.target

      [Service]
      User=root
      ExecStart=/usr/local/bin/cadvisor \
        --logtostderr \
        --port=9050
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd after install
  ansible.builtin.systemd:
    daemon_reload: yes

- name: Enable and start cAdvisor
  ansible.builtin.systemd:
    name: cadvisor
    enabled: yes
    state: started
EOL
