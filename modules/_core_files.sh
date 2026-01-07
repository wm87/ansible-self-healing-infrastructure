#!/bin/bash

# ---------------------
# Basisdateien
# ---------------------
cat >"$PROJECT_MT/inventory.yml" <<EOL
all:
  hosts:
    localhost:
      ansible_connection: local
EOL

# Ansible-Konfigurationsdatei erzeugen
cat >"$PROJECT_MT/ansible.cfg" <<EOL
[defaults]
inventory = $PROJECT_MT/inventory.yml
host_key_checking = False
forks = 10
remote_user = $(whoami)
ansible_python_interpreter = /usr/bin/python3

vault_password_file = ~/.ansible/vault_pass.txt

# Optional: Rollen-Pfad
roles_path = $PROJECT_MT/roles
EOL

cat >"$PROJECT_MT/site.yml" <<EOL
- hosts: all
  become: yes
  roles:
    - role: prometheus
    - role: grafana
    - role: loki
    - role: telegraf
    - role: alloy
    - role: alertmanager
EOL
