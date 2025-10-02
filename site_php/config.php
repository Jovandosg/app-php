<?php
// Configurações da Aplicação

// Informações básicas da aplicação
define('APP_NAME', 'DevOps Test Platform');
define('APP_VERSION', '2.1.3');
define('APP_ENV', getenv('APP_ENV') ?: 'production');

// Configurações de banco de dados (simulado)
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'devops_app');
define('DB_USER', getenv('DB_USER') ?: 'app_user');
define('DB_PASS', getenv('DB_PASS') ?: 'secure_password');

// Configurações de cache
define('CACHE_ENABLED', getenv('CACHE_ENABLED') ?: 'true');
define('CACHE_TTL', getenv('CACHE_TTL') ?: 3600);

// Configurações de logs
define('LOG_LEVEL', getenv('LOG_LEVEL') ?: 'INFO');
define('LOG_PATH', getenv('LOG_PATH') ?: './logs');

// Timezone
date_default_timezone_set('America/Sao_Paulo');

// Headers de segurança básicos
if (!headers_sent()) {
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('X-XSS-Protection: 1; mode=block');
}

// Função para verificar saúde da aplicação
function checkAppHealth() {
    $checks = [];
    
    // Verifica se o diretório de logs é gravável
    $checks['logs_writable'] = is_writable(LOG_PATH);
    
    // Verifica disponibilidade de memória
    $memUsage = memory_get_usage(true);
    $memLimit = ini_get('memory_limit');
    $checks['memory_ok'] = $memUsage < (int)$memLimit * 0.9;
    
    // Simula verificação de conectividade com banco
    $checks['database_connection'] = true; // Em uma app real, testaria a conexão
    
    // Status geral
    $checks['overall_status'] = $checks['logs_writable'] && 
                               $checks['memory_ok'] && 
                               $checks['database_connection'];
    
    return $checks;
}
?>