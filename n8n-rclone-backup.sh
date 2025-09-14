#!/bin/bash
#
# n8n Google Drive Backup & Restore Script (using rclone)
# Store this inside your n8n-github-sync repo as: n8n-rclone-backup.sh
#
# Requirements:
#   - rclone installed and configured (`rclone config`)
#   - a remote called "gdrive" (can be renamed in config below)
#
# Usage:
#   ./n8n-rclone-backup.sh backup   -> push latest n8n data to Google Drive
#   ./n8n-rclone-backup.sh restore  -> restore latest backup from Google Drive

### CONFIGURATION ###
# Adjust these paths/names as needed
#!/bin/bash
#
# n8n-rclone-backup.sh
# Backup and restore n8n Docker volume using rclone + Google Drive (or other remotes)
#

# === CONFIG ===
VOLUME_NAME="n8n_data"                                        # Docker volume name
DATA_PATH="/var/lib/docker/volumes/${VOLUME_NAME}/_data"      # Path inside server
REMOTE="gdrive:n8n-backups"                                   # rclone remote:path
RCLONE_CONF="/home/ubuntu/.config/rclone/rclone.conf"         # Force use ubuntu’s config

# === ENSURE ROOT ===
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Script requires root. Re-running with sudo..."
    exec sudo RCLONE_CONFIG="$RCLONE_CONF" "$0" "$@"
fi

# Always set config path (even under root)
export RCLONE_CONFIG="$RCLONE_CONF"

# === FUNCTIONS ===

backup() {
    echo ">>> Starting n8n backup..."

    if [ ! -d "$DATA_PATH" ]; then
        echo "❌ Error: n8n data directory not found at $DATA_PATH"
        exit 1
    fi

    rclone sync "$DATA_PATH" "$REMOTE/latest" --delete-during --progress
    if [ $? -eq 0 ]; then
        echo "✅ Backup completed successfully."
    else
        echo "❌ Backup failed!"
        exit 1
    fi
}

restore() {
    echo ">>> Restoring n8n data from backup..."

    if [ ! -d "$DATA_PATH" ]; then
        echo "❌ Error: n8n data directory not found at $DATA_PATH"
        exit 1
    fi

    rclone sync "$REMOTE/latest" "$DATA_PATH" --delete-during --progress
    if [ $? -eq 0 ]; then
        echo "✅ Restore completed successfully."
    else
        echo "❌ Restore failed!"
        exit 1
    fi
}

# === MAIN ===
case "$1" in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
        ;;
esac
