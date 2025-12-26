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
├── .env.example           # Template for environment setup
├── n8n_data/             # Persistent n8n data (workflows, settings)
├── my-files/             # File storage for workflows
├── backups/              # Backup archives (excluded from system backups)
├── utils/                # Backup/restore utilities
│   ├── backup_n8n.sh                  # Automated backup script
│   └── restore_n8n.sh                 # Restore script with system backup
└── scripts/              # Custom Python scripts and utilities
    ├── analyze_receipt_accuracy.py    # Receipt validation analytics
    ├── enhance_image.py               # Basic image enhancement
    ├── enhance_image2.py              # Advanced OpenCV enhancement
    ├── enhance_image3.py              # PIL-based enhancement
    ├── enhance_image4.py              # Receipt-specific processing
    ├── enhance_image5.py              # Minimal processing
    ├── log_error_invalid_receipt.py   # Error logging utility
    ├── price_validator.py             # Receipt price validation
    ├── receipt_price_check.py         # Price difference checker
    └── store_tolerance.py             # Store-specific validation
```

## Setup
1. **Clone this repository**

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` and add your actual API keys:
   - **OPENAI_API_KEY**: Get from [OpenAI Platform](https://platform.openai.com/api-keys)
   - **GEMINI_API_KEY**: Get from [Google AI Studio](https://makersuite.google.com/app/apikey)

3. **Build the Docker image:**
   ```bash
   docker build -t my-n8n-custom .
   ```
   
   This creates a custom n8n image with:
   - n8n v2.1.4
   - poppler-utils for PDF processing
   - Python 3 with pip and Pillow
   - Conditional package installation (supports Alpine and Debian-based images)

4. **Set up persistent storage:**
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

## Backup & Restore

The project includes automated backup scripts for protecting your n8n data with comprehensive safety features:

### Quick Backup
```bash
# Complete backup (recommended) - creates n8n_backup_YYYYMMDD_HHMMSS.tar.gz
./utils/backup_n8n.sh

# Database only (fastest)
docker compose down
cp n8n_data/database.sqlite "backup_$(date +%Y%m%d).sqlite"
docker compose up -d
```

### Restore with System Backup Protection
```bash
# Full restore with automatic system backup (RECOMMENDED)
./utils/restore_n8n.sh backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz --test-and-replace

# Extract backup for inspection/comparison only (does not restore system)
./utils/restore_n8n.sh backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz
```

**Restore Options Explained:**
- **`--test-and-replace`** (Recommended): Complete restore workflow with safety mechanisms
- **Extract-only**: Extracts backup to timestamped folder for inspection/debugging - manual work required

**🔒 Safety Features (--test-and-replace mode):**
- **Comprehensive System Backup**: Before any restore, creates `n8n_SYSTEM_COPY/` with complete current system state
- **Test-and-Replace**: Validates backup integrity before applying changes
- **Rollback Protection**: Complete system can be restored from `n8n_SYSTEM_COPY/` if restore fails
- **Smart Exclusions**: Backups exclude `backups/` and `n8n_SYSTEM_COPY/` folders to prevent circular references

### Cloud Storage
The backup script supports Google Drive, Dropbox, and AWS S3. Configure with rclone for automatic cloud uploads.

**Backup sizes:** Database only (~50MB), Complete backup (~80-200MB compressed)

## Workflow Storage & Data Persistence
- **n8n workflows**: Stored in `n8n_data/database.sqlite` (SQLite database)
- **Binary data**: Files and images from executions in `n8n_data/binaryData/`
- **Configuration**: n8n settings in `n8n_data/config`
- **Logs**: Application logs in `n8n_data/n8nEventLog*.log`
- **Backup recommendation**: Always backup the entire `n8n_data/` folder
- **System safety**: `n8n_SYSTEM_COPY/` contains complete system backup during restore operations (excluded from regular backups)

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
- **Backup & Restore Enhancement**: 
  - Added comprehensive backup scripts with cloud storage support
  - Implemented `n8n_SYSTEM_COPY` safety mechanism for complete system rollback
  - Unified naming convention: `n8n_backup_YYYYMMDD_HHMMSS.tar.gz`
  - Smart exclusions: backups and system copies excluded from backup archives
  - Test-and-replace workflow with automatic integrity validation
- **Requirements.txt**: Updated with complete Python dependencies and version constraints
- **Security Review**: Confirmed all scripts are safe for version control
- **Enhanced Documentation**: Added Python dependencies section and security information
- **Improved Dockerfile**: Added conditional package installation for better compatibility
- **Utility Organization**: Moved backup/restore scripts to `utils/` directory

## License
MIT (or specify your license)
