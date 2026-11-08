#!/usr/bin/env bash

set -Eeuo pipefail
PROJECT_DIR="$HOME/linux-ops-toolkit"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/health_checks.log"

mkdir -p "$LOG_DIR"

log_message() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*" \
        >> "$LOG_FILE"
}

record_alert() {
    local severity="$1"
    shift
    local message="$*"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

    printf '[%s] [%s] %s\n' "$timestamp" "$severity" "$message" \
        | tee -a "$LOG_FILE"
}

check_service() {
    local service="$1"

    if systemctl is-active --quiet "$service"; then
        record_alert "OK" "Service '$service' is running."
    else
        record_alert "CRITICAL" "Service '$service' is not running."
    fi
}

get_cpu_usage() {
    local cpu_stats_1
    local cpu_stats_2

    cpu_stats_1=$(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8}' /proc/stat)

    sleep 1

    cpu_stats_2=$(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8}' /proc/stat)

    awk -v first="$cpu_stats_1" -v second="$cpu_stats_2" '
    BEGIN {
        split(first, a, " ")
        split(second, b, " ")

        for (i = 1; i <= 7; i++) {
            total1 += a[i]
            total2 += b[i]
        }

        idle1 = a[4] + a[5]
        idle2 = b[4] + b[5]

        total_diff = total2 - total1
        idle_diff = idle2 - idle1

        if (total_diff > 0) {
            printf "%.1f", (total_diff - idle_diff) / total_diff * 100
        } else {
            print 0
        }
    }'
}

handle_error() {
    local exit_code=$?
    local line_number="${BASH_LINENO[0]}"

    log_message "ERROR: Health check failed at line ${line_number} (exit code ${exit_code}, PID: $$)"

    exit "$exit_code"
}

trap handle_error ERR

log_message "Health check started (PID: $$)"

# Configurable warning thresholds
DISK_THRESHOLD=80
MEMORY_THRESHOLD=80
CPU_THRESHOLD=80

REPORT_DIR="$PROJECT_DIR/reports"

mkdir -p "$REPORT_DIR"

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="$REPORT_DIR/health_report_${TIMESTAMP}.txt"

# Collect system metrics
HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
LOAD_AVERAGE=$(awk '{print $1, $2, $3}' /proc/loadavg)
CPU_CORES=$(nproc)
CPU_USAGE=$(get_cpu_usage)

DISK_USAGE=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
MEMORY_USAGE=$(free | awk '/^Mem:/ {
    if ($2 > 0) {
        printf "%.0f", (($2 - $7) / $2) * 100
    } else {
        print 0
    }
}')

# Generate the report
{
    echo "======================================"
    echo "       LINUX SERVER HEALTH REPORT"
    echo "======================================"
    echo "Timestamp:     $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Hostname:      $HOSTNAME"
    echo "Uptime:        $UPTIME"
    echo "CPU cores:     $CPU_CORES"
    echo "CPU usage:     ${CPU_USAGE}%"
    echo "Load average:  $LOAD_AVERAGE"
    echo "Disk usage (/): ${DISK_USAGE}%"
    echo "Memory usage:   ${MEMORY_USAGE}%"
    echo
    echo "--------------- HEALTH STATUS ---------------"

    if (( DISK_USAGE >= DISK_THRESHOLD )); then
    record_alert "WARNING" "Disk usage is ${DISK_USAGE}%, threshold is ${DISK_THRESHOLD}%."
else
    record_alert "OK" "Disk usage is ${DISK_USAGE}%, below threshold."
fi

if (( MEMORY_USAGE >= MEMORY_THRESHOLD )); then
    record_alert "WARNING" "Memory usage is ${MEMORY_USAGE}%, threshold is ${MEMORY_THRESHOLD}%."
else
    record_alert "OK" "Memory usage is ${MEMORY_USAGE}%, below threshold."
fi

# CPU threshold check
if (( $(awk -v usage="$CPU_USAGE" -v threshold="$CPU_THRESHOLD" \
    'BEGIN {print (usage >= threshold)}') )); then
    record_alert "WARNING" "CPU usage is ${CPU_USAGE}%, threshold is ${CPU_THRESHOLD}%."
else
    record_alert "OK" "CPU usage is ${CPU_USAGE}%, below threshold."
fi

    echo
    echo "Top processes by CPU usage:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6

    echo
    echo "Report saved to: $REPORT_FILE"
    echo "======================================"
} | tee "$REPORT_FILE"

# Check critical system services
check_service "ssh"
check_service "cron"
log_message "Health check completed successfully. Report: $REPORT_FILE"
exit 0
