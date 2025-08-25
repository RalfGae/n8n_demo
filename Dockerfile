
# Use official Node.js image
FROM node:22.18.0-slim

# Set work directory
WORKDIR /data

# Install npm 11.5.2 and n8n
RUN npm install -g npm@11.5.2 \
	&& npm install -g n8n

# Expose n8n default port
EXPOSE 5678

# Set persistent data volume (optional, for documentation)
VOLUME ["/home/node/.n8n"]

# Default command
CMD ["n8n"]
