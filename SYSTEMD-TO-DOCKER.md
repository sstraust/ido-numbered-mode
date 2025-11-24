# Converting Systemd Services to Docker

This guide shows how to convert existing systemd service definitions to Docker Compose services.

## Quick Start

### Automatic Conversion

Run the conversion script on your existing service files:

```bash
# Convert all services in resources/systemctl/
./systemd-to-docker.sh

# Convert a specific service
./systemd-to-docker.sh resources/systemctl/myservice.service
```

The script will output docker-compose.yml service definitions you can copy.

### Manual Conversion

Follow the mapping table below to convert each directive.

## Systemd → Docker Compose Mapping

| Systemd Directive | Docker Compose Equivalent | Notes |
|------------------|---------------------------|-------|
| `Description=` | `# comment` or `container_name:` | Becomes a comment or service name |
| `After=` | `depends_on:` | Ensures startup order |
| `Requires=` | `depends_on:` | Service dependencies |
| `User=` | `user:` or `USER` in Dockerfile | User to run as |
| `WorkingDirectory=` | `working_dir:` | Working directory |
| `ExecStart=` | `command:` | Command to run |
| `ExecStartPre=` | `entrypoint:` or init script | Pre-start commands |
| `Restart=always` | `restart: always` | Restart policy |
| `Restart=on-failure` | `restart: on-failure` | Restart on error |
| `Environment=` | `environment:` | Environment variables |
| `EnvironmentFile=` | `env_file:` | Environment file |
| `StandardOutput=journal` | (automatic) | Docker captures logs |
| `StandardError=journal` | (automatic) | Docker captures logs |

## Complete Examples

### Example 1: Node.js Web Service

**Systemd Service** (`resources/systemctl/web.service`):
```ini
[Unit]
Description=Web Application
After=network.target docker.service postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment="NODE_ENV=production"
Environment="PORT=3000"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Docker Compose Equivalent**:
```yaml
services:
  web:
    build: .
    container_name: web
    user: www-data
    working_dir: /opt/myapp
    command: node server.js
    restart: always
    environment:
      NODE_ENV: production
      PORT: 3000
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./myapp:/opt/myapp
      - /opt/myapp/node_modules
```

### Example 2: Python Worker Service

**Systemd Service** (`resources/systemctl/worker.service`):
```ini
[Unit]
Description=Background Worker
After=network.target mongodb.service

[Service]
Type=simple
User=worker
WorkingDirectory=/opt/worker
ExecStart=/usr/bin/python3 worker.py
Restart=on-failure
Environment="PYTHONUNBUFFERED=1"
Environment="QUEUE_NAME=jobs"

[Install]
WantedBy=multi-user.target
```

**Docker Compose Equivalent**:
```yaml
services:
  worker:
    build: .
    container_name: worker
    user: worker
    working_dir: /opt/worker
    command: python3 worker.py
    restart: on-failure
    environment:
      PYTHONUNBUFFERED: 1
      QUEUE_NAME: jobs
    depends_on:
      mongodb:
        condition: service_healthy
    volumes:
      - ./worker:/opt/worker
```

### Example 3: Multiple Services

**Before** (multiple systemd services):
- `api.service` - REST API
- `worker.service` - Background worker
- `scheduler.service` - Cron-like scheduler

**After** (single docker-compose.yml):
```yaml
version: '3.8'

services:
  api:
    build: .
    command: npm run api
    ports:
      - "8000:8000"
    environment:
      SERVICE_TYPE: api
    depends_on:
      - postgres
      - mongodb
    restart: unless-stopped

  worker:
    build: .
    command: npm run worker
    environment:
      SERVICE_TYPE: worker
    depends_on:
      - postgres
      - mongodb
    restart: unless-stopped

  scheduler:
    build: .
    command: npm run scheduler
    environment:
      SERVICE_TYPE: scheduler
    depends_on:
      - postgres
      - mongodb
    restart: unless-stopped

  postgres:
    image: pgvector/pgvector:pg16
    # ... (existing postgres config)

  mongodb:
    image: mongo:7
    # ... (existing mongodb config)
```

## Dockerfile Adjustments

If your systemd service uses specific system dependencies, create or update your Dockerfile:

### For Node.js Service:
```dockerfile
FROM node:20-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create user (matching systemd User=)
RUN useradd -m -u 1000 www-data || true

WORKDIR /opt/myapp

# Copy and install dependencies
COPY package*.json ./
RUN npm install

# Copy application
COPY . .

# Switch to non-root user
USER www-data

# Default command (can be overridden in docker-compose)
CMD ["node", "server.js"]
```

### For Python Service:
```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create user (matching systemd User=)
RUN useradd -m -u 1001 worker

WORKDIR /opt/worker

# Copy and install dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Switch to non-root user
USER worker

# Default command
CMD ["python3", "worker.py"]
```

## Common Conversion Patterns

### Pattern 1: ExecStart with Absolute Paths

**Systemd:**
```ini
ExecStart=/usr/bin/node /opt/myapp/server.js
```

**Docker:**
```yaml
working_dir: /opt/myapp
command: node server.js
```

### Pattern 2: Multiple Environment Variables

**Systemd:**
```ini
Environment="KEY1=value1"
Environment="KEY2=value2"
Environment="KEY3=value3"
```

**Docker (option A - inline):**
```yaml
environment:
  KEY1: value1
  KEY2: value2
  KEY3: value3
