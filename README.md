# Raspberry Pi Service Manager

A full-screen touchscreen application for Raspberry Pi that monitors and manages Docker containers. Designed for 7-inch displays with a touch-friendly interface.

## Features

- 🖥️ **Full-screen kiosk mode** - Perfect for dedicated 7-inch touchscreen displays
- 🐳 **Docker monitoring** - Real-time status of web app and database containers
- 🔄 **Service management** - Restart containers with a single touch
- 📊 **Live status updates** - Auto-refreshing container health information
- 🎨 **Touch-optimized UI** - Large buttons and clear visual indicators
- ⚡ **Lightweight** - Runs efficiently on Raspberry Pi hardware

## Screenshots

The interface shows:
- Container status (running, stopped, error states)
- Container information (image, ID, state)
- One-touch restart buttons
- Color-coded status indicators
- Auto-updating timestamps

## Requirements

### Hardware
- Raspberry Pi (3B+ or newer recommended)
- 7-inch touchscreen display (800x480 resolution)
- MicroSD card (8GB minimum)
- Power supply

### Software
- Raspberry Pi OS (formerly Raspbian)
- Python 3.7 or newer
- Docker
- Chromium browser

## Installation

### 1. Prepare Your Raspberry Pi

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker (if not already installed)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker pi

# Install Python dependencies
sudo apt install -y python3 python3-pip python3-venv git

# Reboot to apply group changes
sudo reboot
```

### 2. Clone and Install the Application

```bash
# Clone the repository
cd ~
git clone <repository-url> service-manager
cd service-manager

# Make scripts executable
chmod +x install.sh setup-kiosk.sh

# Run installation
./install.sh
```

### 3. Configure Your Containers

Edit the `.env` file to match your Docker container names:

```bash
nano /home/pi/service-manager/.env
```

Update these values:
```env
WEB_CONTAINER_NAME=webapp
DB_CONTAINER_NAME=database
```

### 4. Start the Service

```bash
# Start the service
sudo systemctl start service-manager

# Check if it's running
sudo systemctl status service-manager

# View logs
sudo journalctl -u service-manager -f
```

### 5. Set Up Kiosk Mode

```bash
# Run the kiosk setup script
./setup-kiosk.sh

# Reboot to activate kiosk mode
sudo reboot
```

## Usage

### Starting Your Docker Containers

Before using the service manager, ensure your Docker containers are running:

```bash
# Using the example docker-compose.yml
docker-compose -f docker-compose.example.yml up -d

# Or start your own containers
docker run -d --name webapp nginx:alpine
docker run -d --name database postgres:15-alpine
```

### Accessing the Interface

- **On the Raspberry Pi**: The interface will automatically open in full-screen mode after boot
- **From another device**: Navigate to `http://<raspberry-pi-ip>:5000`

### Managing Services

1. **View Status**: Container status updates automatically every 5 seconds
2. **Restart Service**: Tap the "Restart" button for the desired service
3. **Confirm Action**: Confirm the restart in the dialog
4. **Monitor Progress**: Watch the status change from "Running" to "Restarting" to "Running"

## Configuration

### Environment Variables (.env)

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_ENV` | `production` | Flask environment |
| `FLASK_PORT` | `5000` | Port for the web interface |
| `FLASK_HOST` | `0.0.0.0` | Host binding |
| `WEB_CONTAINER_NAME` | `webapp` | Name of web app container |
| `DB_CONTAINER_NAME` | `database` | Name of database container |
| `REFRESH_INTERVAL` | `5000` | UI refresh interval (ms) |

### Screen Rotation

To rotate the display for different orientations:

```bash
# Portrait mode (90 degrees)
./rotate-screen.sh 90

# Upside down (180 degrees)
./rotate-screen.sh 180

# Landscape inverted (270 degrees)
./rotate-screen.sh 270

