# EspoCRM Infrastructure

Docker Compose setup for EspoCRM with MariaDB and Caddy reverse proxy.

## Quick Start

```bash
# 1. Create .env from template and set your passwords
cp compose/.env.example compose/.env
# Edit compose/.env with your passwords

# 2. Start services
make up

# 3. Access EspoCRM at http://localhost
# Login: admin / (your password from .env)
```

## Available Commands

```bash
make setup       # Initialize .env from template
make up          # Start all services
make down        # Stop services
make restart     # Restart services
make logs        # View logs
make backup      # Create database backup
make restore     # Restore from backup
make shell       # Access EspoCRM container
make db-shell    # Access database container
make status      # Check service status
make clean       # Remove all data (DANGEROUS)
```

## Documentation

See [docs/setup.md](docs/setup.md) for detailed setup and usage instructions.

## Security

All secrets are stored in `compose/.env`. Never commit this file.
