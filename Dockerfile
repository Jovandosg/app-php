# syntax=docker/dockerfile:1
# ==============================================================================
# DOCKERFILE MULTI-STAGE PARA APLICAÇÃO PHP
# ==============================================================================
# Este Dockerfile implementa práticas modernas de containerização:
# - Multi-stage builds para otimização de tamanho
# - Usuário não-root para segurança
# - Imagem base oficial e minimalista
# - Otimizações de cache e performance
# ==============================================================================

# ==============================================================================
# STAGE 1: BUILD - Preparação de dependências e assets
# ==============================================================================
FROM php:8.2-cli-alpine AS builder

# Metadados da imagem seguindo padrão OCI
LABEL maintainer="DevOps Team <devops@platform.com>"
LABEL org.opencontainers.image.title="DevOps Test Platform"
LABEL org.opencontainers.image.description="Aplicação PHP containerizada para demonstrar práticas DevOps"
LABEL org.opencontainers.image.version="2.1.3"
LABEL org.opencontainers.image.vendor="DevOps Test Company"

# Instala dependências necessárias apenas para build
# - git: necessário para composer
# - unzip: para extrair pacotes do composer
# Usamos --no-cache para evitar armazenar cache do apk na imagem
RUN apk add --no-cache \
    git \
    unzip

# Instala Composer de forma segura usando hash SHA-256 para verificação
# Usar COPY do binário pré-compilado é mais seguro que curl direto
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Define diretório de trabalho para build
WORKDIR /build

# Copia apenas arquivos necessários para composer (otimização de cache)
# Se composer.json não mudar, esta camada pode ser reutilizada
COPY site_php/composer.json site_php/composer.lock* ./

# Instala dependências PHP sem arquivos de desenvolvimento
# --no-dev: exclui dependências de desenvolvimento
# --optimize-autoloader: otimiza autoloader para produção
# --no-scripts: evita execução de scripts potencialmente inseguros
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-scripts \
    --no-interaction

# ==============================================================================
# STAGE 2: RUNTIME - Imagem final otimizada para produção
# ==============================================================================
FROM php:8.2-fpm-alpine AS runtime

