#!/bin/bash

set -e

# ---------------------
# Alertmanager Rolle Setup
# ---------------------

# Verzeichnisse anlegen
mkdir -p "$PROJECT/roles/alertmanager/tasks"
mkdir -p "$PROJECT/roles/alertmanager/handlers"
mkdir -p "$PROJECT/roles/alertmanager/templates"
mkdir -p "$PROJECT/roles/alertmanager/files"
mkdir -p "$PROJECT/group_vars/all"
sudo mkdir -p /etc/alertmanager/secrets

# Vault-Passwort kopieren und Rechte setzen
sudo cp ~/.ansible/vault_pass.txt /etc/alertmanager/secrets/vault_pass.txt
sudo chown prometheus:prometheus /etc/alertmanager/secrets/vault_pass.txt
sudo chmod 600 /etc/alertmanager/secrets/vault_pass.txt

# ---------------------
# Alertmanager E-Mail- und SMTP-Konfiguration
# ---------------------
cat >"$PROJECT/group_vars/all/alertmanager.yml" <<'EOL'
alertmanager_smtp_smarthost: "smtp.example.com:587"
alertmanager_smtp_from: "alertmanager@example.com"
alertmanager_smtp_user: "alertmanager@example.com"
alertmanager_mail_to: "recipient@example.com"
alertmanager_service_user: "prometheus"
alertmanager_service_group: "prometheus"
alertmanager_config_mode: "0644"
alertmanager_vault_pass_file: "/etc/alertmanager/secrets/vault_pass.txt"
EOL

# ---------------------
# Handler
# ---------------------
cat >"$PROJECT/roles/alertmanager/handlers/main.yml" <<'EOL'

- name: "Validate and restart alertmanager"
  block:
    - name: "Validate Alertmanager config"
      command: /usr/bin/prometheus-alertmanager --config.file=/etc/alertmanager/config.yml --log.level=error
      changed_when: false
    - name: "Restart alertmanager"
      service:
        name: prometheus-alertmanager
        state: restarted
EOL

# ---------------------
# Alertmanager Template (config.yml.j2)
# ---------------------
cat >"$PROJECT/roles/alertmanager/templates/config.yml.j2" <<'EOL'
global:
  resolve_timeout: 5m
  smtp_require_tls: true

route:
  receiver: gmail-receiver
  group_by: ['alertname', 'instance', 'severity']
  group_wait: 30s
  group_interval: 2m
  repeat_interval: 4h

  routes:
    - matchers:
        - severity="critical"
      receiver: selfheal-webhook
      continue: true

    - matchers:
        - severity="critical"
      receiver: gmail-receiver

    - matchers:
        - severity="warning"
      receiver: gmail-receiver

receivers:
  - name: gmail-receiver
    email_configs:
      - to: "{{ alertmanager_mail_to }}"
        from: "{{ alertmanager_smtp_from }}"
        smarthost: "{{ alertmanager_smtp_smarthost }}"
        auth_username: "{{ alertmanager_smtp_user }}"
        auth_password_file: "{{ alertmanager_vault_pass_file }}"
        send_resolved: true
        headers:
          Subject: '{% raw %}{{ if eq .Status "resolved" }}🟢 RESOLVED: {{ .CommonLabels.alertname }}{{ else }}🔴 ALERT: {{ .CommonLabels.alertname }}{{ end }}{% endraw %}'
        html: '{% raw %}{{ template "alertmanager_email" . }}{% endraw %}'

  - name: selfheal-webhook
    webhook_configs:
      - url: "http://127.0.0.1:8081/selfheal-webhook"
        send_resolved: false

templates:
  - /etc/alertmanager/alert.tmpl
EOL

# ---------------------
# Mail Template (alert.tmpl)
# ---------------------
sudo tee /etc/alertmanager/alert.tmpl >/dev/null <<'EOL'
{{ define "alertmanager_email" }}
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .critical { color: red; font-weight: bold; }
    .warning { color: orange; font-weight: bold; }
    .resolved { color: green; font-weight: bold; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ccc; padding: 5px; text-align: left; vertical-align: top; }
  </style>
</head>
<body>
<h2>Alert: {{ .CommonLabels.alertname }}</h2>
<p><b>Status:</b> 
  <span class="{{ if eq .Status "firing" }}{{ index .GroupLabels "severity" }}{{ else }}resolved{{ end }}">
    {{ .Status }}
  </span>
