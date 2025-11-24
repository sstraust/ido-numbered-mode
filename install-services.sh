#!/bin/bash
set -e

echo "Installing systemd services..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Copy service files to systemd directory
SERVICE_DIR="resources/systemctl"

if [ ! -d "$SERVICE_DIR" ]; then
    echo "Error: $SERVICE_DIR directory not found"
    exit 1
fi

# Install each service file
for service_file in "$SERVICE_DIR"/*.service; do
    if [ -f "$service_file" ]; then
        service_name=$(basename "$service_file")
        echo "Installing $service_name..."

        # Copy to systemd directory
        cp "$service_file" /etc/systemd/system/

        # Set proper permissions
        chmod 644 "/etc/systemd/system/$service_name"

        echo "✓ Installed $service_name"
    fi
done

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start services
echo ""
echo "Enabling and starting services..."
for service_file in "$SERVICE_DIR"/*.service; do
    if [ -f "$service_file" ]; then
        service_name=$(basename "$service_file")

        echo "Enabling $service_name..."
        systemctl enable "$service_name"

        echo "Starting $service_name..."
        systemctl start "$service_name"

        # Check status
        if systemctl is-active --quiet "$service_name"; then
            echo "✓ $service_name is running"
        else
            echo "⚠ $service_name failed to start"
            systemctl status "$service_name" --no-pager
        fi
        echo ""
    fi
done

echo "All services installed and started!"
echo ""
echo "To check service status:"
echo "  systemctl status <service-name>"
echo ""
echo "To view logs:"
echo "  journalctl -u <service-name> -f"
