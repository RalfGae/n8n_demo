#!/bin/bash
# System Startup Notification Script

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_DIR="/home/rglinux/prj/n8n_demo/logs"

# Create startup notification file
cat > "$LOG_DIR/system_startup_$(date +%Y%m%d_%H%M%S).log" << EOF
=== SYSTEM STARTUP NOTIFICATION ===
Timestamp: $TIMESTAMP
Host: $(hostname)
n8n Container Status: $(docker ps --filter "name=my-n8n" --format "{{.Status}}")
n8n URL: http://localhost:5678
System Load: $(uptime)

=== DOCKER CONTAINER LOGS (Last 10 lines) ===
$(docker compose -f /home/rglinux/prj/n8n_demo/docker-compose.yml logs --tail=10 n8n 2>/dev/null)

=== END NOTIFICATION ===
EOF

echo "✅ Startup notification created in $LOG_DIR"