```

**Docker (option B - .env file):**
```yaml
env_file: .env
```

### Pattern 3: Service Dependencies

**Systemd:**
```ini
After=postgresql.service mongodb.service redis.service
Requires=postgresql.service
```

**Docker:**
```yaml
depends_on:
  postgres:
    condition: service_healthy
  mongodb:
    condition: service_healthy
  redis:
    condition: service_started
```

### Pattern 4: Pre-Start Commands

**Systemd:**
```ini
ExecStartPre=/usr/bin/migrate.sh
ExecStart=/usr/bin/node server.js
```

**Docker (option A - entrypoint script):**
```yaml
entrypoint: /docker-entrypoint.sh
command: node server.js
```

Create `docker-entrypoint.sh`:
```bash
#!/bin/bash
set -e

# Pre-start commands
/usr/bin/migrate.sh

# Run main command
exec "$@"
```

**Docker (option B - separate init container):**
```yaml
services:
  migrate:
    build: .
    command: /usr/bin/migrate.sh
    depends_on:
      - postgres

  app:
    build: .
    command: node server.js
    depends_on:
      migrate:
        condition: service_completed_successfully
```

## Migration Workflow

### Step 1: Inventory Your Services
```bash
ls resources/systemctl/*.service
```

### Step 2: Convert Services
```bash
./systemd-to-docker.sh > docker-services.yml
```

### Step 3: Review and Adjust

Edit the generated YAML and adjust:
- [ ] Ports (add `ports:` section)
- [ ] Volumes (add persistent data mounts)
- [ ] Networks (if services need isolation)
- [ ] Health checks (add for critical services)
- [ ] Resource limits (add `deploy.resources` if needed)

### Step 4: Update docker-compose.yml

Merge the converted services into your main `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Existing database services
  postgres:
    # ... existing config

  mongodb:
    # ... existing config

  # Add your converted services here
  api:
    # ... converted from api.service

  worker:
    # ... converted from worker.service
```

### Step 5: Test

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Test functionality
curl http://localhost:3000
```

### Step 6: Transition from Systemd

```bash
# Stop systemd services
sudo systemctl stop my-service.service
sudo systemctl disable my-service.service

# Start Docker services
docker-compose up -d my-service

# Verify
docker-compose logs my-service
```

### Step 7: Remove Systemd Services (optional)

Once Docker services are working:
```bash
sudo ./uninstall-services.sh
```

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
docker-compose logs service-name
```

**Common issues:**
- Working directory doesn't exist → add volume mount
- Command not found → check PATH or use absolute path
- Permission denied → check user/permissions in Dockerfile
- Dependencies not ready → add `depends_on` with health checks

### Environment Variables Not Working

**Debug:**
```bash
# Check environment in running container
docker-compose exec service-name env

# Check if .env file is loaded
docker-compose config
```

### Port Conflicts

**Error:** "Bind for 0.0.0.0:3000 failed: port is already allocated"

**Solution:**
```bash
# Check what's using the port
sudo lsof -i :3000

# Stop systemd service if still running
sudo systemctl stop old-service

# Or change port in docker-compose.yml
ports:
  - "3001:3000"  # Map host 3001 to container 3000
```

### File Permissions

If your systemd service ran as a specific user:

**In Dockerfile:**
```dockerfile
# Create matching user
RUN useradd -m -u 1000 myuser
USER myuser
```

**Or in docker-compose.yml:**
```yaml
user: "1000:1000"
```

## Benefits of Docker vs Systemd

| Feature | Systemd | Docker |
|---------|---------|--------|
| Isolation | Process-level | Container-level |
| Dependencies | System packages | Containerized |
| Portability | Server-specific | Runs anywhere |
| Development | Requires full server | Local with docker-compose |
| Scaling | Manual | Easy horizontal scaling |
| Rollback | Manual | Image-based |
| Resource Limits | cgroups | Docker resources |

## Reference

### Full docker-compose.yml Template

```yaml
version: '3.8'

services:
  # Your application service (converted from systemd)
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: app
    user: www-data
    working_dir: /opt/myapp
    command: node server.js
    restart: always
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      DATABASE_URL: ${DATABASE_URL}
    ports:
      - "${APP_PORT:-3000}:3000"
    volumes:
      - ./myapp:/opt/myapp
      - /opt/myapp/node_modules
    depends_on:
      postgres:
        condition: service_healthy
      mongodb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  postgres:
    image: pgvector/pgvector:pg16
    # ... existing config

  mongodb:
    image: mongo:7
    # ... existing config

volumes:
  postgres_data:
  mongodb_data:
```

## Next Steps

1. ✅ Run `./systemd-to-docker.sh` to convert your services
2. ✅ Review and adjust the generated YAML
3. ✅ Create or update Dockerfile with dependencies
4. ✅ Test with `docker-compose up`
5. ✅ Transition from systemd to Docker
6. ✅ Update documentation and deployment scripts

For questions, see:
- **DOCKER.md** - Docker setup guide
- **SYSTEMD.md** - Systemd vs Docker comparison
- `resources/systemctl/README.md` - Systemd service management
