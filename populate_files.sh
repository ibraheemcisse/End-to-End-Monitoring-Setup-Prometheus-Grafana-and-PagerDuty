#!/bin/bash
# This script populates the project files with sample content.

# --- Root files ---

# Create README.md
cat << 'EOF' > README.md
# End-to-End Monitoring Setup: Prometheus, Grafana, and PagerDuty

This repository contains configuration files, scripts, and documentation for setting up a complete monitoring solution using Prometheus for metrics collection, Grafana for visualization, and PagerDuty for alerting.

## Overview

- **Prometheus:** Metrics collection and time-series data storage.
- **Grafana:** Custom dashboards for visualizing CPU, memory, and disk usage.
- **PagerDuty:** Incident alerting and management.

Please refer to the documentation for detailed setup instructions.
EOF

# Create LICENSE (sample MIT License)
cat << 'EOF' > LICENSE
MIT License

Copyright (c) $(date +%Y) [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
...
EOF

# Create .gitignore
cat << 'EOF' > .gitignore
# Node modules, if applicable
node_modules/

# Logs
*.log

# Temporary files
*.tmp
*.swp

.DS_Store
Thumbs.db
EOF

# --- Prometheus files ---

# prometheus.yml
cat << 'EOF' > prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# setup.sh for Prometheus
cat << 'EOF' > prometheus/setup.sh
#!/bin/bash
# Prometheus setup script
PROMETHEUS_DIR=\$(pwd)
echo "Starting Prometheus from \$PROMETHEUS_DIR"
./prometheus --config.file=\$PROMETHEUS_DIR/prometheus.yml --storage.tsdb.path=\$PROMETHEUS_DIR/data
EOF
chmod +x prometheus/setup.sh

# --- Grafana files ---

# setup.sh for Grafana
cat << 'EOF' > grafana/setup.sh
#!/bin/bash
# Grafana setup script
GRAFANA_DIR=\$(pwd)
echo "Starting Grafana from \$GRAFANA_DIR"
./bin/grafana-server
EOF
chmod +x grafana/setup.sh

# Dashboard for CPU Usage
cat << 'EOF' > grafana/dashboards/cpu-usage.json
{
  "title": "CPU Usage",
  "panels": [
    {
      "type": "graph",
      "targets": [
        {
          "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
        }
      ]
    }
  ]
}
EOF

# Dashboard for Memory Usage
cat << 'EOF' > grafana/dashboards/memory-usage.json
{
  "title": "Memory Usage",
  "panels": [
    {
      "type": "graph",
      "targets": [
        {
          "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
        }
      ]
    }
  ]
}
EOF

# Dashboard for Disk Usage
cat << 'EOF' > grafana/dashboards/disk-usage.json
{
  "title": "Disk Usage",
  "panels": [
    {
      "type": "graph",
      "targets": [
        {
          "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}) * 100)"
        }
      ]
    }
  ]
}
EOF

# --- PagerDuty file ---

# Integration guide for PagerDuty
cat << 'EOF' > pagerduty/integration-guide.md
# PagerDuty Integration Guide

1. Log in to PagerDuty.
2. Create a new service with Events API v2.
3. Obtain the Integration Key from the service's configuration.
4. Use this Integration Key in Grafana's PagerDuty notification channel.

Refer to the documentation for detailed steps.
EOF

# --- Documentation files ---

# Setup guide
cat << 'EOF' > docs/setup-guide.md
# Setup Guide

This guide explains how to install and configure Prometheus, Grafana, and PagerDuty.

## Prometheus Setup
- Install Prometheus.
- Edit \`prometheus/prometheus.yml\` as needed.
- Run \`prometheus/setup.sh\` to start Prometheus.

## Grafana Setup
- Install Grafana.
- Import dashboards from the \`grafana/dashboards/\` directory.
- Run \`grafana/setup.sh\` to start Grafana.

## PagerDuty Integration
- Follow the steps in \`pagerduty/integration-guide.md\` to configure PagerDuty alerts.
EOF

# Troubleshooting guide
cat << 'EOF' > docs/troubleshooting.md
# Troubleshooting

## Common Issues

- **Prometheus Startup Issues:** Verify \`prometheus.yml\` configuration and file permissions.
- **Grafana Dashboard Errors:** Ensure Prometheus is running at http://localhost:9090 and data source is correctly set up.
- **PagerDuty Alerts Not Firing:** Confirm that the PagerDuty Integration Key is correctly set in Grafana.

For more details, consult the official documentation of each tool.
EOF

echo "All files populated successfully."

