![Ansible Version](https://img.shields.io/badge/ansible-v2.19.0-blue)
![Linux](https://img.shields.io/badge/os-Linux-lightgrey)
![Prometheus](https://img.shields.io/badge/prometheus-monitoring-orange)
![Grafana](https://img.shields.io/badge/grafana-dashboards-blueviolet)

# Secure Self-Healing Infrastructure (SSHI) - WIP


**SSHI** ist ein vollautomatisiertes, modular aufgebautes Monitoring- und Observability-Projekt für Linux-Server. Es kombiniert **Prometheus**, **Grafana**, **Node-, Apache-, MySQL- und PostgreSQL-Exporter** mit einem **ansible-basierten Selbstheilungsskript**, das eine stabile, reproduzierbare und wartbare Infrastruktur sicherstellt.

Dieses Projekt richtet sich an DevOps, Systemadministratoren und Infrastruktur-Architekten, die eine robuste Monitoring-Lösung einrichten möchten, die bei Fehlern automatisch repariert oder neu initialisiert wird.

---

## 💡 Motivation

Dieses Projekt wird entwickelt, um eine **vollständig wartbare, reproduzierbare Monitoring-Lösung** zu schaffen, die sich selbst heilen kann und den Administrationsaufwand minimiert. Perfekt für produktive Umgebungen, Testsysteme oder als Basis für Observability-Labs.

Dieses Repository zeigt:

* echtes Infrastructure-as-Code-Denken
* saubere Automatisierung statt Skript-Chaos
* Monitoring, Alerting und Self-Healing als Gesamtsystem

---

## 🚀 Features Monitoring

- **Automatisierte Installation & Konfiguration**
  - Prometheus, Grafana und alle relevanten Exporter
  - Dashboards für Node, Apache, MySQL, PostgreSQL und Docker
- **Exporter-Unterstützung**
  - Node Exporter: Systemmetriken
  - Apache Exporter: HTTP-Server-Status
  - MySQL Exporter: Datenbankmetriken
  - PostgreSQL Exporter: Datenbankmetriken
  - Docker Exporter: Container-Überwachung
  - Systemd Exporter: Überwachung von Systemd‑Services und Units
- **Out-of-the-box Grafana Dashboards**
  - Vorinstallierte Dashboards mit Prometheus-Datenquellen
  - Automatische Dashboard-Provisionierung
- **Benutzerfreundlich**
  - gute manuelle Konfiguration
  - Alert-Versand via Mail
  - Rollen- und Rechteverwaltung für Datenbank-Exporter

## 🚀 Features Selbtheilung

- **Alertmanager** löst Webhook (selfheal_webhook.py) für Selbstheilungsskript (selfhealing_szenario.sh) aus

- **Preflight-Checks**: Überprüft die Systemgesundheit, bevor versucht wird, Dienste zu heilen. Zu den Checks gehören freier RAM, Swap-Nutzung, CPU-Last und freier Festplattenspeicher.

- **Zustandsmaschine**: Nutzt eine definierte Abfolge von Zuständen zur Wiederherstellung von Diensten:
  - Zustände wie `restart`, `cleanup`, `reload`, `scale_service`, `network_heal`, `memory_recovery` und `fsck_approval`.
  - Wenn eine Wiederherstellungsmaßnahme für einen Dienst fehlschlägt, wird versucht, zum nächsten Zustand überzugehen, bis der Dienst geheilt ist oder ein Endzustand erreicht wird.

- **Dienste-Wiederherstellung**: Dienste wie Apache, MySQL, PostgreSQL und Docker werden von der Selbstheilungs-Zustandsmaschine verwaltet. Jeder Dienst hat einen eigenen Wiederherstellungsfluss mit Schweregradstufen (kritisch, hoch, mittel).

- **Push nach Prometheus**: Metriken zur Dienstwiederherstellung, Fehlern und Status werden an **Prometheus Pushgateway** zur Überwachung gesendet. Metriken umfassen Erfolg/Fehler-Zähler und den zuletzt ausgeführten Zustand.

- **FSCK-Zustimmung**: Es wird optional nach einer Zustimmung für FSCK (Filesystem Check) gefragt, bevor riskante Wiederherstellungsmaßnahmen durchgeführt werden.

---

## Demo-Ablauf (lokal)

### Infrastruktur ausrollen:

```bash
# Setup Monitoring
bash run_monitoring_setup.sh

# Setup Selbstheilung
bash run_healing_setup.sh
```

### Ausfall-Demo starten:

```bash
# Ausfall simulieren
sudo systemctl stop apache2
sudo systemctl stop mysql
sudo systemctl stop postgresql

# Start Reperatur-Demo für ausgewählte Dienste
bash run_healing_demo.sh
```

###  Prüfen in Grafana z.B. mit Board "Alerts"

```text
http://localhost:3000/login
```


## 🛠 work in progress

* Board für Erfolge/Fehlschläge der automatisierten Reperaturen
* ~~Services werden absichtlich gestoppt~~
* ~~Prometheus erkennt den Ausfall~~
* ~~Alertmanager sendet automatisch E-Mail's für Alert und Resolve~~
* ~~Alertmanager löst Webhook für Selbstheilungsskript aus~~
* ~~Automatische Reparatur-Ausführung bei instabilen/kritischen Zustand (welche Dienste und Möglichkeiten sinnvoll sind, wird noch genauer eruiert)~~
* ~~Prometheus zeigt den wiederhergestellten Zustand~~

## ⚡ Hinweise

- Alle notwendigen Abhängigkeiten (Python, Postgres/MySQL Clients, Grafana, Prometheus) werden automatisch installiert
- PostgreSQL Exporter benötigt spezifische Rechte für `pg_monitor` und andere Collector
- Exporter brauchen ggf. weitere Rechte bspw. für MySQL
- Die Playbooks erkennen fehlerhafte Services automatisch und starten sie neu.
- Dashboards enthalten out-of-the-box Metriken und können bei Bedarf erweitert werden.

```yml
# _alertmanager.sh
# Alertmanager E-Mail- und SMTP-Konfiguration

alertmanager_smtp_smarthost: "smtp.example.com:587"
alertmanager_smtp_from: "alertmanager@example.com"
alertmanager_smtp_user: "alertmanager@example.com"
alertmanager_mail_to: "recipient@example.com"
alertmanager_service_user: "prometheus"
alertmanager_service_group: "prometheus"
alertmanager_config_mode: "0644"
alertmanager_vault_pass_file: "/etc/alertmanager/secrets/vault_pass.txt"
```


## Debugging

```bash
# arbeitet Alertmanger ?
sudo -u prometheus /usr/bin/prometheus-alertmanager   --config.file=/etc/alertmanager/config.yml   --log.level=debug

# arbeitet selfheal_webhook.py ?
journalctl -u selfheal-webhook -f

# arbeitet alloy ?
journalctl -u alloy -f
```

---


## 📊 Dashboards

Nach erfolgreichem Deployment sind u.a. die folgenden Dashboards sofort in Grafana verfügbar:

| Dashboard | Beschreibung |
|-----------|--------------|
| Node Exporter | Servermetriken (CPU, RAM, Disk, Netzwerk) |
| Apache | HTTP-Server Metriken |
| MySQL | Datenbank-Metriken |
| PostgreSQL | Datenbank-Metriken |
| Docker | Container-Überwachung |

Alle Dashboards werden automatisch mit den entsprechenden Datenquellen verbunden.

---

## Architekturübersicht

```
+-------------------------+
|        Grafana          |
|  Dashboards & Visuals   |
+-----------+-------------+
            ^
            |
+-------------------------+      +-------------------------+
|       Prometheus        |----->|     Alertmanager        |
|  Metrics Collection     |      |  Alerts & Notifications |
+-----------+-------------+      +-------------------------+
            ^                        |
            |                        v
+-------------------------+      +-------------------------+
|     Linux Hosts         |<-----|    Self-Healing         |
|  Node, MySQL, PostgreSQL|      |  Repair Actions         |
|  Apache, Docker, etc.   |      |  (Triggered by Alarms)  |
+-----------+-------------+      +-------------------------+
            ^
            |
+-------------------------+
|     Ansible Engine      |
|  Self-Healing & Config  |
+-------------------------+

```

### Erläuterung der Architektur

- **Ansible Engine:**
  Steuert die gesamte Konfiguration der Hosts, installiert Exporter, setzt Passwörter und sorgt für Self-Healing.

- **Linux Hosts:**
  Hier laufen die Services und Exporter (Node, MySQL, PostgreSQL, Apache, Docker).

- **Prometheus:**
  Sammelt Metriken von allen Exportern und speichert sie für Visualisierung. Alerts werden hier ebenfalls automatisch definiert und angezeigt.

- **Alertmanager:**
  Nimmt die von Prometheus generierten Alerts entgegen, verwaltet sie (Gruppierung, Wiederholungen) und versendet Benachrichtigungen per E-Mail oder andere Kanäle.

- **Grafana:**
  Nutzt Prometheus als Datenquelle und zeigt die Metriken in Dashboards an.

---

## Meine Board's

[Alloy Loki Error/Warning Logs](https://github.com/wm87/grafana_alloy_loki_logs)

---

## Erweiterungen (Ideen)

* GitHub Actions CI (ansible-lint)
* Kubernetes-Anbindung
* Slack / MS Teams Alerts
* Auto-Scaling Integrationen

---

## 📜 Lizenz

MIT License © 2025

---

