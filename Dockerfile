# Use official Python image
FROM python:3.11-slim

# Set work directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt ./
RUN pip install --upgrade pip && pip install -r requirements.txt

# Install Node.js 22.18.0, npm 11.5.2, and n8n
RUN apt-get update \
	&& apt-get install -y curl \
	&& curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
	&& apt-get install -y nodejs \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& npm install -g n \
	&& n 22.18.0 \
	&& npm install -g npm@11.5.2 \
	&& npm install -g n8n

# Copy project files
COPY . .

# Set environment variables (optional, for .env usage)
ENV PYTHONUNBUFFERED=1

# Default command
CMD ["n8n"]
