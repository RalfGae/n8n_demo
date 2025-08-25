## Version Control Best Practices

This project includes a `.gitignore` file to prevent committing sensitive or unnecessary files (such as `.env`, Python cache files, and editor settings) to your repository. Always check that your `.env` and other local files are excluded from version control.

# Quick AI Project Starter (Docker & n8n Edition)

This repository provides n8n (workflow automation) installed in a Docker container for easy setup and reproducibility.

## Features
- Workflow automation with n8n
- Zero local setup required—just use Docker

## Files
- `Dockerfile`: Docker build instructions (installs Node.js 22.18.0, npm 11.5.2, and n8n)
- `docker-compose.yml`: Compose file for easy management, port mapping, and persistent data
- `.env`: Environment variables (not committed)

## Setup
1. **Clone this repository**
2. **Build the Docker image:**
   ```bash
   docker build -t n8n-docker-image .
   ```

   This will install Node.js 22.18.0, npm 11.5.2, and n8n in the container.

3. **(Recommended) Set up persistent storage for n8n workflows:**
   - The docker-compose.yml file maps `./n8n_data` on your host to `/home/node/.n8n` in the container.
   - This ensures your n8n workflows and settings are saved across container restarts.

## Usage

### Run with Docker Compose (Recommended)
```bash
docker compose up
```

### Accessing n8n Web Interface
- After starting the container, open [http://localhost:5678](http://localhost:5678) in your browser.
- On first launch, you may see the setup page. After creating an account, you will be redirected to the sign-in page on future visits.
- All workflows and settings are saved in the `n8n_data` folder on your host (if using Docker Compose as configured).

## Dependencies
Node.js 22.18.0, npm 11.5.2, and n8n are installed in the container for workflow automation and tutorials.

## License
MIT (or specify your license)
