#!/bin/bash
# Grafana setup script
GRAFANA_DIR=\$(pwd)
echo "Starting Grafana from \$GRAFANA_DIR"
./bin/grafana-server
