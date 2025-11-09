# End-to-End Monitoring Setup: Prometheus + Grafana + PagerDuty

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)
[![PagerDuty](https://img.shields.io/badge/PagerDuty-06AC38?style=flat&logo=pagerduty&logoColor=white)](https://www.pagerduty.com/)

A production-ready monitoring stack that provides real-time metrics collection, visualization, and intelligent alerting. This setup helps you detect and respond to issues before they impact your users.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Creating Dashboards](#creating-dashboards)
- [Setting Up Alerts](#setting-up-alerts)
- [Troubleshooting](#troubleshooting)
- [Production Considerations](#production-considerations)
- [Contributing](#contributing)

## 🎯 Overview

This repository provides a complete monitoring solution using industry-standard tools:

- **Prometheus**: Time-series database for metrics collection and storage
- **Grafana**: Visualization platform for creating interactive dashboards
- **PagerDuty**: Incident management and alerting system
- **Node Exporter**: System metrics exporter for Linux/Unix systems

**What You'll Get:**
- Real-time system monitoring (CPU, Memory, Disk, Network)
- Custom dashboards with meaningful visualizations
- Automated alerts for critical issues
- Integration with on-call rotation via PagerDuty

## 🏗️ Architecture

```
┌─────────────┐
│   Servers   │
│  (Targets)  │
└──────┬──────┘
       │ Metrics
       ↓
┌─────────────┐      ┌─────────────┐
│ Prometheus  │◄─────┤   Grafana   │
│  (Storage)  │      │(Dashboards) │
└──────┬──────┘      └──────┬──────┘
       │                    │
       │ Alerts             │ Alerts
       ↓                    ↓
┌─────────────────────────────┐
│        PagerDuty            │
│   (Incident Management)     │
└─────────────────────────────┘
```

## ✅ Prerequisites

### System Requirements
- **OS**: Linux (Ubuntu 20.04+, CentOS 7+, or similar)
- **RAM**: Minimum 2GB (4GB recommended)
- **CPU**: 2 cores minimum
- **Disk**: 20GB free space
- **Ports**: 9090 (Prometheus), 3000 (Grafana), 9100 (Node Exporter)

### Required Knowledge
- Basic Linux command line
- Understanding of systemd services
- Familiarity with YAML configuration
- Basic networking concepts

### Tools & Access
- `wget` or `curl` installed
- `tar` for extracting archives
- `sudo` access on the system
- PagerDuty account (free tier available)
- Web browser for accessing Grafana

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/ibraheemcisse/End-to-End-Monitoring-Setup-Prometheus-Grafana-and-PagerDuty.git
cd End-to-End-Monitoring-Setup-Prometheus-Grafana-and-PagerDuty

# Run the setup script (if available)
# Or follow the detailed setup below
```

## 📦 Detailed Setup

### Step 1: Install Node Exporter

Node Exporter collects system metrics from your servers.

```bash
# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
cd node_exporter-1.7.0.linux-amd64/

# Move binary to system path
sudo mv node_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Create user and start service
sudo useradd -rs /bin/false node_exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Verify it's running
curl http://localhost:9100/metrics
```

### Step 2: Install Prometheus

```bash
# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz
tar xvfz prometheus-2.48.0.linux-amd64.tar.gz
cd prometheus-2.48.0.linux-amd64/

# Create directories
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

# Move files
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/

# Create user
sudo useradd -rs /bin/false prometheus

# Set ownership
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus
```

### Step 3: Configure Prometheus

Edit `/etc/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alertmanager configuration (optional)
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them
rule_files:
  - "alert_rules.yml"

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter - System metrics
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'server-1'
```

Create systemd service for Prometheus:

```bash
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Check status
sudo systemctl status prometheus

# Access Prometheus UI
# Open browser: http://your-server-ip:9090
```

### Step 4: Install Grafana

```bash
# Add Grafana repository (Ubuntu/Debian)
sudo apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt-get update
sudo apt-get install grafana

# Start Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Check status
sudo systemctl status grafana-server

# Access Grafana UI
# Open browser: http://your-server-ip:3000
# Default credentials: admin/admin
```

**For CentOS/RHEL:**

```bash
# Create Grafana repo
sudo tee /etc/yum.repos.d/grafana.repo > /dev/null <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

# Install
sudo yum install grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

### Step 5: Configure Grafana with Prometheus

1. **Access Grafana**: Navigate to `http://your-server-ip:3000`
2. **Login**: Use `admin/admin` (you'll be prompted to change password)
3. **Add Data Source**:
   - Click on "Configuration" (gear icon) → "Data Sources"
   - Click "Add data source"
   - Select "Prometheus"
   - Set URL: `http://localhost:9090`
   - Click "Save & Test"

## 📊 Creating Dashboards

### Import Pre-built Dashboards

Grafana has thousands of community dashboards:

1. Click "+" → "Import"
2. Enter dashboard ID or upload JSON
3. Popular Dashboard IDs:
   - **1860**: Node Exporter Full (comprehensive system metrics)
   - **11074**: Node Exporter for Prometheus Dashboard
   - **405**: Node Exporter Server Metrics

### Create Custom Dashboard

**Example: CPU Usage Panel**

1. Click "+" → "Dashboard" → "Add new panel"
2. In the query editor, enter:
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
3. Configure panel:
   - Title: "CPU Usage %"
   - Unit: "Percent (0-100)"
   - Set thresholds: Warning at 70%, Critical at 90%

**Example: Memory Usage Panel**

```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Example: Disk Usage Panel**

```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!="rootfs"} * 100) / node_filesystem_size_bytes{mountpoint="/",fstype!="rootfs"})
```

**Example: Network Traffic**

```promql
# Incoming
rate(node_network_receive_bytes_total[5m])

# Outgoing
rate(node_network_transmit_bytes_total[5m])
```

## 🚨 Setting Up Alerts

### Step 1: Configure PagerDuty

1. **Create PagerDuty Account**: Sign up at [pagerduty.com](https://www.pagerduty.com)
2. **Create a Service**:
   - Go to "Services" → "New Service"
   - Name: "Production Monitoring"
   - Integration Type: "Grafana"
   - Copy the Integration Key

### Step 2: Configure Grafana Alerting

1. **Add PagerDuty Contact Point**:
   - Go to "Alerting" → "Contact points" → "New contact point"
   - Name: "PagerDuty Production"
   - Integration: "PagerDuty"
   - Paste your Integration Key
   - Click "Test" then "Save"

### Step 3: Create Alert Rules

**Example: High CPU Alert**

1. Edit your CPU Usage panel
2. Switch to "Alert" tab
3. Create alert rule:

```yaml
Name: High CPU Usage
Condition: WHEN avg() OF query(A, 5m, now) IS ABOVE 80

# Alert details
Summary: CPU usage is above 80% on {{ $labels.instance }}
Description: Current CPU usage: {{ $values.A }}%
```

**Example: Low Disk Space Alert**

```yaml
Name: Low Disk Space
Condition: WHEN last() OF query(A, 5m, now) IS ABOVE 85

Summary: Disk usage is above 85% on {{ $labels.instance }}
Description: Current disk usage: {{ $values.A }}% on {{ $labels.mountpoint }}
```

**Example: High Memory Alert**

```yaml
Name: High Memory Usage
Condition: WHEN avg() OF query(A, 5m, now) IS ABOVE 85

Summary: Memory usage is above 85% on {{ $labels.instance }}
Description: Current memory usage: {{ $values.A }}%
```

### Step 4: Create Notification Policy

1. Go to "Alerting" → "Notification policies"
2. Edit the default policy or create new one
3. Set contact point to "PagerDuty Production"
4. Configure grouping and timing:
   - Group by: `alertname, instance`
   - Group wait: 30s
   - Group interval: 5m
   - Repeat interval: 4h

## 🔧 Troubleshooting

### Prometheus Issues

**Problem: Prometheus not scraping targets**

```bash
# Check Prometheus logs
sudo journalctl -u prometheus -f

# Check targets status
# Go to http://your-server-ip:9090/targets

# Verify firewall allows connections
sudo firewall-cmd --list-all
sudo ufw status

# Test connectivity
curl http://localhost:9100/metrics
```

**Problem: "Permission denied" errors**

```bash
# Fix ownership
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Check service status
sudo systemctl status prometheus
```

### Grafana Issues

**Problem: Can't access Grafana UI**

```bash
# Check if Grafana is running
sudo systemctl status grafana-server

# Check logs
sudo journalctl -u grafana-server -f

# Verify port 3000 is listening
sudo netstat -tlnp | grep 3000

# Check firewall
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
```

**Problem: Prometheus data source not working**

- Verify Prometheus URL is correct: `http://localhost:9090`
- Check if Prometheus is running: `sudo systemctl status prometheus`
- Test from command line: `curl http://localhost:9090/api/v1/query?query=up`

### Alert Issues

**Problem: Alerts not triggering**

```bash
# Check alert rules in Prometheus UI
# Go to http://your-server-ip:9090/alerts

# Verify rule file syntax
promtool check rules /etc/prometheus/alert_rules.yml

# Check Grafana alert state
# Go to Grafana → Alerting → Alert rules
```

**Problem: PagerDuty not receiving alerts**

- Verify Integration Key is correct
- Test contact point in Grafana
- Check PagerDuty service status
- Review Grafana notification logs: `sudo journalctl -u grafana-server | grep -i pagerduty`

### Common Query Issues

**Problem: Query returns no data**

```bash
# Check if metrics are being collected
curl http://localhost:9090/api/v1/label/__name__/values | grep node_

# Verify time range in Grafana
# Check if instance label matches in query

# Test query directly in Prometheus
# Go to http://your-server-ip:9090/graph
```

## 🏭 Production Considerations

### Security

**1. Enable Authentication**

```bash
# Create password hash for Prometheus
htpasswd -nB admin > /etc/prometheus/web.yml

# Update Prometheus service
--web.config.file=/etc/prometheus/web.yml
```

**2. Use HTTPS**

```bash
# Generate SSL certificates (Let's Encrypt recommended)
sudo certbot certonly --standalone -d monitoring.yourdomain.com

# Configure Grafana for HTTPS
sudo vi /etc/grafana/grafana.ini

[server]
protocol = https
cert_file = /etc/letsencrypt/live/monitoring.yourdomain.com/fullchain.pem
cert_key = /etc/letsencrypt/live/monitoring.yourdomain.com/privkey.pem
```

**3. Firewall Configuration**

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus (optional, internal only)
sudo ufw enable
```

### High Availability

**Prometheus:**
- Use Prometheus federation for multiple instances
- Implement Thanos for long-term storage
- Set up remote storage (Cortex, M3DB, etc.)

**Grafana:**
- Use MySQL/PostgreSQL instead of SQLite
- Deploy multiple Grafana instances behind load balancer
- Store dashboards in Git for version control

### Performance Tuning

**Prometheus Storage:**

```yaml
# In prometheus.yml
storage:
  tsdb:
    retention.time: 15d        # Keep data for 15 days
    retention.size: 50GB       # Or until 50GB
```

**Scrape Intervals:**

```yaml
# Balance between data granularity and resource usage
global:
  scrape_interval: 30s         # Default for most metrics
  
scrape_configs:
  - job_name: 'high-frequency'
    scrape_interval: 10s       # For critical metrics
```

### Backup and Recovery

**Backup Prometheus Data:**

```bash
# Create backup script
#!/bin/bash
BACKUP_DIR="/backup/prometheus"
PROM_DATA="/var/lib/prometheus"
DATE=$(date +%Y%m%d)

tar -czf ${BACKUP_DIR}/prometheus-${DATE}.tar.gz ${PROM_DATA}

# Keep only last 7 days
find ${BACKUP_DIR} -name "prometheus-*.tar.gz" -mtime +7 -delete
```

**Backup Grafana:**

```bash
# Backup Grafana database and config
#!/bin/bash
BACKUP_DIR="/backup/grafana"
DATE=$(date +%Y%m%d)

# Backup database
cp /var/lib/grafana/grafana.db ${BACKUP_DIR}/grafana-${DATE}.db

# Backup configuration
cp /etc/grafana/grafana.ini ${BACKUP_DIR}/grafana-${DATE}.ini

# Export dashboards via API
curl -u admin:password http://localhost:3000/api/search | \
  jq -r '.[] | .uri' | \
  xargs -I {} curl -u admin:password http://localhost:3000/api/dashboards/{} > \
  ${BACKUP_DIR}/dashboards-${DATE}.json
```

### Monitoring the Monitors

Set up basic health checks:

```bash
# Simple health check script
#!/bin/bash

# Check Prometheus
if ! curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo "Prometheus is down!"
    # Send alert
fi

# Check Grafana
if ! curl -s http://localhost:3000/api/health > /dev/null; then
    echo "Grafana is down!"
    # Send alert
fi
```

## 📚 Useful Resources

### Official Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PagerDuty Documentation](https://support.pagerduty.com/)
- [Node Exporter Guide](https://github.com/prometheus/node_exporter)

### Community Resources
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### Learning Resources
- [Prometheus Training](https://training.promlabs.com/)
- [Grafana Tutorials](https://grafana.com/tutorials/)
- [SRE Book (Google)](https://sre.google/books/)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes and test thoroughly
4. Commit with clear messages: `git commit -m "Add: feature description"`
5. Push to your fork: `git push origin feature/your-feature`
6. Open a Pull Request with detailed description

### What to Contribute
- Additional exporters (MySQL, PostgreSQL, Redis, etc.)
- Pre-configured dashboards
- Alert rule templates
- Automation scripts
- Documentation improvements
- Bug fixes

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- The Prometheus and Grafana communities for amazing tools
- PagerDuty for incident management platform
- All contributors who help improve this project

## 📧 Support

- **Issues**: Open a [GitHub Issue](https://github.com/ibraheemcisse/End-to-End-Monitoring-Setup-Prometheus-Grafana-and-PagerDuty/issues)
- **Discussions**: Use [GitHub Discussions](https://github.com/ibraheemcisse/End-to-End-Monitoring-Setup-Prometheus-Grafana-and-PagerDuty/discussions)
- **Email**: Contact repository maintainer

---

**Built with ❤️ for the SRE community**

⭐ If this project helped you, please star the repository!
