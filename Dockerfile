
# Use official n8n image as base
FROM n8nio/n8n:latest

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
USER root
RUN apk add --no-cache poppler-utils
USER node
