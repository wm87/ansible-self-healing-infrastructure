#!/bin/bash
set -e

# -------------------------------
# Basisvariablen
# -------------------------------
PROJECT="${PROJECT:-/tmp/self-healing}"
ROLE_DIR="$PROJECT/roles/alloy"
TASKS_DIR="$ROLE_DIR/tasks"
VARS_DIR="$ROLE_DIR/vars"
HANDLERS_DIR="$ROLE_DIR/handlers"
FILES_DIR="$ROLE_DIR/files"

mkdir -p "$TASKS_DIR" "$VARS_DIR" "$HANDLERS_DIR" "$FILES_DIR"

# -------------------------------
# Variablen main.yml
# -------------------------------
cat >"$VARS_DIR/main.yml" <<'EOF'
alloy_version: "1.12.1"
grafana_dashboard_dir: "/var/lib/grafana/dashboards"
loki_endpoint: "http://localhost:3100/loki/api/v1/push"
EOF

# -------------------------------
# Handlers main.yml
# -------------------------------
cat >"$HANDLERS_DIR/main.yml" <<'EOF'
- name: restart alloy
  systemd:
    name: alloy
    state: restarted
EOF

# -------------------------------
# Alloy Hauptconfig (HCL-kompatibel)
# -------------------------------
cat >"$FILES_DIR/config.alloy" <<'EOF'

local.file_match "local_files" {
  path_targets = [
    {"__path__" = "/var/log/**/*.log"},
  ]
}
loki.source.file "log_scrape" {
  targets       = local.file_match.local_files.targets
  tail_from_end = false
  forward_to    = [loki.process.process_logs.receiver]
}

loki.process "process_logs" {

  stage.labels {
    values = {
      filename = "__path__",
      host     = "__host__",
	  source   = "file",
    }
  }

  forward_to = [loki.write.local_loki.receiver]
}

loki.write "local_loki" {
  endpoint {
    url = "http://localhost:3100/loki/api/v1/push"
	basic_auth {
	  username = "admin"
	  password = "admin"
	}
  }
}
EOF

# -------------------------------
# Tasks main.yml
# -------------------------------
cat >"$TASKS_DIR/main.yml" <<'EOF'
- name: Ensure dependencies
  apt:
    name:
      - wget
      - apt-transport-https
    state: present
    update_cache: yes

- name: Download Alloy .deb
  get_url:
    url: "https://github.com/grafana/alloy/releases/download/v{{ alloy_version }}/alloy-{{ alloy_version }}-1.amd64.deb"
    dest: "/tmp/alloy-{{ alloy_version }}.deb"
    mode: '0644'

- name: Install Alloy .deb
  apt:
    deb: "/tmp/alloy-{{ alloy_version }}.deb"
    state: present

- name: Cleanup Alloy .deb
  file:
    path: "/tmp/alloy-{{ alloy_version }}.deb"
    state: absent

- name: Deploy config.alloy
  copy:
    src: config.alloy
    dest: /etc/alloy/config.alloy
    owner: root
    group: root
    mode: '0644'
  notify: restart alloy

- name: Create alloy systemd service
  copy:
    dest: /etc/systemd/system/alloy.service
    mode: '0644'
    content: |
      [Unit]
      Description=Grafana Alloy
      After=network.target

      [Service]
      ExecStart=/usr/bin/alloy run /etc/alloy/config.alloy
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

- name: Reload systemd
  systemd:
    daemon_reload: yes

- name: Enable and start Alloy
  systemd:
    name: alloy
    enabled: yes
    state: started

EOF
