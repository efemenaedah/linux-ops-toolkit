#!/usr/bin/env bash

set -Eeuo pipefail

# Project configuration
PROJECT_DIR="$HOME/linux-ops-toolkit"
BACKUP_DIR="$HOME/backups/linux-ops-toolkit"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"

# Create required directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Generate timestamp
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

BACKUP_FILE="$BACKUP_DIR/linux-ops-toolkit_${TIMESTAMP}.tar.gz"

# Logging function
log_message() {
    printf '[%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*" \
        >> "$LOG_FILE"
}

log_message "Backup started (PID: $$)"

# Create compressed archive
if tar -czf "$BACKUP_FILE" \
    --exclude='.git' \
    -C "$PROJECT_DIR" .; then

    log_message "Backup archive created: $BACKUP_FILE"

else
    log_message "ERROR: Backup creation failed."
    exit 1
fi

# Verify archive integrity
if tar -tzf "$BACKUP_FILE" > /dev/null; then

    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')

    log_message "Backup verification successful."
    log_message "Backup size: $BACKUP_SIZE"
    log_message "Backup completed successfully."

    echo "Backup completed successfully!"
    echo "Location: $BACKUP_FILE"
    echo "Size: $BACKUP_SIZE"

else
    log_message "ERROR: Backup verification failed."
    exit 1
fi

# Backup retention: keep the 7 most recent archives

mapfile -t OLD_BACKUPS < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'linux-ops-toolkit_*.tar.gz' \
        -printf '%f\n' | sort -r | tail -n +8
)

for old_backup in "${OLD_BACKUPS[@]}"; do
    rm -- "$BACKUP_DIR/$old_backup"
    log_message "Old backup removed: $old_backup"
done

log_message "Backup retention policy completed."
