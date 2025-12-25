
# Use official n8n image as base  
FROM n8nio/n8n:2.1.4

# --- Inherited from base image start ---
# Set work directory
# WORKDIR /home/node
# Expose n8n default port
# EXPOSE 5678
# Set persistent data volume (optional, for documentation)
# VOLUME ["/home/node/.n8n"]
# Default command
# CMD ["n8n"]
# --- Inherited from base image end---

# Install poppler-utils (for PDF processing)
# Note: Latest n8n image may not include package manager
USER root

# Try to install packages if apk is available, otherwise skip
RUN if command -v apk >/dev/null 2>&1; then \
        apk update && apk add --no-cache poppler-utils python3 py3-pip py3-pillow; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update && apt-get install -y poppler-utils python3 python3-pip python3-pil && rm -rf /var/lib/apt/lists/*; \
    else \
        echo "Warning: No package manager found. PDF processing packages not installed."; \
    fi

USER node
