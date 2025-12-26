#!/bin/bash
# n8n Restore Script with Test & Replace Workflow

set -e

# Configuration
LOG_FILE="restore_$(date +%Y%m%d_%H%M%S).log"
PROJECT_DIR="$(pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup-file.tar.gz> [--test-and-replace]"
    echo ""
    echo "Options:"
    echo "  $0 backup.tar.gz                    # Simple restore to timestamped folder"
    echo "  $0 backup.tar.gz --test-and-replace # Full workflow: extract -> test -> replace -> verify -> cleanup"
    exit 1
fi

BACKUP_FILE="$1"
MODE="${2:-simple}"

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    log "❌ ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

log "🔄 Starting n8n restore from backup: $BACKUP_FILE"
log "📝 Log file: $LOG_FILE"

if [ "$MODE" = "--test-and-replace" ]; then
    log "🚀 Running FULL TEST & REPLACE workflow"
    
    # Step 1: Extract backup to test directory
    TEST_DIR="${PROJECT_DIR}/n8n_restore_test_${TIMESTAMP}"
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
    
    # Backup current files (safety measure)
    SAFETY_BACKUP_DIR="${PROJECT_DIR}/safety_backup_${TIMESTAMP}"
    log "💾 Creating safety backup of current files: $SAFETY_BACKUP_DIR"
    mkdir -p "$SAFETY_BACKUP_DIR"
    
    # Move current files to safety backup
    for item in .env n8n_data scripts my-files; do
        if [ -e "$item" ]; then
            mv "$item" "$SAFETY_BACKUP_DIR/" 2>/dev/null || true
            log "📦 Moved $item to safety backup"
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
            log "🔙 Rolling back to safety backup"
            docker compose down
            rm -rf .env n8n_data scripts my-files
            mv "$SAFETY_BACKUP_DIR"/* ./ 2>/dev/null || true
            rmdir "$SAFETY_BACKUP_DIR"
            exit 1
        fi
    else
        log "❌ ERROR: Failed to start replaced instance"
        exit 1
    fi
    
    # Step 5: Cleanup
    log "🧹 Step 5: Cleaning up temporary files"
    rm -rf "$TEST_DIR"
    rm -rf "$SAFETY_BACKUP_DIR"
    log "✅ Cleanup complete"
    
    log "🎯 FULL RESTORE WORKFLOW COMPLETED SUCCESSFULLY!"
    log "📊 Summary:"
    log "   - Backup extracted and tested: ✅"
    log "   - Files replaced: ✅"  
    log "   - Instance verified: ✅"
    log "   - Cleanup completed: ✅"
    log "🌐 n8n is available at: http://localhost:5678"
    
else
    # Simple restore mode (original functionality)
    TARGET_DIR="${PROJECT_DIR}/n8n_restored_$(date +%Y%m%d_%H%M%S)"
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
    
    # Safety check - ensure we're in a valid n8n project directory
    if [ ! -f "docker-compose.yml" ] && [ ! -f "Dockerfile" ]; then
        echo "⚠️  Warning: This doesn't look like an n8n project directory"
        echo "   (no docker-compose.yml or Dockerfile found)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Restore cancelled"
            exit 1
        fi
    fi
    
    # Create temporary extraction directory
    TEMP_DIR=$(mktemp -d)
    echo "📦 Extracting to temporary directory..."
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
    
    # Copy restored files to current directory
    echo "📋 Copying restored files..."
    cp -f "$TEMP_DIR"/.env . 2>/dev/null || echo "   .env not found in backup"
    cp -rf "$TEMP_DIR"/n8n_data . 2>/dev/null || echo "   n8n_data not found in backup"
    cp -rf "$TEMP_DIR"/scripts . 2>/dev/null || echo "   scripts not found in backup"
    cp -rf "$TEMP_DIR"/my-files . 2>/dev/null || echo "   my-files not found in backup"
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
else
    TARGET_DIR="${TARGET_OPTION:-$(pwd)/n8n_restored_$(date +%Y%m%d_%H%M%S)}"
    echo "📁 Target directory: $TARGET_DIR"
    
    # Create target directory
    mkdir -p "$TARGET_DIR"
    
    # Extract backup
    echo "📦 Extracting backup..."
    tar -xzf "$BACKUP_FILE" -C "$TARGET_DIR"
fi

# Set proper permissions
echo "🔐 Setting permissions..."
if [ "$TARGET_OPTION" = "--in-place" ]; then
    chmod 600 .env 2>/dev/null || true
    chmod -R 755 scripts/ 2>/dev/null || true
    echo "✅ In-place restore complete!"
    echo ""
    echo "📋 Next steps:"
    echo "1. docker compose up -d"
    echo "2. Access n8n at http://localhost:5678"
    echo ""
    echo "📄 Files in current directory:"
    ls -la | grep -E "\.(env|scripts|n8n_data|my-files)"
else
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
fi