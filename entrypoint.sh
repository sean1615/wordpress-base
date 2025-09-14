#!/bin/bash
set -e

# Add Redis configuration to wp-config.php if no# Testing Nginx configuration...
echo "Testing Nginx configuration..."
nginx -t || echo "Nginx configuration has errors!"

# Create a basic index.php in case WordPress isn't fully initialized
if [ ! -f /var/www/html/index.php ]; then
    echo "Creating a basic index.php file..."
    echo "<?php echo '<h1>WordPress setup in progress...</h1>'; ?>" > /var/www/html/index.php
    chown www-data:www-data /var/www/html/index.php
fi

# Output debugging information for socket permissions
echo "PHP-FPM socket permissions:"
ls -la /run/php-fpm.sock 2>/dev/null || echo "Socket not found yet (will be created when PHP-FPM starts)"
echo

# Show WordPress directory permissions
echo "WordPress directory permissions:"
ls -la /var/www/html/ | head -10

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
cat > /usr/local/etc/php-fpm.d/zz-docker.conf << 'EOF'
[global]
daemonize = no

[www]
listen = /run/php-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

user = www-data
group = www-data

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

catch_workers_output = yes
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /proc/self/fd/2
EOF

# Make sure the config is readable
chmod 644 /usr/local/etc/php-fpm.d/zz-docker.conf

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

# Set up WordPress configuration
echo "Setting up WordPress configuration..."
if [ -f /var/www/html/wp-config-docker.php ] && [ ! -f /var/www/html/wp-config.php ]; then
    # Copy the Docker configuration
    cp /var/www/html/wp-config-docker.php /var/www/html/wp-config.php
    chown www-data:www-data /var/www/html/wp-config.php
    echo "WordPress configuration created from Docker template"
fi

# Ensure PHP-FPM socket directory has correct permissions
mkdir -p $(dirname /run/php-fpm.sock)
# Remove any existing socket to avoid permission issues
rm -f /run/php-fpm.sock
# Set proper permissions for the socket directory
chown -R www-data:www-data $(dirname /run/php-fpm.sock)
chmod 775 $(dirname /run/php-fpm.sock)

# Test configuration files
echo "Testing Nginx configuration..."
nginx -t || echo "Nginx configuration has errors!"

# Create a basic index.php in case WordPress isn't fully initialized
if [ ! -f /var/www/html/index.php ]; then
    echo "Creating a basic index.php file..."
    echo "<?php echo '<h1>WordPress setup in progress...</h1>'; ?>" > /var/www/html/index.php
    chown www-data:www-data /var/www/html/index.php
fi

# Create a script to check and fix socket permissions
cat > /usr/local/bin/fix-socket-permissions.sh << 'EOF'
#!/bin/bash

MAX_RETRIES=10
RETRY_INTERVAL=2
SOCKET_PATH="/run/php-fpm.sock"

echo "[$(date)] Starting socket permission monitor..."

for i in $(seq 1 $MAX_RETRIES); do
    if [ -S "$SOCKET_PATH" ]; then
        echo "[$(date)] PHP-FPM socket exists, checking permissions..."
        SOCKET_OWNER=$(stat -c "%U:%G" $SOCKET_PATH 2>/dev/null)
        SOCKET_PERMS=$(stat -c "%a" $SOCKET_PATH 2>/dev/null)
        
        echo "[$(date)] Current socket ownership: $SOCKET_OWNER, permissions: $SOCKET_PERMS"
        
        if [ "$SOCKET_OWNER" != "www-data:www-data" ] || [ "$SOCKET_PERMS" != "660" ]; then
            echo "[$(date)] Fixing socket permissions..."
            chown www-data:www-data $SOCKET_PATH
            chmod 660 $SOCKET_PATH
            ls -la $SOCKET_PATH
            echo "[$(date)] Socket permissions fixed"
        else
            echo "[$(date)] Socket permissions are correct"
        fi
        
        # Test connection to make sure it works
        if ! su -s /bin/bash www-data -c "test -r $SOCKET_PATH && test -w $SOCKET_PATH"; then
            echo "[$(date)] WARNING: www-data user cannot access the socket properly!"
        else
            echo "[$(date)] Socket permissions verified working for www-data user"
        fi
        
        break
    else
        echo "[$(date)] Attempt $i/$MAX_RETRIES: Socket not found yet, waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    fi
done

if [ ! -S "$SOCKET_PATH" ]; then
    echo "[$(date)] ERROR: PHP-FPM socket not found after $MAX_RETRIES attempts!"
    exit 1
fi
EOF

chmod +x /usr/local/bin/fix-socket-permissions.sh

# Run the socket permission fixer in the background
/usr/local/bin/fix-socket-permissions.sh &

# Execute the main command (supervisor)
exec "$@"