# Normal landscape (0 degrees)
./rotate-screen.sh 0
```

## API Endpoints

The application provides a REST API:

### GET /api/status
Get current status of all monitored containers.

**Response:**
```json
{
  "timestamp": "2025-12-24T10:30:00",
  "containers": {
    "web": {
      "name": "webapp",
      "status": "running",
      "state": "running",
      "id": "abc123",
      "image": "nginx:alpine"
    },
    "database": {
      "name": "database",
      "status": "running",
      "state": "running",
      "id": "def456",
      "image": "postgres:15-alpine"
    }
  }
}
```

### POST /api/restart/&lt;container_type&gt;
Restart a specific container.

**Parameters:**
- `container_type`: Either `web` or `database`

**Response:**
```json
{
  "success": true,
  "message": "Container webapp restarted successfully"
}
```

### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "docker_available": true,
  "timestamp": "2025-12-24T10:30:00"
}
```

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status service-manager

# View detailed logs
sudo journalctl -u service-manager -n 50

# Check if port 5000 is available
sudo netstat -tulpn | grep 5000
```

### Docker permission errors

```bash
# Verify user is in docker group
groups pi

# If not, add user and reboot
sudo usermod -aG docker pi
sudo reboot
```

### Kiosk mode not starting

```bash
# Check autostart configuration
cat ~/.config/lxsession/LXDE-pi/autostart

# Check Chromium
chromium-browser --version

# Test manually
DISPLAY=:0 chromium-browser --kiosk http://localhost:5000
```

### Container not found

1. Verify container names in `.env` match actual containers
2. Check containers are running: `docker ps`
3. Restart the service: `sudo systemctl restart service-manager`

### Touchscreen calibration

```bash
# Install calibration tool
sudo apt install xinput-calibrator

# Run calibration
DISPLAY=:0 xinput_calibrator
```

## Development

### Running in Development Mode

```bash
# Activate virtual environment
cd /home/pi/service-manager
source venv/bin/activate

# Run with Flask development server
export FLASK_ENV=development
python app.py
```

### Project Structure

```
service-manager/
├── app.py                      # Main Flask application
├── requirements.txt            # Python dependencies
├── .env                        # Configuration (not in git)
├── .env.example               # Example configuration
├── templates/
│   └── index.html             # Main UI template
├── static/
│   ├── css/
│   │   └── style.css          # Styles optimized for 7" screen
│   └── js/
│       └── app.js             # Client-side JavaScript
├── service-manager.service    # Systemd service file
├── install.sh                 # Installation script
├── setup-kiosk.sh            # Kiosk mode setup script
├── docker-compose.example.yml # Example Docker setup
└── README.md                  # This file
```

## Systemd Service Commands

```bash
# Start service
sudo systemctl start service-manager

# Stop service
sudo systemctl stop service-manager

# Restart service
sudo systemctl restart service-manager

# Enable auto-start on boot
sudo systemctl enable service-manager

# Disable auto-start
sudo systemctl disable service-manager

# View status
sudo systemctl status service-manager

# View logs
sudo journalctl -u service-manager -f
```

## Customization

### Monitoring Additional Containers

Edit `/home/pi/service-manager/.env` and add more container names. Then modify `app.py` to add additional monitoring endpoints and update the UI templates accordingly.

### Changing Refresh Interval

Edit `.env` and change `REFRESH_INTERVAL` value (in milliseconds):
```env
REFRESH_INTERVAL=3000  # Update every 3 seconds
```

### Custom Styling

Edit `/home/pi/service-manager/static/css/style.css` to customize colors, fonts, and layout.

## Security Considerations

- The application runs on port 5000 by default
- No authentication is implemented - intended for local network use
- Docker socket access is required (user must be in docker group)
- For production use, consider:
  - Adding authentication
  - Using HTTPS
  - Restricting network access
  - Running behind a reverse proxy

## License

MIT License - feel free to modify and distribute as needed.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Support

For issues and questions:
1. Check the Troubleshooting section above
2. Review logs: `sudo journalctl -u service-manager -n 100`
3. Open an issue on GitHub

## Acknowledgments

Built with:
- Flask - Web framework
- Docker SDK for Python - Container management
- Chromium - Kiosk mode browser
- Raspberry Pi OS - Operating system
