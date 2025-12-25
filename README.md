## Version Control Best Practices

This project includes a `.gitignore` file to prevent committing sensitive or unnecessary files (such as `.env`, Python cache files, and editor settings) to your repository. Always check that your `.env` and other local files are excluded from version control.


# n8n Docker Automation Starter

This repository provides n8n (workflow automation) in a Docker container with persistent storage, PDF processing support (poppler-utils), Python 3 (with Pillow), and recommended configuration for modern n8n deployments.

## Current Version
- **n8n**: v2.1.4 (latest)
- **Base Image**: n8nio/n8n:2.1.4

## Features
- Workflow automation with n8n v2.1.4
- PDF processing support via poppler-utils
- Python 3 and Pillow for custom Python workflows
- Zero local setup required—just use Docker
- Persistent storage for workflows and credentials
- Automatic package detection for different base image types
- Custom scripts directory mounted at `/home/node/scripts`

## Files
- `Dockerfile`: Custom image based on n8nio/n8n:2.1.4, with conditional package installation for poppler-utils, Python 3, and Pillow
- `docker-compose.yml`: Compose file with port mapping, persistent data volumes, custom container name, and recommended n8n environment variables
- `.env`: Environment variables (not committed to version control)
- `scripts/`: Directory for custom Python scripts, mounted in the container
- `my-files/`: Directory for file storage, mounted at `/files` in the container

## Directory Structure
```
n8n_demo/
├── docker-compose.yml      # Container orchestration
├── Dockerfile             # Custom n8n image with additional tools
├── README.md              # This file
├── requirements.txt       # Python dependencies
├── .env                   # Environment variables (not committed)
├── n8n_data/             # Persistent n8n data (workflows, settings)
├── my-files/             # File storage for workflows
└── scripts/              # Custom Python scripts
    ├── analyze_receipt_accuracy.py
    ├── enhance_image.py
    ├── enhance_image2.py
    ├── enhance_image3.py
    ├── enhance_image4.py
    ├── enhance_image5.py
    ├── log_error_invalid_receipt.py
    ├── price_validator.py
    ├── receipt_price_check.py
    └── store_tolerance.py
```

## Setup
1. **Clone this repository**
2. **Build the Docker image:**
   ```bash
   docker build -t my-n8n-custom .
   ```
   
   This creates a custom n8n image with:
   - n8n v2.1.4
   - poppler-utils for PDF processing
   - Python 3 with pip and Pillow
   - Conditional package installation (supports Alpine and Debian-based images)

3. **Set up persistent storage:**
   - The `docker-compose.yml` file maps volumes for persistent data:
     - `./n8n_data` → `/home/node/.n8n` (n8n workflows and settings)
     - `./scripts` → `/home/node/scripts` (custom Python scripts)
     - `./my-files` → `/files` (file storage for workflows)
   - Container is named `my-n8n` for easy access

## Upgrading n8n
To upgrade to a newer version of n8n:
1. Stop the current container: `docker compose down`
2. Pull the latest base image: `docker pull n8nio/n8n:latest`
3. Update the Dockerfile `FROM` line with the desired version
4. Rebuild the custom image: `docker build -t my-n8n-custom .`
5. Start the updated container: `docker compose up -d`

## Usage

### Run with Docker Compose (Recommended)
```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
docker compose down
```

### Accessing n8n Web Interface
- After starting the container, open [http://localhost:5678](http://localhost:5678) in your browser
- On first launch, you'll see the setup page to create an account
- All workflows and settings are automatically saved in the `n8n_data` folder
- To open a shell in the running container for troubleshooting:
   ```bash
   docker exec -it my-n8n sh
   
   # Test installed packages
   pdftotext -v                                    # PDF processing
   python3 --version                               # Python version
   python3 -c "import PIL; print(PIL.__version__)" # Pillow image library
   n8n --version                                   # n8n version
   ```

## Workflow Storage & Data Persistence
- **n8n workflows**: Stored in `n8n_data/database.sqlite` (SQLite database)
- **Binary data**: Files and images from executions in `n8n_data/binaryData/`
- **Configuration**: n8n settings in `n8n_data/config`
- **Logs**: Application logs in `n8n_data/n8nEventLog*.log`
- **Backup recommendation**: Always backup the entire `n8n_data/` folder

## Container Information
- **Container Name**: `my-n8n`
- **Port**: `5678` (mapped to host port 5678)
- **Base Image**: n8nio/n8n:2.1.4
- **Working Directory**: `/home/node`
- **Data Persistence**: `./n8n_data` volume

## Python Dependencies
The `requirements.txt` file contains all necessary Python packages:

### Core Dependencies:
- **openai>=1.0.0**: OpenAI API integration for workflows
- **python-dotenv>=0.19.0**: Environment variable management

### Image Processing Dependencies:
- **Pillow>=9.0.0**: PIL library for image enhancement (used in enhance_image*.py)
- **opencv-python>=4.5.0**: Advanced image processing (used in enhance_image2.py)
- **numpy>=1.21.0**: Numerical arrays for OpenCV operations

### Installation:
```bash
# Install dependencies in the container (if needed)
docker exec -it my-n8n pip install -r /home/node/scripts/../requirements.txt
```

## Script Security & Version Control
✅ **All scripts are safe to commit** - No credentials or sensitive data found in any Python files.

### What's included in scripts/ (all secure):
- **Receipt Processing**: `price_validator.py`, `receipt_price_check.py`, `store_tolerance.py`
- **Image Enhancement**: `enhance_image.py`, `enhance_image2.py`, `enhance_image3.py`, `enhance_image4.py`, `enhance_image5.py`
- **Analytics & Logging**: `analyze_receipt_accuracy.py`, `log_error_invalid_receipt.py`

### Credentials are safely stored:
- **n8n workflows & credentials**: In `n8n_data/database.sqlite` (excluded from git)
- **API keys & tokens**: In `.env` file (excluded by `.gitignore`)
- **OAuth credentials**: Managed by n8n internally

## Environment Variables (via .env file)
The following environment variables are configured for optimal n8n performance:
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true`
- `DB_SQLITE_POOL_SIZE=2`
- `N8N_RUNNERS_ENABLED=true`

## Troubleshooting
- **Port conflict**: If port 5678 is in use, modify the port mapping in `docker-compose.yml`
- **Build issues**: Ensure Docker is running and you have internet access for base image download
- **Data persistence**: Check that the `n8n_data` directory has proper permissions
- **Package issues**: The Dockerfile uses conditional installation to handle different base image types

## Recent Updates
- **December 2025**: Upgraded to n8n v2.1.4 with enhanced Dockerfile
- **Requirements.txt**: Updated with complete Python dependencies and version constraints
- **Security Review**: Confirmed all scripts are safe for version control
- **Enhanced Documentation**: Added Python dependencies section and security information
- **Improved Dockerfile**: Added conditional package installation for better compatibility

## License
MIT (or specify your license)
