# Process Management: Standard Tools for Running Services in Docker

This guide compares standard tools for running multiple services/processes in Docker containers.

## Quick Comparison

| Approach | Best For | Complexity | Standard? |
|----------|----------|------------|-----------|
| **Docker Compose** | Multiple containers | Low | ✅ Industry Standard |
| **Supervisord** | Multi-process container | Medium | ✅ Very Common |
| **s6-overlay** | Advanced multi-process | High | ✅ Used by LinuxServer.io |
| **systemd in Docker** | Not recommended | Very High | ❌ Anti-pattern |

## 1. Docker Compose (Recommended - What You Have)

**One service per container** - This is the Docker way and industry standard.

### Advantages
✅ **Most standard approach** - Used by everyone
✅ **Clean separation** - Each service is isolated
✅ **Easy to scale** - Scale individual services
✅ **Better resource control** - Per-service limits
✅ **Simpler debugging** - Clear logs per service

### Setup (Already Done!)
```yaml
# docker-compose.yml
services:
  web:
    command: node server.js
    ports: ["3000:3000"]

  worker:
    command: python worker.py

  api:
    command: uvicorn api:app
    ports: ["8000:8000"]
```

### When to Use
- ✅ New projects (default choice)
- ✅ Microservices architecture
- ✅ Need to scale services independently
- ✅ Want simple, standard approach

---

## 2. Supervisord (Popular for Multi-Process)

**Multiple processes in one container** - Standard tool, battle-tested since 2004.

### Advantages
✅ **Most popular multi-process tool** - Widely used
✅ **Simple configuration** - INI-style config
✅ **Good documentation** - Mature project
✅ **Easy to debug** - Clear status/control commands
✅ **Lightweight** - Minimal overhead

### Automatic Conversion
```bash
# Convert your systemd services to supervisord
./systemd-to-supervisord.sh > supervisord.conf
```

### Setup

**Step 1: Create supervisord.conf**
```ini
[supervisord]
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0

[program:web]
command=node server.js
directory=/app
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0

[program:worker]
command=python3 worker.py
directory=/app
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
```

**Step 2: Update Dockerfile**
```dockerfile
FROM node:20-bullseye

# Install Python and supervisord
RUN apt-get update && apt-get install -y \
    python3 python3-pip supervisor \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN npm install && pip3 install -r requirements.txt

# Copy supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

**Step 3: Use in docker-compose.yml**
```yaml
services:
  app:
    build: .
    # No command needed - supervisord starts everything
    ports:
      - "3000:3000"
      - "8000:8000"
```

### Management
```bash
# View status
docker-compose exec app supervisorctl status

# Restart specific service
docker-compose exec app supervisorctl restart web

# Stop specific service
docker-compose exec app supervisorctl stop worker

# View logs
docker-compose exec app supervisorctl tail -f web
```

### When to Use
- ✅ Legacy app with tightly coupled processes
- ✅ Need multiple processes in one container
- ✅ All processes share same resources
- ✅ Simpler deployment (one container vs many)

---

## 3. s6-overlay (Modern Alternative)

**Advanced process supervision** - Used by LinuxServer.io and other popular images.

### Advantages
✅ **Modern and lightweight** - Better than supervisord
✅ **Proper init system** - Handles zombie processes
✅ **Service dependencies** - Start services in order
✅ **Health checks** - Better process monitoring

### Setup

See `Dockerfile.s6` for example configuration.

### When to Use
- ✅ Need advanced process management
- ✅ Complex service dependencies
- ✅ Building base images for distribution
- ✅ Want most modern solution

---

## Decision Tree

```
Do you have multiple services?
│
├─ YES → Are they tightly coupled?
│        │
│        ├─ NO → Use Docker Compose (separate containers)
│        │       ✅ RECOMMENDED
│        │
│        └─ YES → Do they share state/memory?
│                 │
│                 ├─ NO → Still use Docker Compose
│                 │
│                 └─ YES → Use supervisord or s6-overlay
│                          (Multiple processes in one container)
│
└─ NO → Use simple Dockerfile with single CMD
        (Already standard Docker)
```

## Comparison: Your Systemd Services

### Original (Systemd)
```bash
# Install and run
sudo ./install-services.sh
sudo systemctl start web worker api

