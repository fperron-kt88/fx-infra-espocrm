# EspoCRM Infrastructure

Docker Compose setup for EspoCRM with MariaDB, Caddy reverse proxy, and ansible-vault for secure secrets management.

## Quick Start

```bash
# 1. Install dependencies
poetry install

# 2. Set your passwords (default vault password: setup)
make vault-edit

# 3. Generate environment file
make setup

# 4. Start services
make up

# 5. Access EspoCRM at http://localhost
# Login: admin / (your password from vault)
```

## Available Commands

```bash
make up           # Start all services
make down         # Stop services
make restart      # Restart services
make logs         # View logs
make backup       # Create database backup
make restore      # Restore from backup
make shell        # Access EspoCRM container
make db-shell     # Access database container
make vault-edit   # Edit encrypted secrets
make status       # Check service status
make clean        # Remove all data (DANGEROUS)
```

## Documentation

See [docs/setup.md](docs/setup.md) for detailed setup and usage instructions.

## Security

All secrets are stored in `ansible/group_vars/all/vault.yml` (encrypted with ansible-vault).
Never commit unencrypted passwords or `.env` files.