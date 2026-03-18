.PHONY: help up down start stop restart logs ps shell mysql mysql-user backup restore clean init status version import export disk-usage stats list-dbs create-db drop-db

# Variables - Gunakan docker compose (plugin)
DC = docker compose
SERVICE = mysql
YELLOW = \033[1;33m
GREEN = \033[1;32m
RED = \033[1;31m
BLUE = \033[1;34m
CYAN = \033[1;36m
NC = \033[0m # No Color

# Default target
help:
	@echo "$(CYAN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║        MySQL Official Docker Management Commands           ║$(NC)"
	@echo "$(CYAN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)CONTAINER MANAGEMENT:$(NC)"
	@echo "  $(GREEN)make up$(NC)         - Start MySQL container (detached mode)"
	@echo "  $(GREEN)make down$(NC)       - Stop and remove MySQL container"
	@echo "  $(GREEN)make start$(NC)      - Start existing MySQL container"
	@echo "  $(GREEN)make stop$(NC)       - Stop MySQL container"
	@echo "  $(GREEN)make restart$(NC)    - Restart MySQL container"
	@echo "  $(GREEN)make logs$(NC)       - Show MySQL logs (follow mode)"
	@echo "  $(GREEN)make ps$(NC)         - Show container status"
	@echo "  $(GREEN)make status$(NC)     - Show MySQL server status"
	@echo ""
	@echo "$(YELLOW)DATABASE ACCESS:$(NC)"
	@echo "  $(GREEN)make shell$(NC)      - Open bash shell in MySQL container"
	@echo "  $(GREEN)make mysql$(NC)      - Open MySQL CLI as root user"
	@echo "  $(GREEN)make mysql-user$(NC) - Open MySQL CLI as application user"
	@echo "  $(GREEN)make version$(NC)    - Show MySQL version"
	@echo ""
	@echo "$(YELLOW)BACKUP & RESTORE:$(NC)"
	@echo "  $(GREEN)make backup$(NC)     - Backup all databases to ./backups/"
	@echo "  $(GREEN)make restore$(NC)    - Restore database from backup file"
	@echo "    $(BLUE)Usage:$(NC) make restore file=backups/backup.sql"
	@echo "  $(GREEN)make export$(NC)     - Export specific database"
	@echo "    $(BLUE)Usage:$(NC) make export db=database_name"
	@echo "  $(GREEN)make import$(NC)     - Import SQL file into database"
	@echo "    $(BLUE)Usage:$(NC) make import file=path/to/file.sql"
	@echo ""
	@echo "$(YELLOW)DATABASE MANAGEMENT:$(NC)"
	@echo "  $(GREEN)make list-dbs$(NC)   - List all databases"
	@echo "  $(GREEN)make create-db$(NC)  - Create new database"
	@echo "    $(BLUE)Usage:$(NC) make create-db name=new_database"
	@echo "  $(GREEN)make drop-db$(NC)    - Drop database (careful!)"
	@echo "    $(BLUE)Usage:$(NC) make drop-db name=database_to_drop"
	@echo ""
	@echo "$(YELLOW)INITIALIZATION & MAINTENANCE:$(NC)"
	@echo "  $(GREEN)make init$(NC)       - Create sample database initialization script"
	@echo "  $(GREEN)make clean$(NC)      - $(RED)WARNING:$(NC) Remove container and all data"
	@echo "  $(GREEN)make disk-usage$(NC) - Show disk usage of data directories"
	@echo "  $(GREEN)make stats$(NC)      - Show container resource usage"
	@echo "  $(GREEN)make startup$(NC)    - Run interactive startup script"
	@echo "  $(GREEN)make info$(NC)       - Show connection information"
	@echo ""
	@echo "$(YELLOW)EXAMPLES:$(NC)"
	@echo "  $(BLUE)# Start MySQL$(NC)"
	@echo "  make up"
	@echo ""
	@echo "  $(BLUE)# Connect to MySQL as root$(NC)"
	@echo "  make mysql"
	@echo ""
	@echo "  $(BLUE)# Backup all databases$(NC)"
	@echo "  make backup"
	@echo ""
	@echo "  $(BLUE)# Import data$(NC)"
	@echo "  make import file=./my_data.sql"
	@echo ""
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"

# Start services
up:
	@echo "$(GREEN)Starting MySQL Official container...$(NC)"
	$(DC) up -d
	@echo "$(GREEN)✓ MySQL is starting...$(NC)"
	@echo "$(BLUE)Run 'make logs' to see startup progress$(NC)"
	@echo "$(BLUE)Run 'make mysql' to connect when ready$(NC)"

# Stop and remove containers
down:
	@echo "$(YELLOW)Stopping and removing MySQL container...$(NC)"
	$(DC) down
	@echo "$(GREEN)✓ Container stopped and removed$(NC)"

# Start existing containers
start:
	@echo "$(GREEN)Starting existing MySQL container...$(NC)"
	$(DC) start
	@echo "$(GREEN)✓ Container started$(NC)"

# Stop containers
stop:
	@echo "$(YELLOW)Stopping MySQL container...$(NC)"
	$(DC) stop
	@echo "$(GREEN)✓ Container stopped$(NC)"

# Restart containers
restart:
	@echo "$(YELLOW)Restarting MySQL container...$(NC)"
	$(DC) restart
	@echo "$(GREEN)✓ Container restarted$(NC)"
	@sleep 3
	@$(DC) ps

# Show logs
logs:
	@echo "$(BLUE)Showing MySQL logs (Ctrl+C to exit):$(NC)"
	$(DC) logs -f $(SERVICE)

# Show container status
ps:
	@echo "$(BLUE)Container status:$(NC)"
	$(DC) ps

# Open bash shell in container
shell:
	@echo "$(BLUE)Opening bash shell in MySQL container...$(NC)"
	$(DC) exec $(SERVICE) bash

# Open MySQL CLI as root
mysql:
	@echo "$(BLUE)Connecting to MySQL as root...$(NC)"
	@$(DC) exec $(SERVICE) mysql -u root -p${MYSQL_ROOT_PASSWORD}

# Open MySQL CLI as application user
mysql-user:
	@echo "$(BLUE)Connecting to MySQL as ${MYSQL_USER}...$(NC)"
	@$(DC) exec $(SERVICE) mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

# Backup all databases
backup:
	@echo "$(BLUE)Starting backup...$(NC)"
	@mkdir -p backups
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	BACKUP_FILE=backups/mysql_backup_$$TIMESTAMP.sql; \
	echo "$(YELLOW)Creating backup: $(CYAN)$$BACKUP_FILE$(NC)"; \
	$(DC) exec $(SERVICE) mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --all-databases --events --routines --triggers > $$BACKUP_FILE; \
	if [ $$? -eq 0 ]; then \
		echo "$(GREEN)✓ Backup completed successfully: $(CYAN)$$BACKUP_FILE$(NC)"; \
		echo "$(BLUE)Backup size:$(NC) $$(du -h $$BACKUP_FILE | cut -f1)"; \
	else \
		echo "$(RED)✗ Backup failed$(NC)"; \
		exit 1; \
	fi

# Restore database from backup file
restore:
	@if [ -z "$(file)" ]; then \
		echo "$(RED)✗ Error: Please specify backup file$(NC)"; \
		echo "$(BLUE)Usage:$(NC) make restore file=backups/your_backup.sql"; \
		exit 1; \
	fi
	@if [ ! -f "$(file)" ]; then \
		echo "$(RED)✗ Error: File '$(file)' not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)WARNING: This will overwrite existing data!$(NC)"
	@read -p "Are you sure you want to restore from $(file)? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "$(BLUE)Restoring from: $(CYAN)$(file)$(NC)"; \
		cat $(file) | $(DC) exec -T $(SERVICE) mysql -u root -p${MYSQL_ROOT_PASSWORD}; \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ Restore completed successfully$(NC)"; \
		else \
			echo "$(RED)✗ Restore failed$(NC)"; \
			exit 1; \
		fi \
	else \
		echo "$(YELLOW)Restore cancelled$(NC)"; \
	fi

# Clean everything (CAUTION: removes data!)
clean:
	@echo "$(RED)╔════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(RED)║                    DANGER ZONE                         ║$(NC)"
	@echo "$(RED)╚════════════════════════════════════════════════════════╝$(NC)"
	@echo "$(YELLOW)This will:$(NC)"
	@echo "  - Stop and remove MySQL container"
	@echo "  - Delete all MySQL data in ./mysql_data/"
	@echo "  - Remove all backups in ./backups/"
	@echo "  - Remove all exports in ./exports/"
	@echo ""
	@read -p "Are you ABSOLUTELY SURE? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(RED)Performing clean up...$(NC)"; \
		$(DC) down -v; \
		rm -rf mysql_data backups exports; \
		mkdir -p mysql_data backups exports; \
		echo "$(GREEN)✓ Cleanup completed$(NC)"; \
	else \
		echo "$(GREEN)Cleanup cancelled$(NC)"; \
	fi

# Initialize with sample database
init:
	@echo "$(BLUE)Creating sample database initialization script...$(NC)"
	@mkdir -p init-scripts
	@if [ -f "init-scripts/01-sample-db.sql" ]; then \
		echo "$(YELLOW)Sample script already exists. Overwrite?$(NC)"; \
		read -p "Overwrite? (y/N): " overwrite; \
		if [ "$$overwrite" != "y" ] && [ "$$overwrite" != "Y" ]; then \
			echo "$(GREEN)Initialization cancelled$(NC)"; \
			exit 0; \
		fi \
	fi
	@echo "-- Sample database initialization for MySQL Official" > init-scripts/01-sample-db.sql
	@echo "USE \$${MYSQL_DATABASE};" >> init-scripts/01-sample-db.sql
	@echo "" >> init-scripts/01-sample-db.sql
	@echo "-- Create users table" >> init-scripts/01-sample-db.sql
	@echo "CREATE TABLE IF NOT EXISTS users (" >> init-scripts/01-sample-db.sql
	@echo "    id INT AUTO_INCREMENT PRIMARY KEY," >> init-scripts/01-sample-db.sql
	@echo "    username VARCHAR(50) UNIQUE NOT NULL," >> init-scripts/01-sample-db.sql
	@echo "    email VARCHAR(100) UNIQUE NOT NULL," >> init-scripts/01-sample-db.sql
	@echo "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," >> init-scripts/01-sample-db.sql
	@echo "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" >> init-scripts/01-sample-db.sql
	@echo ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" >> init-scripts/01-sample-db.sql
	@echo "" >> init-scripts/01-sample-db.sql
	@echo "-- Create products table" >> init-scripts/01-sample-db.sql
	@echo "CREATE TABLE IF NOT EXISTS products (" >> init-scripts/01-sample-db.sql
	@echo "    id INT AUTO_INCREMENT PRIMARY KEY," >> init-scripts/01-sample-db.sql
	@echo "    name VARCHAR(100) NOT NULL," >> init-scripts/01-sample-db.sql
	@echo "    description TEXT," >> init-scripts/01-sample-db.sql
	@echo "    price DECIMAL(10,2) NOT NULL," >> init-scripts/01-sample-db.sql
	@echo "    stock INT DEFAULT 0," >> init-scripts/01-sample-db.sql
	@echo "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," >> init-scripts/01-sample-db.sql
	@echo "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," >> init-scripts/01-sample-db.sql
	@echo "    INDEX idx_price (price)," >> init-scripts/01-sample-db.sql
	@echo "    INDEX idx_stock (stock)" >> init-scripts/01-sample-db.sql
	@echo ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" >> init-scripts/01-sample-db.sql
	@echo "" >> init-scripts/01-sample-db.sql
	@echo "-- Create orders table" >> init-scripts/01-sample-db.sql
	@echo "CREATE TABLE IF NOT EXISTS orders (" >> init-scripts/01-sample-db.sql
	@echo "    id INT AUTO_INCREMENT PRIMARY KEY," >> init-scripts/01-sample-db.sql
	@echo "    user_id INT NOT NULL," >> init-scripts/01-sample-db.sql
	@echo "    total_amount DECIMAL(10,2) NOT NULL," >> init-scripts/01-sample-db.sql
	@echo "    status ENUM('pending', 'processing', 'completed', 'cancelled') DEFAULT 'pending'," >> init-scripts/01-sample-db.sql
	@echo "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," >> init-scripts/01-sample-db.sql
	@echo "    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE," >> init-scripts/01-sample-db.sql
	@echo "    INDEX idx_status (status)" >> init-scripts/01-sample-db.sql
	@echo ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;" >> init-scripts/01-sample-db.sql
	@echo "" >> init-scripts/01-sample-db.sql
	@echo "-- Insert sample data" >> init-scripts/01-sample-db.sql
	@echo "INSERT INTO users (username, email) VALUES" >> init-scripts/01-sample-db.sql
	@echo "    ('admin', 'admin@example.com')," >> init-scripts/01-sample-db.sql
	@echo "    ('john_doe', 'john@example.com')," >> init-scripts/01-sample-db.sql
	@echo "    ('jane_smith', 'jane@example.com')," >> init-scripts/01-sample-db.sql
	@echo "    ('bob_wilson', 'bob@example.com');" >> init-scripts/01-sample-db.sql
	@echo "" >> init-scripts/01-sample-db.sql
	@echo "INSERT INTO products (name, description, price, stock) VALUES" >> init-scripts/01-sample-db.sql
	@echo "    ('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 50)," >> init-scripts/01-sample-db.sql
	@echo "    ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 200)," >> init-scripts/01-sample-db.sql
	@echo "    ('Mechanical Keyboard', 'RGB mechanical keyboard', 89.99, 75)," >> init-scripts/01-sample-db.sql
	@echo "    ('4K Monitor', '27-inch 4K UHD monitor', 399.99, 30)," >> init-scripts/01-sample-db.sql
	@echo "    ('USB-C Hub', '7-in-1 USB-C hub', 49.99, 150);" >> init-scripts/01-sample-db.sql
	@echo "" >> init-scripts/01-sample-db.sql
	@echo "INSERT INTO orders (user_id, total_amount, status) VALUES" >> init-scripts/01-sample-db.sql
	@echo "    (1, 1329.98, 'completed')," >> init-scripts/01-sample-db.sql
	@echo "    (2, 89.99, 'processing')," >> init-scripts/01-sample-db.sql
	@echo "    (3, 449.98, 'pending')," >> init-scripts/01-sample-db.sql
	@echo "    (4, 79.98, 'completed');" >> init-scripts/01-sample-db.sql
	@echo "$(GREEN)✓ Sample initialization script created at $(CYAN)init-scripts/01-sample-db.sql$(NC)"
	@echo "$(BLUE)Run 'make up' to initialize database with sample data$(NC)"

# Check MySQL status
status:
	@echo "$(BLUE)MySQL Server Status:$(NC)"
	@$(DC) exec $(SERVICE) mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} status

# Show MySQL version
version:
	@echo "$(BLUE)MySQL Version:$(NC)"
	@$(DC) exec $(SERVICE) mysql --version

# Import SQL file
import:
	@if [ -z "$(file)" ]; then \
		echo "$(RED)✗ Error: Please specify SQL file$(NC)"; \
		echo "$(BLUE)Usage:$(NC) make import file=path/to/file.sql"; \
		exit 1; \
	fi
	@if [ ! -f "$(file)" ]; then \
		echo "$(RED)✗ Error: File '$(file)' not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Importing $(CYAN)$(file)$(NC) into database $(CYAN)${MYSQL_DATABASE}$(NC)..."
	@cat $(file) | $(DC) exec -T $(SERVICE) mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}
	@if [ $$? -eq 0 ]; then \
		echo "$(GREEN)✓ Import completed successfully$(NC)"; \
	else \
		echo "$(RED)✗ Import failed$(NC)"; \
		exit 1; \
	fi

# Export specific database
export:
	@if [ -z "$(db)" ]; then \
		echo "$(RED)✗ Error: Please specify database name$(NC)"; \
		echo "$(BLUE)Usage:$(NC) make export db=database_name"; \
		exit 1; \
	fi
	@mkdir -p exports
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	EXPORT_FILE=exports/$(db)_$$TIMESTAMP.sql; \
	echo "$(BLUE)Exporting database '$(CYAN)$(db)$(BLUE)' to $(CYAN)$$EXPORT_FILE$(NC)"; \
	$(DC) exec $(SERVICE) mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --events --routines --triggers $(db) > $$EXPORT_FILE; \
	if [ $$? -eq 0 ]; then \
		echo "$(GREEN)✓ Export completed: $(CYAN)$$EXPORT_FILE$(NC)"; \
		echo "$(BLUE)Export size:$(NC) $$(du -h $$EXPORT_FILE | cut -f1)"; \
	else \
		echo "$(RED)✗ Export failed$(NC)"; \
		exit 1; \
	fi

# Show disk usage
disk-usage:
	@echo "$(BLUE)Disk Usage:$(NC)"
	@echo "$(YELLOW)MySQL Data:$(NC)"
	@du -sh mysql_data 2>/dev/null || echo "No data yet"
	@echo "$(YELLOW)Backups:$(NC)"
	@du -sh backups 2>/dev/null || echo "No backups yet"
	@echo "$(YELLOW)Exports:$(NC)"
	@du -sh exports 2>/dev/null || echo "No exports yet"

# Show container resource usage
stats:
	@echo "$(BLUE)Container Resource Usage:$(NC)"
	@docker stats --no-stream $(shell $(DC) ps -q $(SERVICE) 2>/dev/null) 2>/dev/null || echo "Container not running"

# List all databases
list-dbs:
	@echo "$(BLUE)Available Databases:$(NC)"
	@$(DC) exec $(SERVICE) mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;" 2>/dev/null | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" || echo "Container not running or connection failed"

# Create new database
create-db:
	@if [ -z "$(name)" ]; then \
		echo "$(RED)✗ Error: Please specify database name$(NC)"; \
		echo "$(BLUE)Usage:$(NC) make create-db name=new_database"; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating database '$(CYAN)$(name)$(BLUE)'...$(NC)"
	@$(DC) exec $(SERVICE) mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS \`$(name)\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
	@if [ $$? -eq 0 ]; then \
		echo "$(GREEN)✓ Database '$(name)' created$(NC)"; \
	else \
		echo "$(RED)✗ Failed to create database (container not running or connection failed)$(NC)"; \
	fi

# Drop database (careful!)
drop-db:
	@if [ -z "$(name)" ]; then \
		echo "$(RED)✗ Error: Please specify database name$(NC)"; \
		echo "$(BLUE)Usage:$(NC) make drop-db name=database_to_drop"; \
		exit 1; \
	fi
	@echo "$(RED)WARNING: This will permanently delete database '$(name)'!$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(RED)Dropping database '$(name)'...$(NC)"; \
		$(DC) exec $(SERVICE) mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "DROP DATABASE \`$(name)\`;" 2>/dev/null; \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ Database '$(name)' dropped$(NC)"; \
		else \
			echo "$(RED)✗ Failed to drop database (container not running or database doesn't exist)$(NC)"; \
		fi \
	else \
		echo "$(GREEN)Operation cancelled$(NC)"; \
	fi

# Startup script
startup:
	@echo "$(BLUE)Running startup script...$(NC)"
	@chmod +x ./start.sh
	@./start.sh

# Show connection info
info:
	@echo "$(CYAN)MySQL Connection Information:$(NC)"
	@source .env && \
	echo "Host: localhost" && \
	echo "Port: $${MYSQL_PORT:-3306}" && \
	echo "Database: $${MYSQL_DATABASE}" && \
	echo "Root Password: $${MYSQL_ROOT_PASSWORD}" && \
	echo "User: $${MYSQL_USER}" && \
	echo "User Password: $${MYSQL_PASSWORD}" && \
	echo "MySQL Version: $${MYSQL_VERSION:-8.0}"
