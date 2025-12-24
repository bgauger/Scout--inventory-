#!/bin/bash
# Setup script for Raspberry Pi Kiosk Mode

set -e

echo "================================================"
echo "  Raspberry Pi Kiosk Mode Setup"
echo "================================================"
echo

# Configuration
AUTOSTART_DIR="/home/pi/.config/lxsession/LXDE-pi"
AUTOSTART_FILE="$AUTOSTART_DIR/autostart"

# Check if running as pi user
if [ "$USER" != "pi" ]; then
    echo "⚠️  This script should be run as the 'pi' user"
    echo "   Run: sudo -u pi ./setup-kiosk.sh"
    exit 1
fi

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y chromium-browser unclutter xdotool

# Create autostart directory if it doesn't exist
mkdir -p "$AUTOSTART_DIR"

# Backup existing autostart file
if [ -f "$AUTOSTART_FILE" ]; then
    echo "Backing up existing autostart configuration..."
    cp "$AUTOSTART_FILE" "$AUTOSTART_FILE.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create new autostart configuration
echo "Creating kiosk mode autostart configuration..."
cat > "$AUTOSTART_FILE" << 'EOF'
# Disable screen saver and power management
@xset s off
@xset -dpms
@xset s noblank

# Hide mouse cursor when idle
@unclutter -idle 0.5 -root

# Start Chromium in kiosk mode
@chromium-browser --noerrdialogs --disable-infobars --kiosk --incognito --disable-session-crashed-bubble --disable-restore-session-state http://localhost:5000

# Alternative: Use Chromium in app mode (with window controls)
# Uncomment the line below and comment out the line above if you prefer
# @chromium-browser --noerrdialogs --disable-infobars --app=http://localhost:5000 --start-fullscreen
EOF

echo "✓ Kiosk mode configuration created"
echo

# Configure Raspberry Pi settings
echo "Configuring Raspberry Pi settings..."

# Disable screen blanking in /boot/config.txt if not already done
if ! grep -q "^hdmi_blanking=1" /boot/config.txt 2>/dev/null; then
    echo "Adding HDMI settings to /boot/config.txt..."
    echo "" | sudo tee -a /boot/config.txt
    echo "# Prevent screen blanking" | sudo tee -a /boot/config.txt
    echo "hdmi_blanking=1" | sudo tee -a /boot/config.txt
fi

# Create a script to rotate screen if needed (for portrait mode)
cat > /home/pi/rotate-screen.sh << 'EOF'
#!/bin/bash
# Script to rotate the display
# Usage: ./rotate-screen.sh [0|90|180|270]

ROTATION=${1:-0}

# Set display rotation
xrandr --output HDMI-1 --rotate $ROTATION 2>/dev/null || \
xrandr --output HDMI-0 --rotate $ROTATION 2>/dev/null || \
echo "Could not rotate display. Run 'xrandr' to see available outputs."

# Adjust touchscreen if present
xinput list | grep -i touch | grep -o 'id=[0-9]*' | cut -d'=' -f2 | while read TOUCH_ID; do
    xinput set-prop $TOUCH_ID "Coordinate Transformation Matrix" \
        $(case $ROTATION in
            90) echo "0 1 0 -1 0 1 0 0 1";;
            180) echo "-1 0 1 0 -1 1 0 0 1";;
            270) echo "0 -1 1 1 0 0 0 0 1";;
            *) echo "1 0 0 0 1 0 0 0 1";;
        esac) 2>/dev/null
done
EOF

chmod +x /home/pi/rotate-screen.sh

echo
echo "✓ Kiosk mode setup complete!"
echo
echo "Configuration details:"
echo "  - Screen saver: Disabled"
echo "  - Mouse cursor: Auto-hide when idle"
echo "  - Browser: Chromium in kiosk mode"
echo "  - URL: http://localhost:5000"
echo
echo "Optional configurations:"
echo "  - To rotate screen: ./rotate-screen.sh [0|90|180|270]"
echo "  - To edit autostart: nano $AUTOSTART_FILE"
echo
echo "To apply changes:"
echo "  1. Ensure the service is running: sudo systemctl start service-manager"
echo "  2. Reboot the Raspberry Pi: sudo reboot"
echo
echo "To disable kiosk mode:"
echo "  1. Restore backup: cp $AUTOSTART_FILE.backup.* $AUTOSTART_FILE"
echo "  2. Or delete: rm $AUTOSTART_FILE"
echo
