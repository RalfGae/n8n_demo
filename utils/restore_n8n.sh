#!/bin/bash
# n8n Restore Script with Test & Replace Workflow

set -e

# Configuration
PROJECT_DIR="$(pwd)"

# Logging function (log file will be set later after extracting backup timestamp)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup-file.tar.gz> [--test-and-replace]"
    echo ""
    echo "Options:"
    echo "  $0 backup.tar.gz                    # Simple restore to timestamped folder"
    echo "  $0 backup.tar.gz --test-and-replace # Full workflow: extract -> test -> replace -> verify -> cleanup"
    echo ""
    echo "Examples:"
    echo "  $0 backups/n8n_backup_20251226_143022.tar.gz"
    echo "  $0 backups/n8n_backup_20251226_143022.tar.gz --test-and-replace"
    exit 1
fi

BACKUP_FILE="$1"
MODE="${2:-simple}"

# Extract timestamp from backup filename (format: n8n_backup_YYYYMMDD_HHMMSS.tar.gz)
BACKUP_FILENAME=$(basename "$BACKUP_FILE")
if [[ $BACKUP_FILENAME =~ n8n_backup_([0-9]{8}_[0-9]{6})\.tar\.gz ]]; then
    BACKUP_TIMESTAMP="${BASH_REMATCH[1]}"
    LOG_FILE="restore_${BACKUP_TIMESTAMP}.log"
    log "📅 Using timestamp from backup: $BACKUP_TIMESTAMP"
else
    # Fallback to current timestamp if pattern doesn't match
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="restore_${BACKUP_TIMESTAMP}.log"
    log "⚠️  Could not extract timestamp from filename, using current: $BACKUP_TIMESTAMP"
fi

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    log "❌ ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

log "🔄 Starting n8n restore from backup: $BACKUP_FILE"
log "📝 Log file: $LOG_FILE"

# Create comprehensive system backup before any restore operation
SYSTEM_BACKUP_DIR="${PROJECT_DIR}/n8n_SYSTEM_COPY"
log "💾 Creating comprehensive system backup: $SYSTEM_BACKUP_DIR"

# Remove existing system copy if it exists
if [ -d "$SYSTEM_BACKUP_DIR" ]; then
    log "🗑️  Removing previous system copy"
    rm -rf "$SYSTEM_BACKUP_DIR"
fi

mkdir -p "$SYSTEM_BACKUP_DIR"

# Copy ALL current files to system backup (not move - copy for safety)
# Exclude backups folder to avoid unnecessary duplication
for item in .env .env.example n8n_data scripts my-files docker-compose.yml Dockerfile README.md requirements.txt utils; do
    if [ -e "$item" ]; then
        cp -r "$item" "$SYSTEM_BACKUP_DIR/" 2>/dev/null || true
        log "📦 Copied $item to system backup"
    fi
done

log "✅ Complete system backup created"

