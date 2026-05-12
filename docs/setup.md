# EspoCRM Docker Compose Setup

Complete Docker Compose setup for EspoCRM with MariaDB and Caddy reverse proxy.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Caddy     │────▶│  EspoCRM     │────▶│   MariaDB   │
│   (:80)     │     │   (Main)     │     │  (Database) │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                           ▼
                     ┌──────────────┐
                     │ EspoCRM      │
                     │  Daemon      │
                     │  (Jobs)      │
                     └──────────────┘
                           │
                           ▼
                     ┌──────────────┐
                     │ EspoCRM      │
                     │  WebSocket   │
                     │ (Real-time)  │
                     └──────────────┘
```

## Requirements

- Docker & Docker Compose
- Make

## Quick Start

### 1. Configure Secrets

Copy the environment template and set your passwords:

```bash
cp compose/.env.example compose/.env
```

Edit `compose/.env` and set these values:
- `MARIADB_ROOT_PASSWORD` - MariaDB root password
- `MARIADB_PASSWORD` - MariaDB application user password
- `ESPOCRM_ADMIN_PASSWORD` - EspoCRM admin user password

### 2. Start Services

```bash
make up
```

Wait ~30 seconds for database initialization, then access:
- **EspoCRM:** http://localhost
- **Login:** admin / (password from .env)

## Daily Operations

### View Logs
```bash
make logs              # All services
make logs-svc SVC=espocrm  # Specific service
```

### Access Containers
```bash
make shell             # EspoCRM container
make db-shell          # MariaDB container
```

### Create Backup
```bash
make backup
```
Backups are stored in `backups/data/` with timestamps.

### Restore from Backup
```bash
make restore FILE=backups/data/espocrm_backup_YYYYMMDD_HHMMSS.sql
```

### Update Secrets
```bash
# Edit compose/.env with new passwords
make restart           # Restart with new secrets
```

### Stop Services
```bash
make down              # Stop containers (keep data)
make clean             # Stop and remove all data (DANGEROUS)
```

## Project Structure

```
.
├── Makefile                 # Common operations
├── compose/
│   ├── docker-compose.yml   # Service definitions
│   ├── caddy/
│   │   └── Caddyfile        # Reverse proxy config
│   ├── .env.example         # Environment template
│   ├── .env                 # Your secrets (gitignored)
│   └── volumes/             # Persistent data (gitignored)
├── backups/
│   └── data/                # Database backups (gitignored)
└── docs/
    └── setup.md             # This file
```

## Troubleshooting

### Services won't start
```bash
make status              # Check container status
make logs                # View error messages
```

### Database connection issues
```bash
make db-shell            # Test database connection
# Inside container:
mariadb -u espocrm -p -D espocrm
```

### Reset everything (DESTRUCTIVE)
```bash
make clean               # Remove all containers and volumes
make up                  # Start fresh
```

## EspoCRM Configuration

After initial setup, you can configure EspoCRM through the web UI:
- Go to **Administration** → **Settings**
- Configure email, branding, users, etc.

## Updating EspoCRM

```bash
make down
make up
```

## Support

- [EspoCRM Documentation](https://docs.espocrm.com/)
- [EspoCRM Docker Hub](https://hub.docker.com/r/espocrm/espocrm)
