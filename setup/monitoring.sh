#!/bin/bash

# ========================================================
# Komplettes Setup-Skript:
#
#	* Secure Self-Healing Projekt
# 	* inkl. Grafana Dashboards
# 	* inkl. Self-Healing Mechanismen
# 	* inkl. Hardening Maßnahmen
# 	* inkl. Monitoring mit Prometheus
# 	* inkl. Alertmanager
#	* inkl. Exporter für Apache, MySQL, PostgreSQL, Node Exporter, cAdvisor, SNMP
# 	* inkl. Grafana Alloy und Grafana Loki für Logmanagement
# ========================================================

set -e

# ---------------------
# Ordnerstruktur
# ---------------------
source modules/_file_hierarchy.sh

# ---------------------
# Basisdateien
# ---------------------
source modules/_core_files.sh

# ---------------------
# Hardening Rolle
# ---------------------
source modules/_hardening.sh

# ---------------------
# Prometheus Rolle
# ---------------------
source modules/_prometheus.sh

# ---------------------
# SNMP
# ---------------------
#source modules/snmp/_snmp.sh

# ---------------------
# Exporter
# ---------------------
source modules/exporter/_apache.sh
source modules/exporter/_apache-logs.sh
source modules/exporter/_node.sh
source modules/exporter/_mysql.sh
source modules/exporter/_postgres.sh

# ---------------------
# Grafana Rolle
# ---------------------
source modules/_grafana.sh

source modules/_grafana_loki.sh
source modules/_alloy.sh
source modules/dashboards/_all-logs.sh

source modules/_grafana_prometheus.sh
source modules/_grafana_telegraf.sh

# ---------------------
# Alertmanager Rolle
# ---------------------
source modules/_alertmanager.sh
