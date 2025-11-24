# Systemd Services vs Docker Services

You have two options for running application services:

## 🔄 Converting Systemd to Docker

If you have existing systemd services and want to convert them to Docker:

**Automated conversion:**
```bash
# Convert all services
./systemd-to-docker.sh

# Convert specific service
./systemd-to-docker.sh resources/systemctl/myservice.service
```

**See the complete guide:** [SYSTEMD-TO-DOCKER.md](SYSTEMD-TO-DOCKER.md)

---

## Option 1: Systemd Services on Host (Traditional Approach)

Use this if you need services that:
- Need direct host access
- Must run outside of containers
- Integrate with other host services

**Pros:**
- Direct access to host resources
- Traditional Linux service management
- Can use existing systemd tooling

**Cons:**
- Services not containerized
- Harder to reproduce environments
- Manual dependency management

### Setup:

1. Add your `.service` files to `resources/systemctl/`
2. Run installation script:
   ```bash
   sudo ./install-services.sh
   ```

3. Services will be installed and started automatically

See `resources/systemctl/README.md` for details.

## Option 2: Docker Services (Recommended - Cloud Native)

Convert your systemd services to Docker containers in `docker-compose.yml`.

**Pros:**
- All services containerized and reproducible
- Easy to scale and deploy
- Consistent environments (dev/staging/prod)
- No host configuration needed

**Cons:**
- Requires containerizing your applications
- Some limitations on host access

### How to Convert:

For each systemd service, add a service to `docker-compose.yml`:

**Before (systemd service):**
```ini
[Service]
Type=simple
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/node server.js
Environment="PORT=3000"
```

**After (docker-compose service):**
```yaml
services:
  myapp:
    build: ./myapp
    environment:
      PORT: 3000
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - mongodb
    restart: unless-stopped
```

## Recommendation

**For new projects:** Use Docker services (Option 2)
**For existing infrastructure:** Use systemd services (Option 1)

## Hybrid Approach

You can use both:
- **Docker:** Databases (PostgreSQL, MongoDB) and stateless services
- **Systemd:** System daemons, cron jobs, or services requiring host access

## Examples

### Example 1: Web Server + Worker

#### Docker Approach (Recommended):
```yaml
# docker-compose.yml
services:
  web:
    build: .
    command: npm start
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - mongodb

  worker:
    build: .
    command: python worker.py
    depends_on:
      - postgres
      - mongodb
```

#### Systemd Approach:
```bash
# resources/systemctl/web.service
# resources/systemctl/worker.service
sudo ./install-services.sh
```

### Example 2: Nginx Reverse Proxy

#### Docker Approach:
```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
```

#### Systemd Approach:
```bash
# Install nginx on host
sudo apt install nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

## Migration Path

If you have existing systemd services you want to containerize:

1. Keep systemd services running (current state)
2. Add Docker equivalents to docker-compose.yml
3. Test Docker services
4. Gradually switch traffic to Docker services
5. Remove old systemd services when confident

## Quick Reference

### Docker Commands:
```bash
docker-compose up -d          # Start services
docker-compose ps             # Check status
docker-compose logs -f        # View logs
docker-compose restart app    # Restart service
```

### Systemd Commands:
```bash
sudo systemctl start app      # Start service
sudo systemctl status app     # Check status
sudo journalctl -u app -f     # View logs
sudo systemctl restart app    # Restart service
```
