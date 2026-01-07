#!/bin/bash

# ---------------------
# Hardening Rolle
# ---------------------
cat >"$PROJECT_SH/roles/hardening/tasks/main.yml" <<EOL
- name: Install essential packages
  apt:
    name: [ufw, fail2ban, unattended-upgrades]
    state: present
    update_cache: yes

- name: Configure SSH
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
  notify: Restart ssh

- name: Allow SSH
  ufw:
    rule: allow
    port: "22"
    proto: tcp

- name: Enable firewall
  ufw:
    state: enabled

- name: Configure Fail2Ban
  template:
    src: jail.local
    dest: /etc/fail2ban/jail.local
  notify: Restart fail2ban
EOL

cat >"$PROJECT_SH/roles/hardening/handlers/main.yml" <<EOL
- name: Restart ssh
  service:
    name: ssh
    state: restarted
- name: Restart fail2ban
  service:
    name: fail2ban
    state: restarted
EOL

cat >"$PROJECT_SH/roles/hardening/templates/sshd_config.j2" <<EOL
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
EOL

cat >"$PROJECT_SH/roles/hardening/templates/jail.local" <<EOL
[DEFAULT]
bantime  = 3600
findtime  = 600
maxretry = 5
backend = systemd
[sshd]
enabled = true
EOL
