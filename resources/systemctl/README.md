# Systemd Services

This directory contains systemd service files for managing application services on the host machine.

## Important Notes

- **These services run on the HOST, not in Docker**
- Docker containers (MongoDB, PostgreSQL) are managed by docker-compose
- These systemd services are typically for application processes that need to run outside of Docker

## Installation

### Install all services:
```bash
sudo ./install-services.sh
```

### Uninstall all services:
```bash
sudo ./uninstall-services.sh
```

## Managing Services

### Check status of all services:
```bash
sudo systemctl status $(ls resources/systemctl/*.service | xargs -n 1 basename)
```

### Restart all services:
```bash
sudo systemctl restart $(ls resources/systemctl/*.service | xargs -n 1 basename)
```

### View logs:
```bash
# Specific service
sudo journalctl -u example-app.service -f

# All services
sudo journalctl -f
```

### Individual service management:
```bash
# Start
sudo systemctl start example-app.service

# Stop
sudo systemctl stop example-app.service

# Restart
sudo systemctl restart example-app.service

# Enable (start on boot)
sudo systemctl enable example-app.service

# Disable (don't start on boot)
sudo systemctl disable example-app.service
```

## Service File Template

```ini
[Unit]
Description=My Service Description
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/app
ExecStart=/usr/bin/command args
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables
Environment="KEY=value"

[Install]
WantedBy=multi-user.target
```

## Common Service Types

- `Type=simple` - Process runs in foreground (most common)
- `Type=forking` - Process forks to background
- `Type=oneshot` - Runs once and exits
- `Type=notify` - Service sends notification when ready

## Best Practices

1. **Use a non-root user** (e.g., `www-data`, `nginx`, or create a dedicated user)
2. **Set WorkingDirectory** to your application path
3. **Use absolute paths** for ExecStart
4. **Enable auto-restart** with `Restart=always`
5. **Add dependencies** with `After=` and `Requires=`
6. **Set environment variables** with `Environment=`
7. **Use StandardOutput/StandardError=journal** for logging

## Integration with Docker

Services can interact with Docker containers:

```ini
[Unit]
After=docker.service
Requires=docker.service

[Service]
# Can use environment variables from docker-compose
Environment="POSTGRES_URL=postgresql://user:pass@localhost:5432/db"
Environment="MONGODB_URL=mongodb://user:pass@localhost:27017/db"
```

## Troubleshooting

### Service won't start:
```bash
# Check status
sudo systemctl status service-name.service

# View logs
sudo journalctl -u service-name.service -n 50

# Check for errors
sudo systemctl --failed
```

### Service keeps restarting:
```bash
# View real-time logs
sudo journalctl -u service-name.service -f

# Check if process is crashing
sudo systemctl status service-name.service
```

### Reload after editing service file:
```bash
sudo systemctl daemon-reload
sudo systemctl restart service-name.service
```
