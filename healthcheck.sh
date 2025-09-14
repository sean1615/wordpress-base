#!/bin/bash
set -e

# Check if Nginx is running
if ! pgrep nginx > /dev/null; then
    echo "Nginx is not running"
    exit 1
fi

# Check if PHP-FPM is running
if ! pgrep php-fpm > /dev/null; then
    echo "PHP-FPM is not running"
    exit 1
fi

# Check if WordPress is accessible
CURL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$CURL_RESPONSE" != "200" ] && [ "$CURL_RESPONSE" != "302" ]; then
    echo "WordPress is not accessible, HTTP status: $CURL_RESPONSE"
    exit 1
fi

echo "All checks passed"
exit 0
