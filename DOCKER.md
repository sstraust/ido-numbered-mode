# Docker Setup Guide

This project includes Docker Compose configuration for a full-stack application with MongoDB, PostgreSQL (pgvector), Python, and Node.js.

## Prerequisites

- Docker Engine (20.10.0 or higher)
- Docker Compose (2.0.0 or higher)
- `package.json` and `requirements.txt` files in your project root

## Quick Start

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your desired credentials:**
   - Update passwords for security
   - Adjust ports if needed
   - Configure APP_COMMAND for your startup script

3. **Build and start the services:**
   ```bash
   docker-compose up -d --build
   ```

4. **Verify services are running:**
   ```bash
   docker-compose ps
   ```

## Services

### Application Service
- **Runtime**: Node.js 20 + Python 3.11
- **Default Ports**: 3000 (web), 8000 (API)
- **Features**:
  - Automatic installation of npm packages from `package.json`
  - Automatic installation of Python packages from `requirements.txt`
  - Hot-reload support with volume mounting
  - Auto-connects to PostgreSQL and MongoDB
- **Environment Variables**:
  - `POSTGRES_URL`: Full PostgreSQL connection string
  - `MONGODB_URL`: Full MongoDB connection string
  - `NODE_ENV`: development/production

### PostgreSQL with pgvector
- **Image**: pgvector/pgvector:pg16
- **Default Port**: 5432
- **Database**: mydb (configurable)
- **Extensions**: pgvector is pre-installed

### MongoDB
- **Image**: mongo:7
- **Default Port**: 27017
- **Database**: mydb (configurable)

## Common Commands

### Build and start all services
```bash
docker-compose up -d --build
```

### Start services (without rebuilding)
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f postgres
docker-compose logs -f mongodb
```

### Rebuild app after dependency changes
```bash
docker-compose up -d --build app
```

### Execute commands in app container
```bash
# Run Python script
docker-compose exec app python3 script.py

# Run Node.js script
docker-compose exec app node script.js

# Install additional npm package
docker-compose exec app npm install package-name

# Install additional Python package
docker-compose exec app pip3 install package-name

# Access bash shell
docker-compose exec app bash
```

### Stop and remove all data (⚠️ destructive)
```bash
docker-compose down -v
```

## Connecting to Databases

### PostgreSQL
```bash
# Using psql
docker-compose exec postgres psql -U postgres -d mydb

# Enable pgvector extension
docker-compose exec postgres psql -U postgres -d mydb -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### MongoDB
```bash
# Using mongosh
docker-compose exec mongodb mongosh -u admin -p admin
```

## Connection Strings

### From Your Host Machine

#### PostgreSQL
```
postgresql://postgres:your_password@localhost:5432/mydb
```

#### MongoDB
```
mongodb://admin:your_password@localhost:27017/mydb?authSource=admin
```

### From Within Docker Containers (app service)

The app service automatically has these environment variables set:

#### PostgreSQL
```
POSTGRES_URL=postgresql://postgres:password@postgres:5432/mydb
```

#### MongoDB
```
MONGODB_URL=mongodb://admin:password@mongodb:27017/mydb?authSource=admin
```

Use these in your application code:
```javascript
// Node.js example
const pgUrl = process.env.POSTGRES_URL;
const mongoUrl = process.env.MONGODB_URL;
```

```python
# Python example
import os
pg_url = os.getenv('POSTGRES_URL')
mongo_url = os.getenv('MONGODB_URL')
```

## Initialization Scripts

You can add initialization scripts to automatically set up your databases:

- **PostgreSQL**: Place `.sql` files in `./init-scripts/postgres/`
- **MongoDB**: Place `.js` files in `./init-scripts/mongodb/`

These scripts will run automatically when the containers are first created.

## Backup and Restore

### PostgreSQL Backup
```bash
docker-compose exec postgres pg_dump -U postgres mydb > backup.sql
```

### PostgreSQL Restore
```bash
docker-compose exec -T postgres psql -U postgres mydb < backup.sql
```

### MongoDB Backup
```bash
docker-compose exec mongodb mongodump --username admin --password admin --authenticationDatabase admin --db mydb --out /data/backup
```

### MongoDB Restore
```bash
docker-compose exec mongodb mongorestore --username admin --password admin --authenticationDatabase admin /data/backup
```

## Development Workflow

### Making Code Changes
Your code is mounted as a volume, so changes are reflected immediately:
- Node.js: Use `nodemon` or similar for auto-restart
- Python: Use `watchdog` or similar for auto-reload

### Adding Dependencies

#### Node.js
```bash
# Add to package.json, then rebuild
docker-compose up -d --build app

# OR install directly (temporary, lost on rebuild)
docker-compose exec app npm install package-name
```

#### Python
```bash
# Add to requirements.txt, then rebuild
docker-compose up -d --build app

# OR install directly (temporary, lost on rebuild)
docker-compose exec app pip3 install package-name
```

### Running Scripts

```bash
# Python
docker-compose exec app python3 your_script.py

# Node.js
docker-compose exec app node your_script.js

# NPM scripts
docker-compose exec app npm run test
docker-compose exec app npm run build
```

## Troubleshooting

### Check service health
```bash
docker-compose ps
```

### View service logs
```bash
docker-compose logs app
docker-compose logs postgres
docker-compose logs mongodb
```

### Restart a service
```bash
docker-compose restart app
docker-compose restart postgres
docker-compose restart mongodb
```

### App won't start
1. Check if `package.json` and `requirements.txt` exist
2. View logs: `docker-compose logs app`
3. Rebuild: `docker-compose up -d --build app`

### Dependencies not found
```bash
# Rebuild the app container
docker-compose up -d --build app
```

### Port conflicts
Edit `.env` file and change `APP_PORT`, `API_PORT`, `POSTGRES_PORT`, or `MONGO_PORT`

### Reset everything (⚠️ destroys all data)
```bash
docker-compose down -v
docker-compose up -d --build
```

## Systemd Services

If you need to run additional services on the host machine (outside Docker), see:
- **SYSTEMD.md** - Guide for choosing between Docker and systemd services
- **resources/systemctl/** - Systemd service files and installation scripts

To install systemd services:
```bash
sudo ./install-services.sh
```

## Production Deployment

For production, update your `.env`:
```bash
NODE_ENV=production
APP_COMMAND=npm start
```

Consider:
- Using specific version tags instead of `latest`
- Setting up proper secrets management
- Configuring resource limits
- Setting up health checks and monitoring
- Using a reverse proxy (nginx, traefik)
- Review **SYSTEMD.md** for managing host services
