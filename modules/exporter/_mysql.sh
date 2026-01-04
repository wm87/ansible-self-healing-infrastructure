#!bin/bash

set -e

source "modules/exporter/_mysql-exporter.sh"
source "modules/alerts/_alert_mysql.sh"
source "modules/exporter/_prometheus_mysql.sh"
