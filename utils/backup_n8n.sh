#!/bin/bash
# n8n Backup Script with Cloud Upload Support

set -e

# Configuration
PROJECT_DIR="/home/rglinux/prj/n8n_demo"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="n8n_backup_${TIMESTAMP}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "🔄 Creating n8n backup: $BACKUP_NAME"

# Stop n8n container to ensure data consistency
echo "⏸️  Stopping n8n container..."
cd "$PROJECT_DIR"
docker compose down

# Create comprehensive backup
echo "📦 Creating backup archive..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" \
    -C "$PROJECT_DIR" \
    n8n_data/ \
    my-files/ \
    scripts/ \
    .env \
    docker-compose.yml \
    Dockerfile \
    requirements.txt \
    README.md

# Restart n8n
echo "▶️  Restarting n8n container..."
docker compose up -d

# Backup size info
BACKUP_SIZE=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)
echo "✅ Backup created: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"

# Upload options (uncomment as needed)

# Option A: Upload to Google Drive (requires rclone)
# echo "☁️  Uploading to Google Drive..."
# rclone copy "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" gdrive:n8n-backups/

# Option B: Upload to Dropbox (requires rclone)
# echo "☁️  Uploading to Dropbox..."
# rclone copy "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" dropbox:n8n-backups/

# Option C: Upload via SCP to remote server
# echo "☁️  Uploading to remote server..."
# scp "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" user@server:/path/to/backups/

# Option D: AWS S3 upload (requires aws-cli)
# echo "☁️  Uploading to AWS S3..."
# aws s3 cp "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" s3://your-bucket/n8n-backups/

# Cleanup old local backups (keep last 5)
echo "🧹 Cleaning up old local backups..."
ls -t "$BACKUP_DIR"/n8n_backup_*.tar.gz | tail -n +6 | xargs -r rm

echo "🎉 Backup complete: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"

# Create backup completion notification for n8n workflows
LOGS_DIR="$PROJECT_DIR/logs"
if [ -d "$LOGS_DIR" ]; then
    cat > "$LOGS_DIR/backup_completed_${TIMESTAMP}.log" << EOF
=== BACKUP COMPLETION NOTIFICATION ===
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Backup File: ${BACKUP_NAME}.tar.gz
Backup Size: ${BACKUP_SIZE}
Backup Location: $BACKUP_DIR/${BACKUP_NAME}.tar.gz
Status: SUCCESS

=== BACKUP CONTENTS ===
$(tar -tzf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | head -20)
$([ "$(tar -tzf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | wc -l)" -gt 20 ] && echo "... and $(($(tar -tzf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | wc -l) - 20)) more files")

=== SYSTEM INFO ===
Host: $(hostname)
Available Space: $(df -h "$BACKUP_DIR" | tail -1 | awk '{print "Used: " $3 " Available: " $4 " (" $5 " full)"}')
Total Backups: $(ls -1 "$BACKUP_DIR"/n8n_backup_*.tar.gz 2>/dev/null | wc -l)

=== END NOTIFICATION ===
EOF
    echo "📧 Backup notification created for n8n workflows"
fi