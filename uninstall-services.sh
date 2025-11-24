#!/bin/bash
set -e

echo "Uninstalling systemd services..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

SERVICE_DIR="resources/systemctl"

if [ ! -d "$SERVICE_DIR" ]; then
    echo "Error: $SERVICE_DIR directory not found"
    exit 1
fi

# Stop and disable each service
for service_file in "$SERVICE_DIR"/*.service; do
    if [ -f "$service_file" ]; then
        service_name=$(basename "$service_file")

        echo "Stopping $service_name..."
        systemctl stop "$service_name" || true

        echo "Disabling $service_name..."
        systemctl disable "$service_name" || true

        echo "Removing $service_name..."
        rm -f "/etc/systemd/system/$service_name"

        echo "✓ Uninstalled $service_name"
        echo ""
    fi
done

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed

echo "All services uninstalled!"
