#!/bin/bash
# Prometheus setup script
PROMETHEUS_DIR=\$(pwd)
echo "Starting Prometheus from \$PROMETHEUS_DIR"
./prometheus --config.file=\$PROMETHEUS_DIR/prometheus.yml --storage.tsdb.path=\$PROMETHEUS_DIR/data
