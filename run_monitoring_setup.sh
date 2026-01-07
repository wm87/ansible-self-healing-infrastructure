#!/bin/bash

set -e

export PROJECT_MT="$(pwd)/monitoring"

#/etc/postgresql/18/main/pg_hba.conf
# Allow postgres_exporter user
#host    postgres        postgres_exporter    127.0.0.1/32    md5

# ========================================
# Setup: alte Grafana-Source entfernen, Projekt neu erstellen
# ========================================
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -rf monitoring/
bash ./setup/monitoring.sh

# ========================================
# Installation / Aufbau aller Rollen
# ========================================
echo "🛠 Starte Installation aller Rollen ..."
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i monitoring/inventory.yml monitoring/site.yml
echo "✅ Installation abgeschlossen."

echo
echo "🌐 Web-UIs der installierten Dienste:"
if systemctl list-unit-files | grep -q "^grafana-server.service"; then
	echo "- Grafana: http://localhost:3000 (User: admin / Password: admin)"
fi
if systemctl list-unit-files | grep -q "^prometheus.service"; then
	echo "- Prometheus: http://localhost:9090"
fi
if systemctl list-unit-files | grep -q "^prometheus-alertmanager.service"; then
	sudo systemctl daemon-reload
	sudo systemctl restart prometheus-alertmanager
	#sudo systemctl status prometheus-alertmanager

	echo "- Alertmanager: http://localhost:9093"
	echo "  - Test Alert: amtool --alertmanager.url=http://localhost:9093 alert add test_alert severity=critical"
fi
echo

echo "💡 Demo kann separat gestartet werden mit: bash run_demo.sh"
