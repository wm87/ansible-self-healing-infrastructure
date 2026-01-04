#!bin/bash

set -e

source "modules/exporter/_apache-exporter.sh"
source "modules/alerts/_alert_apache.sh"
source "modules/exporter/_prometheus_apache.sh"