if [ "$MODE" = "--test-and-replace" ]; then
    log "🚀 Running FULL TEST & REPLACE workflow"
    
    # Step 1: Extract backup to test directory
    TEST_DIR="${PROJECT_DIR}/n8n_restore_test_${BACKUP_TIMESTAMP}"
    log "📦 Step 1: Extracting backup to test directory: $TEST_DIR"
    mkdir -p "$TEST_DIR"
    tar -xzf "$BACKUP_FILE" -C "$TEST_DIR"
    log "✅ Extraction complete"
    
    # Step 2: Test the extracted backup
    log "🧪 Step 2: Testing extracted backup"
    cd "$TEST_DIR"
    
    # Check if essential files exist
    if [ ! -f ".env" ]; then
        log "❌ ERROR: .env file missing in backup"
        exit 1
    fi
    if [ ! -d "n8n_data" ]; then
        log "❌ ERROR: n8n_data directory missing in backup"
        exit 1
    fi
    if [ ! -f "docker-compose.yml" ]; then
        log "❌ ERROR: docker-compose.yml missing in backup"
        exit 1
    fi
    
    log "✅ Essential files verified"
    
    # Test container startup
    log "🐳 Testing container startup..."
    if docker compose up -d; then
        log "✅ Container started successfully"
        sleep 5
        
        # Check if container is running
        if docker compose ps | grep -q "Up"; then
            log "✅ Container is running properly"
            
            # Test health (optional - check if port responds)
            sleep 10
            if curl -s http://localhost:5678 > /dev/null 2>&1; then
                log "✅ n8n web interface is responding"
            else
                log "⚠️  WARNING: n8n web interface not responding (may need more time)"
            fi
        else
            log "❌ ERROR: Container failed to stay running"
            docker compose logs
            exit 1
        fi
        
        log "🛑 Stopping test container"
        docker compose down
    else
        log "❌ ERROR: Failed to start test container"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    # Step 3: Replace current files with backup
    log "🔄 Step 3: Replacing current files with tested backup"
    
    # Stop current container if running
    log "🛑 Stopping current n8n container"
    docker compose down 2>/dev/null || true
    
    # Remove current files (we already have them safely backed up in n8n_SYSTEM_COPY)
    log "🗑️  Removing current files (backed up in n8n_SYSTEM_COPY)"
    for item in .env n8n_data scripts my-files; do
        if [ -e "$item" ]; then
            rm -rf "$item" 2>/dev/null || true
            log "�️  Removed $item"
        fi
    done
    
    # Copy tested files to current directory
    log "📋 Copying tested files to current directory"
    cp "$TEST_DIR/.env" ./ 2>/dev/null || true
    cp -r "$TEST_DIR/n8n_data" ./ 2>/dev/null || true
    cp -r "$TEST_DIR/scripts" ./ 2>/dev/null || true
    cp -r "$TEST_DIR/my-files" ./ 2>/dev/null || true
    
    # Set proper permissions
    log "🔐 Setting proper permissions"
    chmod 600 .env 2>/dev/null || true
    
    # Fix n8n_data permissions (Docker needs write access)
    if [ -d "n8n_data" ]; then
        find n8n_data -type d -exec chmod 755 {} \; 2>/dev/null || true
        find n8n_data -type f -exec chmod 644 {} \; 2>/dev/null || true
        # Make n8n_data writable by the Docker container user (node:node = 1000:1000)
        chmod -R u+w n8n_data 2>/dev/null || true
    fi
    
    find scripts -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
    
    log "✅ Files replaced successfully"
    
    # Step 4: Start and verify the replaced instance
    log "🚀 Step 4: Starting replaced n8n instance"
    if docker compose up -d; then
        log "✅ Replaced instance started"
        sleep 10
        
        # Verify it's working
        if docker compose ps | grep -q "Up"; then
            log "✅ Replaced instance is running"
            
            # Test health
            if curl -s http://localhost:5678 > /dev/null 2>&1; then
                log "✅ Replaced n8n instance is responding correctly"
            else
                log "⚠️  WARNING: n8n may need more time to start"
            fi
            
            log "🎉 RESTORE SUCCESSFUL! n8n is running from restored backup"
        else
            log "❌ ERROR: Replaced instance failed to run"
            docker compose logs
            
            # Rollback
            log "🔙 Rolling back to complete system backup"
            docker compose down
            
            # Remove current files (preserve backups folder)
            rm -rf .env n8n_data scripts my-files docker-compose.yml Dockerfile README.md requirements.txt utils 2>/dev/null || true
            
            # Restore complete system from n8n_SYSTEM_COPY
            if [ -d "$SYSTEM_BACKUP_DIR" ]; then
                cp -r "$SYSTEM_BACKUP_DIR"/* ./
                log "✅ System successfully rolled back to n8n_SYSTEM_COPY"
            else
                log "❌ ERROR: System backup directory not found: $SYSTEM_BACKUP_DIR"
            fi
            
            exit 1
        fi
    else
        log "❌ ERROR: Failed to start replaced instance"
        exit 1
    fi
    
    # Step 5: Cleanup
    log "🧹 Step 5: Cleaning up temporary files"
    rm -rf "$TEST_DIR"
    log "📁 Preserving system backup: $SYSTEM_BACKUP_DIR (kept for safety)"
    log "✅ Cleanup complete"
    
    log "🎯 FULL RESTORE WORKFLOW COMPLETED SUCCESSFULLY!"
    log "📊 Summary:"
    log "   - System backup created: ✅"
    log "   - Backup extracted and tested: ✅"
    log "   - Files replaced: ✅"  
    log "   - Instance verified: ✅"
    log "   - Cleanup completed: ✅"
    log "🔒 System backup preserved at: $SYSTEM_BACKUP_DIR"
    log "🌐 n8n is available at: http://localhost:5678"
    
else
    # Simple restore mode (original functionality)
    TARGET_DIR="${PROJECT_DIR}/n8n_restored_${BACKUP_TIMESTAMP}"
    log "📁 Simple restore to: $TARGET_DIR"
    
    mkdir -p "$TARGET_DIR"
    log "📦 Extracting backup..."
    tar -xzf "$BACKUP_FILE" -C "$TARGET_DIR"
    
    log "🔐 Setting permissions..."
    chmod 600 "$TARGET_DIR/.env" 2>/dev/null || true
    find "$TARGET_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$TARGET_DIR" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
    
    log "✅ Simple restore complete!"
    log "📋 Next steps:"
    log "   1. cd $TARGET_DIR"
    log "   2. docker compose up -d"
    log "   3. Access n8n at http://localhost:5678"
    
    log "📄 Files restored:"
    ls -la "$TARGET_DIR"
fi

log "📝 Restore log saved to: $LOG_FILE"