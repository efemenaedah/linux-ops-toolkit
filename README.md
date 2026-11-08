# Linux Operations Toolkit

A hands-on Linux system administration and Bash automation
project built on Ubuntu Server.

This toolkit automates routine Linux operational tasks,
monitors system resource utilization, detects service failures,
generates health reports, and manages scheduled backups.

## Project Objectives

The project demonstrates practical Linux administration,
Bash scripting, monitoring, troubleshooting, logging,
backup management, and operational automation.

## Implemented Features

### 1. System Health Monitoring

- CPU utilization monitoring using /proc/stat.
- Memory utilization monitoring.
- Disk usage monitoring.
- System load average and uptime reporting.
- Configurable resource warning thresholds.
- Identification of top CPU-consuming processes.

### 2. Service Monitoring and Alerting

- SSH service availability checks.
- Cron service availability checks.
- OK, WARNING, and CRITICAL alert levels.
- Timestamped operational event logging.
- Detection of service failures.

### 3. Logging and Reporting

- Centralized health-check logging.
- Timestamped health reports.
- Log rotation using logrotate.
- Error handling and failure logging.

### 4. Backup Automation

- Automated project backups using tar.
- Compressed backup archives.
- Backup archive integrity verification.
- Seven-backup retention policy.
- Restoration testing.

### 5. Scheduled Automation

- Health checks scheduled through cron.
- Daily automated backups.
- Separate output logs for scheduled tasks.

## Technology Stack

- Ubuntu Server
- Bash
- Linux
- Git and GitHub
- Cron
- systemd
- logrotate
- tar
- awk

## Repository Structure

```text
linux-ops-toolkit/
├── scripts/
│   ├── health_checks.sh
│   └── backup.sh
├── tests/
│   └── test_error_logging.sh
├── config/
│   └── logrotate/
├── logs/
├── reports/
├── docs/
├── .gitignore
├── LICENSE
└── README.md
