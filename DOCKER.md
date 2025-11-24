# Docker Setup Guide

This project includes Docker Compose configuration for MongoDB and PostgreSQL with pgvector extension.

## Prerequisites

- Docker Engine (20.10.0 or higher)
- Docker Compose (2.0.0 or higher)

## Quick Start

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your desired credentials:**
   - Update passwords for security
   - Adjust ports if needed

3. **Start the services:**
   ```bash
   docker-compose up -d
   ```

4. **Verify services are running:**
   ```bash
   docker-compose ps
   ```

## Services

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

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f
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

### PostgreSQL
```
postgresql://postgres:your_password@localhost:5432/mydb
```

### MongoDB
```
mongodb://admin:your_password@localhost:27017/mydb?authSource=admin
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

## Troubleshooting

### Check service health
```bash
docker-compose ps
```

### View service logs
```bash
docker-compose logs postgres
docker-compose logs mongodb
```

### Restart a service
```bash
docker-compose restart postgres
docker-compose restart mongodb
```

### Reset everything (⚠️ destroys all data)
```bash
docker-compose down -v
docker-compose up -d
```
