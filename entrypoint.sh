#!/bin/bash
set -e

# Add Redis configuration to wp-config.php if not already present
if [ -f /var/www/html/wp-config.php ]; then
    if ! grep -q "WP_REDIS_HOST" /var/www/html/wp-config.php; then
        wp_config_end=$(grep -n "require_once ABSPATH . 'wp-settings.php';" /var/www/html/wp-config.php | cut -d ":" -f 1)
        
        # Add Redis configuration before wp-settings.php require
        if [ -n "$wp_config_end" ]; then
            # Insert Redis configuration directly before wp-settings.php
            sed -i "${wp_config_end}i /* Redis settings */" /var/www/html/wp-config.php
            sed -i "$((wp_config_end+1))i define('WP_REDIS_HOST', 'redis');" /var/www/html/wp-config.php
            sed -i "$((wp_config_end+2))i define('WP_REDIS_PORT', 6379);" /var/www/html/wp-config.php
            sed -i "$((wp_config_end+3))i define('WP_CACHE', true);" /var/www/html/wp-config.php
            sed -i "$((wp_config_end+4))i " /var/www/html/wp-config.php
            
            echo "Added Redis configuration to wp-config.php"
        fi
    fi
fi

# Run WordPress entrypoint script but don't start PHP-FPM yet
# We'll handle that with supervisor
/usr/local/bin/docker-entrypoint.sh bash -c "echo 'WordPress initialized'"

# Configure PHP-FPM to use a Unix socket instead of TCP port
# This avoids the address already in use error
sed -i 's|listen = 9000|listen = /run/php-fpm.sock|g' /usr/local/etc/php-fpm.d/zz-docker.conf
sed -i 's|listen.owner = www-data|listen.owner = www-data\nlisten.mode = 0666|g' /usr/local/etc/php-fpm.d/zz-docker.conf

# Debug information
echo "==== DEBUG INFO ===="
echo "WordPress Directory Contents:"
ls -la /var/www/html/
echo ""
echo "PHP-FPM Configuration:"
cat /usr/local/etc/php-fpm.d/zz-docker.conf
echo ""
echo "Nginx Configuration:"
cat /etc/nginx/nginx.conf | grep -A 10 "server {"
echo ""

# Fix permissions
echo "Setting correct permissions for WordPress files..."
chown -R www-data:www-data /var/www/html/
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;
echo "Permissions set."

# Create the PHP-FPM socket directory with correct permissions
mkdir -p /run/php
chown -R www-data:www-data /run/php

# Execute the main command (supervisor)
exec "$@"
