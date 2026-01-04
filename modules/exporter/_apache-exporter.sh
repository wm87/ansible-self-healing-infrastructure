#!bin/bash

set -e

cat >>"$PROJECT/roles/prometheus/tasks/main.yml" <<'EOL'
# ---------------------
# Apache Exporter
# ---------------------

- name: Stop apache exporter if installed
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: stopped
  loop:
    - apache_exporter
  when: ansible_facts.services[item] is defined

- name: Remove apache exporter service file
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - /etc/systemd/system/apache_exporter.service

- name: Reload systemd
  command: systemctl daemon-reexec

- name: Install apache2-utils
  apt:
    name:
      - apache2-utils
    state: present
    update_cache: yes

- name: Download Apache Exporter
  get_url:
    url: "https://github.com/Lusitaniae/apache_exporter/releases/download/v1.0.10/apache_exporter-1.0.10.linux-amd64.tar.gz"
    dest: /tmp/apache_exporter.tar.gz

- name: Extract Apache Exporter
  unarchive:
    src: /tmp/apache_exporter.tar.gz
    dest: /usr/local/bin/
    remote_src: yes
    extra_opts: [--strip-components=1]

- name: Create Apache Exporter systemd service
  copy:
    dest: /etc/systemd/system/apache_exporter.service
    content: |
      [Unit]
      Description=Prometheus Apache Exporter
      After=network.target

      [Service]
      ExecStart=/usr/local/bin/apache_exporter --scrape_uri="http://localhost/server-status?auto"
      Restart=always
      User=prometheus
      Group=prometheus

      [Install]
      WantedBy=multi-user.target

- name: Enable and start Apache Exporter
  systemd:
    name: apache_exporter
    enabled: yes
    state: started
    daemon_reload: yes

EOL
