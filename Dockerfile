FROM php:8.2-cli-alpine AS builder

LABEL maintainer="DevOps Team"
LABEL version="1.0.0"

RUN apk add --no-cache git unzip

COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

WORKDIR /build

COPY site_php/composer.json site_php/composer.lock* ./

RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-scripts \
    --no-interaction

FROM php:8.2-fpm-alpine AS runtime

RUN apk add --no-cache nginx supervisor curl \
    && rm -rf /var/cache/apk/*

RUN docker-php-ext-install opcache \
    && docker-php-ext-enable opcache

RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.validate_timestamps=0'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

RUN { \
    echo 'expose_php=off'; \
    echo 'display_errors=off'; \
    echo 'log_errors=on'; \
    echo 'error_log=/var/log/php_errors.log'; \
    echo 'max_execution_time=30'; \
    echo 'memory_limit=256M'; \
    echo 'post_max_size=50M'; \
    echo 'upload_max_filesize=50M'; \
    } > /usr/local/etc/php/conf.d/security.ini

RUN adduser -D -H -s /sbin/nologin appuser

RUN mkdir -p \
    /var/www/html \
    /var/log/nginx \
    /var/log/supervisor \
    /var/run/supervisor \
    /etc/supervisor/conf.d \
    /var/cache/nginx \
    /var/lib/nginx/tmp \
    && chown -R appuser:appuser /var/www/html \
    && chown -R appuser:appuser /var/log/nginx \
    && chown -R appuser:appuser /var/cache/nginx \
    && chown -R appuser:appuser /var/lib/nginx/tmp

RUN cat > /etc/nginx/nginx.conf <<'NGINX_EOF'
user appuser;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';
    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript;

    server {
        listen 8080;
        server_name _;
        root /var/www/html;
        index index.php;

        server_tokens off;

        location /health {
            try_files $uri $uri/ /health.php?$query_string;
        }

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            include fastcgi.conf;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }

        location ~ /\. {
            deny all;
        }

        location ~* \.(jpg|jpeg|gif|png|css|js|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
NGINX_EOF

RUN cat > /etc/supervisor/conf.d/supervisord.conf << 'SUPERVISOR_EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log

[program:php-fpm]
command=php-fpm --nodaemonize
stdout_logfile=/var/log/supervisor/php-fpm.log
stderr_logfile=/var/log/supervisor/php-fpm.log
autorestart=true

[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/var/log/supervisor/nginx.log
stderr_logfile=/var/log/supervisor/nginx.log
autorestart=true
SUPERVISOR_EOF

RUN sed -i 's/user = www-data/user = appuser/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/group = www-data/group = appuser/' /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

COPY --from=builder /build/vendor ./vendor
COPY --chown=appuser:appuser site_php/ .
COPY --chown=appuser:appuser assets/ ./assets/

RUN mkdir -p logs && chown -R appuser:appuser logs

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health?simple || exit 1

USER root

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
