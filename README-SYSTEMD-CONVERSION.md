# Quick Start: Converting Systemd Services to Docker

If you have existing systemd services in `resources/systemctl/` and want to run them in Docker instead:

## Step 1: Convert Services

```bash
./systemd-to-docker.sh > converted-services.yml
```

This generates docker-compose service definitions from your systemd files.

## Step 2: Review Output

The script will show you Docker Compose YAML like:

```yaml
services:
  myapp:
    build: .
    command: node server.js
    environment:
      NODE_ENV: production
      PORT: 3000
    restart: always
```

## Step 3: Add to docker-compose.yml

Copy the converted services and add them to your `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Database services (already present)
  postgres:
    # ... existing config

  mongodb:
    # ... existing config

  # Your converted services (add here)
  myapp:
    build: .
    command: node server.js
    # ... rest of converted config
    depends_on:
      - postgres
      - mongodb
```

## Step 4: Test

```bash
# Build and start
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f myapp
```

## Step 5: Transition

Once Docker services are working:

```bash
# Stop old systemd services
sudo systemctl stop myservice
sudo systemctl disable myservice

# Use Docker instead
docker-compose up -d myservice
```

## Full Documentation

- **SYSTEMD-TO-DOCKER.md** - Complete conversion guide with examples
- **SYSTEMD.md** - When to use Docker vs systemd
- **DOCKER.md** - Docker setup and usage guide

## Example Conversion

**Before (systemd):**
```bash
sudo systemctl start myapp
sudo systemctl status myapp
sudo journalctl -u myapp -f
```

**After (Docker):**
```bash
docker-compose up -d myapp
docker-compose ps myapp
docker-compose logs -f myapp
```

## Need Help?

- Run `./systemd-to-docker.sh` to see conversion notes
- Check **SYSTEMD-TO-DOCKER.md** for detailed examples
- Review the mapping table for directive conversions