# Manage
sudo systemctl status web
sudo systemctl restart worker
sudo journalctl -u api -f
```

### Option 1: Docker Compose (Recommended)
```bash
# Run
docker-compose up -d

# Manage
docker-compose ps
docker-compose restart worker
docker-compose logs -f api
```

**Convert:**
```bash
./systemd-to-docker.sh > docker-services.yml
```

### Option 2: Supervisord
```bash
# Run (all services in one container)
docker-compose up -d app

# Manage
docker-compose exec app supervisorctl status
docker-compose exec app supervisorctl restart worker
docker-compose exec app supervisorctl tail -f api
```

**Convert:**
```bash
./systemd-to-supervisord.sh > supervisord.conf
```

## Real-World Examples

### Example 1: Web App + Background Jobs

**Docker Compose (Recommended):**
```yaml
services:
  web:
    build: .
    command: npm start
    ports: ["3000:3000"]

  worker:
    build: .
    command: python worker.py

  scheduler:
    build: .
    command: node scheduler.js
```

**Supervisord Alternative:**
```ini
[program:web]
command=npm start

[program:worker]
command=python worker.py

[program:scheduler]
command=node scheduler.js
```

### Example 2: Nginx + App Server

**Docker Compose (Better):**
```yaml
services:
  nginx:
    image: nginx:alpine
    ports: ["80:80"]

  app:
    build: .
    command: uvicorn api:app
```

**Supervisord (If You Must):**
```ini
[program:nginx]
command=nginx -g "daemon off;"

[program:app]
command=uvicorn api:app
```

## Performance Comparison

| Metric | Docker Compose | Supervisord | s6-overlay |
|--------|----------------|-------------|------------|
| Startup Time | ~2-5s | ~1s | ~1s |
| Memory Overhead | ~50MB per container | ~10MB | ~5MB |
| Process Isolation | ✅ Full | ⚠️ Shared | ⚠️ Shared |
| Resource Limits | ✅ Per-service | ❌ Shared | ❌ Shared |
| Scaling | ✅ Easy | ❌ Hard | ❌ Hard |

## Migration Path

### From Systemd → Docker Compose

1. **Convert services:**
   ```bash
   ./systemd-to-docker.sh > converted.yml
   ```

2. **Add to docker-compose.yml:**
   ```yaml
   services:
     # ... your converted services
   ```

3. **Test:**
   ```bash
   docker-compose up -d
   docker-compose ps
   ```

4. **Stop systemd services:**
   ```bash
   sudo systemctl stop myservice
   sudo systemctl disable myservice
   ```

### From Systemd → Supervisord

1. **Convert services:**
   ```bash
   ./systemd-to-supervisord.sh > supervisord.conf
   ```

2. **Update Dockerfile** (see Dockerfile.supervisord)

3. **Test:**
   ```bash
   docker-compose build
   docker-compose up -d
   docker-compose exec app supervisorctl status
   ```

## Tools Reference

### Conversion Scripts
```bash
# To Docker Compose (separate containers)
./systemd-to-docker.sh

# To Supervisord (one container)
./systemd-to-supervisord.sh
```

### Example Files
- `Dockerfile.supervisord` - Multi-process Dockerfile with supervisord
- `supervisord.conf` - Example supervisord configuration
- `Dockerfile.s6` - Advanced example with s6-overlay

## Recommendation

**For most projects: Use Docker Compose** (Option 1)
- Industry standard
- Better isolation
- Easier to scale
- Simpler to understand
- Better resource management

**Use Supervisord only if:**
- Legacy app requires multiple processes
- Processes are tightly coupled
- Need to minimize containers
- Specific technical constraints

## Additional Resources

- **Docker Compose**: https://docs.docker.com/compose/
- **Supervisord**: http://supervisord.org/
- **s6-overlay**: https://github.com/just-containers/s6-overlay

## Summary

| Your Need | Use This | Command |
|-----------|----------|---------|
| Standard approach | Docker Compose | `./systemd-to-docker.sh` |
| Multi-process container | Supervisord | `./systemd-to-supervisord.sh` |
| Advanced needs | s6-overlay | See Dockerfile.s6 |
| Quick start | What you have now | Already set up! |

**Bottom line: Docker Compose (what you already have) is the standard.** Supervisord is the standard fallback if you need multiple processes in one container.
