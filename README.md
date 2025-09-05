## Version Control Best Practices

This project includes a `.gitignore` file to prevent committing sensitive or unnecessary files (such as `.env`, Python cache files, and editor settings) to your repository. Always check that your `.env` and other local files are excluded from version control.


# n8n Docker Automation Starter

This repository provides n8n (workflow automation) in a Docker container, with persistent storage, PDF processing support (poppler-utils), and recommended configuration for modern n8n deployments.

## Features
- Workflow automation with n8n
- PDF processing support via poppler-utils
- Zero local setup required—just use Docker
- Persistent storage for workflows and credentials

## Files
- `Dockerfile`: Custom image based on n8nio/n8n:latest, installs poppler-utils for PDF processing
- `docker-compose.yml`: Compose file for easy management, port mapping, persistent data, custom container name, and recommended n8n environment variables
- `.env`: Environment variables (not committed)

## Setup
1. **Clone this repository**
2. **Build the Docker image:**
   ```bash
   docker build -t my-n8n-custom .
   ```

   This will install n8n and poppler-utils in the container.

3. **(Recommended) Set up persistent storage for n8n workflows:**
   - The docker-compose.yml file maps `./n8n_data` on your host to `/home/node/.n8n` in the container.
   - This ensures your n8n workflows and settings are saved across container restarts.
   - The container is named `my-n8n` for easy access.

## Usage

### Run with Docker Compose (Recommended)
```bash
docker compose up
```

### Accessing n8n Web Interface
- After starting the container, open [http://localhost:5678](http://localhost:5678) in your browser.
- On first launch, you may see the setup page. After creating an account, you will be redirected to the sign-in page on future visits.
- All workflows and settings are saved in the `n8n_data` folder on your host (if using Docker Compose as configured).
- To open a shell in the running container (for troubleshooting or to check poppler-utils):
   ```bash
   docker exec -it my-n8n sh
   pdftotext -v
   ```

## Dependencies
- n8n (from official image)
- poppler-utils (for PDF processing)

## Recommended n8n Environment Variables
- N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
- DB_SQLITE_POOL_SIZE=2
- N8N_RUNNERS_ENABLED=true

## License
MIT (or specify your license)
