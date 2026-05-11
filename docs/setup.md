# EspoCRM Docker Compose Setup

Complete Docker Compose setup for EspoCRM with MariaDB, Caddy reverse proxy, and ansible-vault for secrets management.

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
- Poetry (Python dependency management)
- Make

## Quick Start

### 1. Install Dependencies

```bash
# Install ansible via poetry
poetry install
```

### 2. Configure Secrets

Edit the encrypted vault file to set your passwords:

```bash
make vault-edit
```

**Default vault password:** `setup` (change this after first setup!)

The vault contains:
- `mariadb_root_password` - MariaDB root password
- `mariadb_password` - MariaDB application user password  
- `espocrm_admin_password` - EspoCRM admin user password

### 3. Initial Setup

Generate the `.env` file from vault secrets:

```bash
make setup
```

### 4. Start Services

```bash
make up
```

Wait ~30 seconds for database initialization, then access:
- **EspoCRM:** http://localhost
- **Login:** admin / (password from vault)

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
make vault-edit        # Edit passwords
make setup             # Regenerate .env
make restart           # Restart with new secrets
```

### Stop Services
```bash
make down              # Stop containers (keep data)
make clean             # Stop and remove all data (DANGEROUS)
```

## Changing Vault Password

To change the ansible-vault encryption password:

```bash
make vault-rekey
```

You'll be prompted for the old password, then the new one.

## Project Structure

```
.
├── Makefile                 # Common operations
├── compose/
│   ├── docker-compose.yml   # Service definitions
│   ├── caddy/
│   │   └── Caddyfile        # Reverse proxy config
│   ├── .env.example         # Environment template
│   └── volumes/             # Persistent data (gitignored)
├── ansible/
│   ├── ansible.cfg          # Ansible configuration
│   ├── inventory            # Localhost inventory
│   └── group_vars/
│       └── all/
│           ├── vars.yml     # Non-sensitive variables
│           └── vault.yml    # ENCRYPTED secrets
├── backups/
│   └── data/                # Database backups (gitignored)
└── docs/
    └── setup.md             # This file
```

## Security Notes

- **Never commit** `.env` files or unencrypted passwords
- The vault password is entered manually (no password file by default)
- All sensitive data is stored in `ansible/group_vars/all/vault.yml` (encrypted)
- Volume data in `compose/volumes/` is gitignored
- Backups in `backups/data/` are gitignored

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
make setup               # Re-initialize
make up                  # Start fresh
```

## EspoCRM Configuration

After initial setup, you can configure EspoCRM through the web UI:
- Go to **Administration** → **Settings**
- Configure email, branding, users, etc.

## Updating EspoCRM

```bash
cd compose/
docker compose pull
docker compose up -d
```

Or simply:
```bash
make down
make up
```

## Support

- [EspoCRM Documentation](https://docs.espocrm.com/)
- [EspoCRM Docker Hub](https://hub.docker.com/r/espocrm/espocrm)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html)