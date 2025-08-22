## Version Control Best Practices

This project includes a `.gitignore` file to prevent committing sensitive or unnecessary files (such as `.env`, Python cache files, and editor settings) to your repository. Always check that your `.env` and other local files are excluded from version control.


# Quick AI Project Starter (Docker & n8n Edition)


This repository provides a simple terminal-based chatbot using OpenAI's API, and also includes n8n (workflow automation) installed in the same Docker container for easy setup and reproducibility.

## Features
- Chatbot powered by OpenAI (GPT-4o-mini)
- Zero local Python setup required—just use Docker
- Uses environment variables for API keys

## Files
- `app.py`: Main chatbot script
- `requirements.txt`: Python dependencies
- `Dockerfile`: Docker build instructions (installs Python, Node.js 22.18.0, npm 11.5.2, and n8n)
- `docker-compose.yml`: Compose file for easy management, port mapping, and persistent data
- `.env`: Environment variables (not committed)

## Setup
1. **Clone this repository**
2. **Set your OpenAI API key:**
    - Copy the provided `.env.example` to `.env`:
       ```bash
       cp .env.example .env
       ```
    - Edit `.env` and fill in your actual OpenAI API key.
3. **Build the Docker image:**
   ```bash
   docker build -t app-docker-image .
   ```

   This will install Python, Node.js 22.18.0, npm 11.5.2, and n8n in the container. Node.js, npm, and n8n are included for compatibility with workflow automation and tutorials.

4. **(Recommended) Set up persistent storage for n8n workflows:**
   - The docker-compose.yml file maps `./n8n_data` on your host to `/home/node/.n8n` in the container.
   - This ensures your n8n workflows and settings are saved across container restarts.

## Usage


### Run with Docker (Chatbot only)
```bash
docker run --env-file .env -it app-docker-image python app.py
```
Type your message and interact with the bot. Type `exit`, `bye`, or `quit` to end the session.

### Run with Docker Compose (Recommended for n8n)
```bash
docker compose up
```

### Or use Docker Compose
```bash
docker compose up
```

### Accessing n8n Web Interface
- After starting the container, open [http://localhost:5678](http://localhost:5678) in your browser.
- On first launch, you may see the setup page. After creating an account, you will be redirected to the sign-in page on future visits.
- All workflows and settings are saved in the `n8n_data` folder on your host (if using Docker Compose as configured).

## Dependencies
All Python dependencies are managed via Docker and listed in `requirements.txt`:
- openai
- python-dotenv

Node.js 22.18.0, npm 11.5.2, and n8n are also installed in the container for compatibility with tutorials, workflow automation, and tools that require them.

## License
MIT (or specify your license)
