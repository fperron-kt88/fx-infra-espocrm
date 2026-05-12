.PHONY: help setup fix-perms up down restart status logs logs-svc shell db-shell backup restore clean

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

COMPOSE_DIR = compose
BACKUP_DIR = backups/data
DOCKER_COMPOSE = docker compose -f $(COMPOSE_DIR)/docker-compose.yml

# ═══════════════════════════════════════════════════════════════════════════════
# HELP & SETUP
# ═══════════════════════════════════════════════════════════════════════════════

help: ## Display this help message with colorized output
	@echo ""
	@echo "\033[1;36m╔════════════════════════════════════════════════════════════════════════╗\033[0m"
	@echo "\033[1;36m║           \033[1;33mEspoCRM Docker Compose Management\033[1;36m                           ║\033[0m"
	@echo "\033[1;36m╚════════════════════════════════════════════════════════════════════════╝\033[0m"
	@echo ""
	@echo "\033[1;35m🔐 Setup:\033[0m"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(setup|fix-perms)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "\033[1;35m🚀 Service Management:\033[0m"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(^up:|^down:|^restart:|^status:)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "\033[1;35m🔍 Debugging & Access:\033[0m"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(logs|shell)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[33m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "\033[1;35m💾 Data Management:\033[0m"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(backup|restore|clean)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[31m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

setup: ## Initialize or regenerate .env from template
	@if [ ! -f $(COMPOSE_DIR)/.env ]; then \
		cp $(COMPOSE_DIR)/.env.example $(COMPOSE_DIR)/.env; \
		echo "Created compose/.env from template."; \
	else \
		echo "compose/.env already exists."; \
	fi
	@echo "IMPORTANT: Edit compose/.env to set your passwords before starting services."

$(COMPOSE_DIR)/.env: $(COMPOSE_DIR)/.env.example
	@cp $(COMPOSE_DIR)/.env.example $(COMPOSE_DIR)/.env
	@echo "Created compose/.env from template."
	@echo "Edit compose/.env to set your passwords before starting services."
	@echo "Run 'make up' again when ready."
	@exit 1

fix-perms: ## Fix permissions on volumes/ (Docker containers create files as root)
	@echo "Fixing permissions on volumes/..."
	@sudo chown $(shell whoami):$(shell whoami) volumes/
	@sudo chmod 755 volumes/caddy-config/caddy volumes/caddy-data/caddy volumes/caddy-data/caddy/locks 2>/dev/null || true
	@sudo chmod 644 volumes/caddy-data/access.log 2>/dev/null || true
	@echo "Done."

# ═══════════════════════════════════════════════════════════════════════════════
# SERVICE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

up: $(COMPOSE_DIR)/.env ## Start all EspoCRM services
	@echo "Starting EspoCRM services..."
	$(DOCKER_COMPOSE) up -d
	@echo ""
	@echo "Services starting... wait 30 seconds for database initialization."
	@echo "Access EspoCRM at: http://localhost"
	@echo "Admin login: admin (password in .env)"

down: ## Stop all services
	@echo "Stopping EspoCRM services..."
	$(DOCKER_COMPOSE) down

restart: down up ## Restart all services (down + up)

status: ## Check service status
	$(DOCKER_COMPOSE) ps

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUGGING & ACCESS
# ═══════════════════════════════════════════════════════════════════════════════

logs: ## View all service logs (follow mode)
	$(DOCKER_COMPOSE) logs -f

logs-svc: ## View logs for specific service (usage: make logs-svc SVC=espocrm)
	$(DOCKER_COMPOSE) logs -f $(SVC)

shell: ## Access EspoCRM container shell
	$(DOCKER_COMPOSE) exec espocrm bash

db-shell: ## Access MariaDB container shell (prompts for password)
	$(DOCKER_COMPOSE) exec mariadb mariadb -u root -p

# ═══════════════════════════════════════════════════════════════════════════════
# DATA MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

backup: ## Create database and files backup with timestamp
	@mkdir -p $(BACKUP_DIR)
	@echo "Creating database backup..."
	$(DOCKER_COMPOSE) exec -T mariadb mariadb-dump -u root -p"$$(grep MARIADB_ROOT_PASSWORD $(COMPOSE_DIR)/.env | cut -d= -f2-)" espocrm > $(BACKUP_DIR)/espocrm_backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Creating EspoCRM files backup..."
	tar -czf $(BACKUP_DIR)/espocrm_files_$$(date +%Y%m%d_%H%M%S).tar.gz -C volumes espocrm/
	@echo "Backup complete!"
	@ls -lh $(BACKUP_DIR)/*.sql $(BACKUP_DIR)/*.tar.gz 2>/dev/null | tail -2

restore: ## Restore from backup (usage: make restore FILE=backups/data/backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "Error: Please specify backup file with FILE=path/to/backup.sql"; \
		echo "Available backups:"; \
		ls -la $(BACKUP_DIR)/*.sql 2>/dev/null || echo "No backups found"; \
		exit 1; \
	fi
	@echo "Restoring from $(FILE)..."
	$(DOCKER_COMPOSE) exec -T mariadb mariadb -u root -p"$$(grep MARIADB_ROOT_PASSWORD $(COMPOSE_DIR)/.env | cut -d= -f2-)" espocrm < $(FILE)
	@echo "Restore complete!"

clean: down ## ⚠️  Remove all containers and volumes (DESTRUCTIVE - asks for confirmation)
	@echo "WARNING: This will remove all containers, volumes, and data!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	$(DOCKER_COMPOSE) down -v
	@echo "Cleanup complete."
