#!bin/bash

set -e

source "modules/exporter/_cadvisor-exporter.sh"
source "modules/exporter/_prometheus_cadvisor.sh"
source "modules/exporter/_prometheus_apache-logs.sh"
