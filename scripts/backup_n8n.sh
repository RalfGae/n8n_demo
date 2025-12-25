#!/bin/bash
# n8n Backup Script with Cloud Upload Support

set -e

# Configuration
BACKUP_DIR="/tmp/n8n-backups"
PROJECT_DIR="/home/rglinux/prj/n8n_demo"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="n8n-backup-${TIMESTAMP}"

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
ls -t "$BACKUP_DIR"/n8n-backup-*.tar.gz | tail -n +6 | xargs -r rm

echo "🎉 Backup complete: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"