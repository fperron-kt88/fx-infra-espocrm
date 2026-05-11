.PHONY: help up down restart logs shell backup restore vault-edit vault-view status clean

# Default target
help:
	@echo "EspoCRM Docker Compose Management"
	@echo "=================================="
	@echo ""
	@echo "Available targets:"
	@echo "  up          - Start all services"
	@echo "  down        - Stop all services"
	@echo "  restart     - Restart all services"
	@echo "  status      - Check service status"
	@echo "  logs        - View all service logs (follow mode)"
	@echo "  logs-svc    - View logs for specific service (use: make logs-svc SVC=espocrm)"
	@echo "  shell       - Access EspoCRM container shell"
	@echo "  db-shell    - Access MariaDB container shell"
	@echo "  backup      - Create database backup"
	@echo "  restore     - Restore from latest backup (use: make restore FILE=path/to/backup.sql)"
	@echo "  vault-edit  - Edit encrypted vault secrets"
	@echo "  vault-view  - View encrypted vault secrets"
	@echo "  clean       - Remove all containers and volumes (WARNING: destructive)"
	@echo ""
	@echo "Environment setup:"
	@echo "  setup       - Initial setup (generate .env from vault)"

# Directories
COMPOSE_DIR = compose
BACKUP_DIR = backups/data
VAULT_FILE = ansible/group_vars/all/vault.yml

# Use poetry run for ansible commands
ANSIBLE_VAULT = poetry run ansible-vault
DOCKER_COMPOSE = docker compose -f $(COMPOSE_DIR)/docker-compose.yml

# Initial setup
setup:
	@echo "Setting up environment..."
	$(ANSIBLE_VAULT) view $(VAULT_FILE) > /dev/null 2>&1 || (echo "Error: Cannot read vault. Run 'make vault-edit' first to set passwords." && exit 1)
	@echo "Generating .env file from vault..."
	@mkdir -p $(COMPOSE_DIR)/volumes/espocrm $(COMPOSE_DIR)/volumes/caddy-data $(COMPOSE_DIR)/volumes/caddy-config
	@$(ANSIBLE_VAULT) view $(VAULT_FILE) | grep -E '^(mariadb_root_password|mariadb_password|espocrm_admin_password):' | sed 's/: /=/; s/^mariadb_root_password/MARIADB_ROOT_PASSWORD/; s/^mariadb_password/MARIADB_PASSWORD/; s/^espocrm_admin_password/ESPOCRM_ADMIN_PASSWORD/' > $(COMPOSE_DIR)/.env
	@echo 'MARIADB_DATABASE=espocrm' >> $(COMPOSE_DIR)/.env
	@echo 'MARIADB_USER=espocrm' >> $(COMPOSE_DIR)/.env
	@echo 'ESPOCRM_ADMIN_USERNAME=admin' >> $(COMPOSE_DIR)/.env
	@echo 'ESPOCRM_SITE_URL=http://localhost' >> $(COMPOSE_DIR)/.env
	@echo 'ESPOCRM_WEBSOCKET_URL=ws://localhost/ws' >> $(COMPOSE_DIR)/.env
	@echo "Setup complete! .env file created."
	@echo "IMPORTANT: Review and update passwords with 'make vault-edit' before starting services."

# Start services
up: $(COMPOSE_DIR)/.env
	@echo "Starting EspoCRM services..."
	$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "Services starting... wait 30 seconds for database initialization."
	@echo "Access EspoCRM at: http://localhost"
	@echo "Admin login: admin (password in vault)"

# Stop services
down:
	@echo "Stopping EspoCRM services..."
	$(DOCKER_COMPOSE) down

# Restart services
restart: down up

# Check status
status:
	$(DOCKER_COMPOSE) ps

# View logs
logs:
	$(DOCKER_COMPOSE) logs -f

# View logs for specific service
logs-svc:
	$(DOCKER_COMPOSE) logs -f $(SVC)

# Access EspoCRM container shell
shell:
	$(DOCKER_COMPOSE) exec espocrm bash

# Access MariaDB container shell
db-shell:
	$(DOCKER_COMPOSE) exec mariadb mariadb -u root -p

# Create backup
backup:
	@mkdir -p $(BACKUP_DIR)
	@echo "Creating database backup..."
	$(DOCKER_COMPOSE) exec -T mariadb mariadb-dump -u root -p"$$(grep MARIADB_ROOT_PASSWORD $(COMPOSE_DIR)/.env | cut -d= -f2)" espocrm > $(BACKUP_DIR)/espocrm_backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Creating EspoCRM files backup..."
	tar -czf $(BACKUP_DIR)/espocrm_files_$$(date +%Y%m%d_%H%M%S).tar.gz -C $(COMPOSE_DIR)/volumes espocrm/
	@echo "Backup complete!"
	@ls -lh $(BACKUP_DIR)/*.sql $(BACKUP_DIR)/*.tar.gz 2>/dev/null | tail -2

# Restore from backup
restore:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Please specify backup file with FILE=path/to/backup.sql"; \
		echo "Available backups:"; \
		ls -la $(BACKUP_DIR)/*.sql 2>/dev/null || echo "No backups found"; \
		exit 1; \
	fi
	@echo "Restoring from $(FILE)..."
	$(DOCKER_COMPOSE) exec -T mariadb mariadb -u root -p"$$(grep MARIADB_ROOT_PASSWORD $(COMPOSE_DIR)/.env | cut -d= -f2)" espocrm < $(FILE)
	@echo "Restore complete!"

# Edit vault secrets
vault-edit:
	$(ANSIBLE_VAULT) edit $(VAULT_FILE)
	@if [ -f $(COMPOSE_DIR)/.env ]; then \
		echo "Vault updated. Run 'make setup' to regenerate .env file with new values."; \
	fi

# View vault secrets
vault-view:
	$(ANSIBLE_VAULT) view $(VAULT_FILE)

# Re-encrypt vault with different password
vault-rekey:
	$(ANSIBLE_VAULT) rekey $(VAULT_FILE)

# Clean up (destructive)
clean: down
	@echo "WARNING: This will remove all containers, volumes, and data!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	$(DOCKER_COMPOSE) down -v
	@echo "Cleanup complete."

# Check if .env exists
$(COMPOSE_DIR)/.env:
	@echo "Error: .env file not found. Run 'make setup' first."
	@exit 1