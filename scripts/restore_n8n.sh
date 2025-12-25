#!/bin/bash
# n8n Restore Script

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup-file.tar.gz> [target-directory]"
    echo "Example: $0 n8n-backup-20251225-160000.tar.gz /home/user/n8n_restored"
    exit 1
fi

BACKUP_FILE="$1"
TARGET_DIR="${2:-$(pwd)/n8n_restored_$(date +%Y%m%d_%H%M%S)}"

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "🔄 Restoring n8n from backup: $BACKUP_FILE"
echo "📁 Target directory: $TARGET_DIR"

# Create target directory
mkdir -p "$TARGET_DIR"

# Extract backup
echo "📦 Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TARGET_DIR"

# Set proper permissions
echo "🔐 Setting permissions..."
chmod 600 "$TARGET_DIR"/.env 2>/dev/null || true
chmod -R 755 "$TARGET_DIR"/scripts/ 2>/dev/null || true

echo "✅ Restore complete!"
echo ""
echo "📋 Next steps:"
echo "1. cd $TARGET_DIR"
echo "2. docker compose up -d"
echo "3. Access n8n at http://localhost:5678"
echo ""
echo "📄 Files restored:"
ls -la "$TARGET_DIR"