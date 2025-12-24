#!/bin/bash
# Installation script for Raspberry Pi Service Manager

set -e

echo "================================================"
echo "  Raspberry Pi Service Manager - Installation"
echo "================================================"
echo

# Configuration
INSTALL_DIR="/home/pi/service-manager"
SERVICE_NAME="service-manager"

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for required commands
echo "Checking dependencies..."
command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 is required but not installed. Install with: sudo apt install python3"; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "❌ pip3 is required but not installed. Install with: sudo apt install python3-pip"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Install with: curl -fsSL https://get.docker.com | sh"; exit 1; }

echo "✓ All dependencies found"
echo

# Create installation directory
echo "Creating installation directory at $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown pi:pi "$INSTALL_DIR"

# Copy files
echo "Copying application files..."
cp -r ./* "$INSTALL_DIR/" 2>/dev/null || true
cd "$INSTALL_DIR"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env configuration file..."
    cp .env.example .env
    echo "✓ Created .env file - please edit with your container names if needed"
fi

# Create Python virtual environment
echo "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Add user to docker group if not already added
if ! groups pi | grep -q docker; then
    echo "Adding user 'pi' to docker group..."
    sudo usermod -aG docker pi
    echo "⚠️  You will need to log out and back in for docker group membership to take effect"
fi

# Install systemd service
echo "Installing systemd service..."
sudo cp "$INSTALL_DIR/$SERVICE_NAME.service" "/etc/systemd/system/$SERVICE_NAME.service"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME.service"

echo
echo "✓ Installation complete!"
echo
echo "Next steps:"
echo "1. Edit $INSTALL_DIR/.env with your container names"
echo "2. Log out and back in (for docker group membership)"
echo "3. Start the service: sudo systemctl start $SERVICE_NAME"
echo "4. Check status: sudo systemctl status $SERVICE_NAME"
echo "5. Run ./setup-kiosk.sh to configure auto-start in kiosk mode"
echo
