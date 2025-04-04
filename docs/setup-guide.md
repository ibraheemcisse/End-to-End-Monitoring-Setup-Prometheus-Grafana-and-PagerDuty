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
