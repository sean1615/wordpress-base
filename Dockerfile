ARG PHP_VERSION=8.3

# PHP-FPM stage
FROM wordpress:php${PHP_VERSION}-fpm AS wordpress

# Nginx stage
FROM nginx:stable AS nginx

# Final combined stage
FROM wordpress:php${PHP_VERSION}-fpm

# Install Supervisor and debugging tools
RUN apt-get update && apt-get install -y \
    supervisor \
    curl \
    zip \
    nano \
    vim \
    less \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy Nginx binary and configuration from the nginx image
COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx
#COPY --from=nginx /etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY --from=nginx /etc/nginx/mime.types /etc/nginx/mime.types
COPY --from=nginx /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params
COPY --from=nginx /etc/nginx/scgi_params /etc/nginx/scgi_params
COPY --from=nginx /etc/nginx/uwsgi_params /etc/nginx/uwsgi_params
COPY --from=nginx /var/log/nginx /var/log/nginx

# Create required directories for Nginx
RUN mkdir -p /var/cache/nginx /run/nginx \
    && chown -R www-data:www-data /var/log/nginx /var/cache/nginx /run/nginx

# Copy Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Install Redis object cache plugin for WordPress
RUN curl -o /tmp/redis-cache.zip https://downloads.wordpress.org/plugin/redis-cache.2.6.5.zip \
    && unzip /tmp/redis-cache.zip -d /usr/src/wordpress/wp-content/plugins/ \
    && rm /tmp/redis-cache.zip

# Create a test file to check web server access
RUN echo "<?php phpinfo(); ?>" > /usr/src/wordpress/info.php \
    && echo "<html><body><h1>Nginx Test Page</h1><p>If you see this, Nginx is working!</p></body></html>" > /usr/src/wordpress/test.html

# Copy custom entry point script
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Copy healthcheck script
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Copy debug script
COPY debug.sh /usr/local/bin/debug.sh
RUN chmod +x /usr/local/bin/debug.sh

# Expose HTTP port
EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