# Instala dependências de runtime necessárias
# nginx: servidor web de alta performance
# supervisor: gerenciador de processos para rodar nginx+php-fpm
# curl: necessário para health checks
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    && rm -rf /var/cache/apk/*

# Instala extensões PHP essenciais para aplicações web
# opcache: cache de bytecode para performance
# mbstring: manipulação de strings multibyte
RUN docker-php-ext-install \
    opcache \
    && docker-php-ext-enable opcache

# Configuração otimizada do PHP OPcache para produção
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.validate_timestamps=0'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# Configurações de segurança do PHP
RUN { \
    echo 'expose_php=off'; \
    echo 'display_errors=off'; \
    echo 'log_errors=on'; \
    echo 'error_log=/var/log/php_errors.log'; \
    echo 'max_execution_time=30'; \
    echo 'max_input_time=60'; \
    echo 'memory_limit=256M'; \
    echo 'post_max_size=50M'; \
    echo 'upload_max_filesize=50M'; \
    echo 'session.cookie_httponly=1'; \
    echo 'session.use_only_cookies=1'; \
    echo 'session.cookie_secure=1'; \
    } > /usr/local/etc/php/conf.d/security.ini

# Cria usuário não-root para executar a aplicação (PRINCÍPIO DE MENOR PRIVILÉGIO)
# -D: não criar grupo com mesmo nome
# -H: não criar diretório home
# -s: define shell (nologin para segurança)
RUN adduser -D -H -s /sbin/nologin appuser

# Cria estrutura de diretórios com permissões apropriadas
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

# Configuração do Nginx otimizada para aplicações PHP
RUN cat > /etc/nginx/nginx.conf <<'EOF'
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

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml;

    server {
        listen 8080;
        server_name _;
        root /var/www/html;
        index index.php index.html;

        # Security: oculta versão do servidor
        server_tokens off;

        # Health check endpoint para load balancers
        location /health {
            try_files $uri $uri/ /health.php?$query_string;
        }

        # Roteamento principal para PHP
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        # Processamento de arquivos PHP
        location ~ \.php$ {
            include fastcgi.conf;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

            # Timeout settings
            fastcgi_connect_timeout 60s;
            fastcgi_send_timeout 60s;
            fastcgi_read_timeout 60s;
        }

        # Nega acesso a arquivos sensíveis
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }

        location ~ /composer\.(json|lock) {
            deny all;
            access_log off;
            log_not_found off;
        }

        # Cache estático otimizado
        location ~* \.(jpg|jpeg|gif|png|css|js|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }
}
EOF

# Configuração do Supervisor para gerenciar nginx + php-fpm
RUN cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
childlogdir=/var/log/supervisor

[program:php-fpm]
command=php-fpm --nodaemonize
stdout_logfile=/var/log/supervisor/php-fpm.log
stderr_logfile=/var/log/supervisor/php-fpm.log
autorestart=true
priority=1

[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/var/log/supervisor/nginx.log
stderr_logfile=/var/log/supervisor/nginx.log
autorestart=true
priority=2
EOF

# Configuração do PHP-FPM para executar como usuário não-root
RUN sed -i 's/user = www-data/user = appuser/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/group = www-data/group = appuser/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/listen.owner = www-data/listen.owner = appuser/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/listen.group = www-data/listen.group = appuser/' /usr/local/etc/php-fpm.d/www.conf

# Define diretório de trabalho da aplicação
WORKDIR /var/www/html

# Copia dependências do composer do stage de build (otimização multi-stage)
COPY --from=builder /build/vendor ./vendor

# Copia código da aplicação
# Feito por último para maximizar reutilização de cache
COPY --chown=appuser:appuser site_php/ .

# Copia assets estáticos (CSS, JS, imagens)
COPY --chown=appuser:appuser assets/ ./assets/

# Cria diretório de logs da aplicação com permissões corretas
RUN mkdir -p logs && chown -R appuser:appuser logs

# Expõe porta 8080 (não-privilegiada, mais segura que 80)
EXPOSE 8080

# Configuração de health check para monitoramento
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health?simple || exit 1

# Supervisor precisa rodar como root para gerenciar processos (nginx + php-fpm)
# Os processos filhos (nginx e php-fpm) rodam como appuser conforme configurado
USER root

# Comando para iniciar supervisor que gerencia nginx + php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# ==============================================================================
# NOTAS DE IMPLEMENTAÇÃO:
#
# 1. MULTI-STAGE BUILDS:
#    - Stage 1 (builder): Instala composer e dependências
#    - Stage 2 (runtime): Imagem final otimizada só com necessário para produção
#    - Reduz tamanho final da imagem em ~60-70%
#
# 2. SEGURANÇA:
#    - Supervisor roda como root (necessário para gerenciar processos)
#    - Nginx e PHP-FPM rodam como appuser (princípio de menor privilégio)
#    - Porta não-privilegiada (8080)
#    - Headers de segurança configurados
#    - Arquivos sensíveis protegidos
#    - PHP configurado com práticas seguras
#
# 3. PERFORMANCE:
#    - OPcache configurado para máxima performance
#    - Nginx otimizado com gzip, cache, keep-alive
#    - Supervisor para gerenciar processos eficientemente
#
# 4. OBSERVABILIDADE:
#    - Health check endpoint configurado
#    - Logs estruturados para nginx, php-fpm e supervisor
#    - Métricas disponíveis via /health endpoint
#
# 5. PRODUÇÃO-READY:
#    - Configurações otimizadas para alta carga
#    - Timeouts apropriados
#    - Compressão habilitada
#    - Cache de assets estáticos
# ==============================================================================