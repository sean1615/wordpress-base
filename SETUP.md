# Local Development Setup

This document provides instructions for setting up a local development environment with the WordPress Nginx Docker image. These files are not included in the repository but can be created locally.

## Docker Compose Setup

Create a `docker-compose.yml` file with the following content:

```yaml
version: '3.8'

services:
  wordpress:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_TABLE_PREFIX: wp_
      WORDPRESS_DEBUG: "true"  # Set to "false" in production
    volumes:
      - wp_content:/var/www/html/wp-content
    depends_on:
      - db
      - redis

  db:
    image: mariadb:12.0
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
      MYSQL_ROOT_PASSWORD: root_password
    volumes:
      - db_data:/var/lib/mysql
      - ./mariadb.cnf:/etc/mysql/conf.d/custom.cnf:ro

  redis:
    image: redis:latest
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  wp_content:
    driver: local
  db_data:
    driver: local
  redis_data:
    driver: local
```

## Database Configuration

Create a `mariadb.cnf` file for optimized MySQL settings:

```ini
[mysqld]
# Basic Settings
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
max_connections = 100
table_open_cache = 400
thread_cache_size = 8

# InnoDB Settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Character Settings
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# WordPress recommended settings
max_allowed_packet = 64M
wait_timeout = 300
interactive_timeout = 300
```

## Production Setup

For production environments, create a `docker-compose.production.yml` file:

```yaml
version: '3.8'

services:
  wordpress:
    image: your-org/wordpress-nginx:latest
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD:-wordpress_password}
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_TABLE_PREFIX: wp_
      WORDPRESS_DEBUG: "false"
    volumes:
      - wp_content:/var/www/html/wp-content
    depends_on:
      - db
      - redis
    networks:
      - wordpress_network

  db:
    image: mariadb:12.0
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: ${WORDPRESS_DB_PASSWORD:-wordpress_password}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root_password}
    volumes:
      - db_data:/var/lib/mysql
      - ./mariadb.cnf:/etc/mysql/conf.d/custom.cnf:ro
    networks:
      - wordpress_network

  redis:
    image: redis:latest
    restart: unless-stopped
    volumes:
      - redis_data:/data
    networks:
      - wordpress_network

volumes:
  wp_content:
  db_data:
  redis_data:

networks:
  wordpress_network:
    driver: bridge
```

## Environment Variables

Create a `.env` file for your environment variables (don't commit this to git):

```
WORDPRESS_DB_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=another_secure_password
```

## Starting the Environment

```bash
# For development
docker compose up -d

# For production
docker compose -f docker-compose.production.yml up -d
```

## Debugging

If you encounter issues, you can run the included debug script:

```bash
docker exec -it wordpress-container-name /usr/local/bin/debug.sh
```
