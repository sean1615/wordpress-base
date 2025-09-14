#!/bin/bash
# Debug script for WordPress-Nginx setup

echo "=== System Status ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -a)"
echo

echo "=== Process Status ==="
ps aux | grep -E 'nginx|php|supervisord'
echo

echo "=== Service Status ==="
echo "PHP-FPM Socket:"
ls -la /run/php-fpm.sock 2>/dev/null || echo "Socket not found!"
echo

echo "=== PHP Info ==="
php -v
echo

echo "=== Web Server Config ==="
echo "Nginx Configuration:"
nginx -T 2>&1 | grep -E 'root|fastcgi_pass|listen|server_name|error_log|access_log'
echo

echo "=== File Permissions ==="
echo "WordPress Directory:"
ls -la /var/www/html/
echo
echo "WordPress Index:"
ls -la /var/www/html/index.php 2>/dev/null || echo "index.php not found!"
echo

echo "=== Log Files ==="
echo "Nginx Error Log (last 20 lines):"
tail -n 20 /var/log/nginx/error.log 2>/dev/null || echo "Error log not found or empty"
echo
echo "Nginx Access Log (last 20 lines):"
tail -n 20 /var/log/nginx/access.log 2>/dev/null || echo "Access log not found or empty"
echo

echo "=== Network Status ==="
echo "Listening Ports:"
netstat -tlnp 2>/dev/null || echo "netstat not available"
