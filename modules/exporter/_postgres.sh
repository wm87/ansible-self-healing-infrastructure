#!bin/bash

set -e

source "modules/exporter/_postgres-exporter.sh"
source "modules/alerts/_alert_postgres.sh"
source "modules/exporter/_prometheus_postgres.sh"
