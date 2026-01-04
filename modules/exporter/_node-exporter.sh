#!bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# Node-Exporter
# ---------------------

- name: Stop Node-Exporter if installed
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: stopped
  loop:
    - prometheus-node-exporter
  when: ansible_facts.services[item] is defined


- name: Purge Node-Exporter packages
  apt:
    name:
      - prometheus-node-exporter
    state: absent
    purge: yes
    autoremove: yes

- name: Reload systemd
  command: systemctl daemon-reexec


- name: Install Node-Exporter
  apt:
    name:
      - prometheus-node-exporter
    state: present
    update_cache: yes

EOL