</p>

<p><b>Severity:</b> {{ index .GroupLabels "severity" }}</p>
<p><b>Instance:</b> {{ .CommonLabels.instance }}</p>

<table>
  <tr>
    <th>Summary</th>
    <th>Description</th>
    <th>Values</th>
  </tr>
{{ range .Alerts }}
  <tr>
    <td class="{{ if eq .Status "firing" }}{{ .Labels.severity }}{{ else }}resolved{{ end }}">
      {{ .Annotations.summary }}
    </td>
    <td>{{ .Annotations.description | html }}</td>
    <td>
      {{/* ------------------ System Metrics ------------------ */}}
      {{ if .Labels.cpu_usage }}CPU: {{ .Labels.cpu_usage }}%<br>{{ end }}
      {{ if .Labels.memory_usage }}RAM: {{ .Labels.memory_usage }}%<br>{{ end }}
      {{ if .Labels.disk_free }}Disk frei: {{ .Labels.disk_free }}%<br>{{ end }}
      {{ if .Labels.network_receive }}Netzwerk eingehend: {{ .Labels.network_receive }} Bytes/s<br>{{ end }}
      {{ if .Labels.network_transmit }}Netzwerk ausgehend: {{ .Labels.network_transmit }} Bytes/s<br>{{ end }}
      {{ if .Labels.connections }}Connections: {{ .Labels.connections }}<br>{{ end }}
      
      {{/* ------------------ Application Metrics ------------------ */}}
      {{ if .Labels.apache_status }}Apache: <span class="{{ if eq .Labels.apache_status "down" }}critical{{ else if eq .Labels.apache_status "high_5xx" }}warning{{ else }}resolved{{ end }}">
        {{ .Labels.apache_status }}
      </span><br>{{ end }}
      {{ if .Labels.apache_5xx_rate }}Apache 5xx Rate: {{ .Labels.apache_5xx_rate }}<br>{{ end }}

      {{ if .Labels.mysql_status }}MySQL: <span class="{{ if eq .Labels.mysql_status "down" }}critical{{ else }}resolved{{ end }}">
        {{ .Labels.mysql_status }}
      </span><br>{{ end }}
      {{ if .Labels.mysql_connections }}MySQL Connections: {{ .Labels.mysql_connections }}<br>{{ end }}

      {{ if .Labels.postgres_status }}PostgreSQL: <span class="{{ if eq .Labels.postgres_status "down" }}critical{{ else }}resolved{{ end }}">
        {{ .Labels.postgres_status }}
      </span><br>{{ end }}
    </td>
  </tr>
{{ end }}
</table>

<p><b>Auto-Resolve Info:</b> 
  {{ if eq .Status "resolved" }}Problem behoben ✅{{ else }}Noch aktiv ⚠️{{ end }}
</p>
<hr>
</body>
</html>
{{ end }}
EOL

sudo chown prometheus:prometheus /etc/alertmanager/alert.tmpl
sudo chmod 644 /etc/alertmanager/alert.tmpl

# ---------------------
# Tasks
# ---------------------
cat >"$PROJECT/roles/alertmanager/tasks/main.yml" <<'EOL'
- name: Install Alertmanager
  apt:
    name: prometheus-alertmanager
    state: present
    update_cache: yes

- name: Ensure Alertmanager config directory exists
  file:
    path: /etc/alertmanager
    state: directory
    owner: "{{ alertmanager_service_user }}"
    group: "{{ alertmanager_service_group }}"
    mode: '0755'

- name: Deploy Alertmanager config
  template:
    src: config.yml.j2
    dest: /etc/alertmanager/config.yml
    owner: "{{ alertmanager_service_user }}"
    group: "{{ alertmanager_service_group }}"
    mode: "{{ alertmanager_config_mode }}"
  notify: "Validate and restart alertmanager"
EOL

# ---------------------
# Systemd Drop-in Override inkl. UI aktivieren
# ---------------------
sudo mkdir -p /etc/systemd/system/prometheus-alertmanager.service.d

sudo tee /etc/systemd/system/prometheus-alertmanager.service.d/override.conf >/dev/null <<'EOL'
[Service]
ExecStart=
ExecStart=/usr/bin/prometheus-alertmanager \
  --config.file=/etc/alertmanager/config.yml
Restart=on-failure
User=prometheus
Group=prometheus
EOL
