# WordPress Nginx Docker Image

A high-performance WordPress Docker image with Nginx, PHP-FPM, and Redis object caching support.

## Overview

This repository contains a Dockerfile that builds a WordPress image with the following features:

- **Nginx Web Server**: Replaces Apache for better performance
- **PHP-FPM**: For efficient PHP processing
- **Redis Object Cache**: For improved WordPress performance
- **Multi-stage Build**: Optimized Docker image size

## Using This Image

### Basic Usage

This image can be used as a base for your WordPress projects:

```dockerfile
FROM your-org/wordpress-nginx:latest

# Add your custom themes, plugins, etc.
COPY ./themes/ /var/www/html/wp-content/themes/
COPY ./plugins/ /var/www/html/wp-content/plugins/
```

### Environment Variables

The image supports all standard WordPress environment variables:

- `WORDPRESS_DB_HOST`: Database hostname (default: `db`)
- `WORDPRESS_DB_USER`: Database username (default: `wordpress`)
- `WORDPRESS_DB_PASSWORD`: Database password
- `WORDPRESS_DB_NAME`: Database name (default: `wordpress`)
- `WORDPRESS_TABLE_PREFIX`: Table prefix (default: `wp_`)
- `WORDPRESS_DEBUG`: Enable debug mode (`true`/`false`)

### Sample docker-compose.yml

While not included in this repository, here's a sample docker-compose.yml you can use:

```yaml
version: '3.8'

services:
  wordpress:
    image: your-org/wordpress-nginx:latest
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_TABLE_PREFIX: wp_
      WORDPRESS_DEBUG: "false"
    volumes:
      - wp_content:/var/www/html/wp-content

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

  redis:
    image: redis:latest
    restart: unless-stopped

volumes:
  wp_content:
  db_data:
```

## Performance Features

### Nginx Configuration

- Optimized for WordPress
- Static file caching
- Efficient PHP-FPM communication via Unix socket
- Gzip compression

### PHP-FPM Settings

- Optimized memory usage
- Improved request handling

### Redis Object Cache

- Reduces database load
- Speeds up dynamic page generation

## Building the Image

To build this image locally:

```bash
docker build -t wordpress-nginx .
```

## Extending This Image

### Adding Plugins/Themes

The recommended approach is to extend this image and add your custom plugins/themes:

```dockerfile
FROM your-org/wordpress-nginx:latest

# Add custom plugins
COPY ./plugins/my-custom-plugin /var/www/html/wp-content/plugins/my-custom-plugin

# Add custom themes
COPY ./themes/my-custom-theme /var/www/html/wp-content/themes/my-custom-theme
```

### Custom Configuration

You can also override configuration files:

```dockerfile
FROM your-org/wordpress-nginx:latest

# Custom Nginx config
COPY ./nginx-custom.conf /etc/nginx/nginx.conf

# Custom PHP settings
COPY ./php-custom.ini /usr/local/etc/php/conf.d/custom-php.ini
```

## Security Notes

- WordPress admin area should be protected (via HTTPS and/or IP restrictions)
- Database credentials should be secured
- Production deployments should use proper secrets management
- Regular updates are important

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on official WordPress and Nginx Docker images
- Inspired by WordPress performance best practices
