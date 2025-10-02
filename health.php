<?php
require_once 'config.php';

// Define o content type como JSON para APIs
header('Content-Type: application/json');

// Função para verificar a saúde da aplicação
$healthChecks = checkAppHealth();

// Determina o status HTTP baseado nos checks
$httpStatus = $healthChecks['overall_status'] ? 200 : 503;
http_response_code($httpStatus);

// Informações detalhadas do sistema
$systemInfo = [
    'timestamp' => date('c'),
    'application' => [
        'name' => APP_NAME,
        'version' => APP_VERSION,
        'environment' => APP_ENV,
        'php_version' => phpversion(),
        'memory_usage' => [
            'current' => memory_get_usage(true),
            'peak' => memory_get_peak_usage(true),
            'limit' => ini_get('memory_limit')
        ]
    ],
    'system' => [
        'hostname' => gethostname(),
        'os' => php_uname('s'),
        'architecture' => php_uname('m'),
        'uptime' => (file_exists('/proc/uptime') ? trim(file_get_contents('/proc/uptime')) : 'N/A'),
        'load_average' => (function_exists('sys_getloadavg') ? sys_getloadavg() : null)
    ],
    'checks' => $healthChecks,
    'status' => $healthChecks['overall_status'] ? 'healthy' : 'unhealthy'
];

// Para requisições de health check simples (usados por load balancers)
if (isset($_GET['simple']) || isset($_GET['lb'])) {
    if ($healthChecks['overall_status']) {
        http_response_code(200);
        echo json_encode([
            'status' => 'ok',
            'timestamp' => date('c'),
            'version' => APP_VERSION
        ]);
    } else {
        http_response_code(503);
        echo json_encode([
            'status' => 'error',
            'timestamp' => date('c'),
            'version' => APP_VERSION
        ]);
    }
    exit;
}

// Para requisições de readiness check (Kubernetes)
if (isset($_GET['ready'])) {
    // Simula verificações de readiness (banco de dados, cache, etc.)
    $readinessChecks = [
        'database' => true, // Em uma app real, testaria conexão com o banco
        'cache' => CACHE_ENABLED === 'true',
        'external_services' => true // APIs externas, etc.
    ];
    
    $isReady = array_reduce($readinessChecks, function($carry, $check) {
        return $carry && $check;
    }, true);
    
    http_response_code($isReady ? 200 : 503);
    echo json_encode([
        'status' => $isReady ? 'ready' : 'not ready',
        'checks' => $readinessChecks,
        'timestamp' => date('c')
    ]);
    exit;
}

// Para requisições de liveness check (Kubernetes)
if (isset($_GET['live'])) {
    // Verificações básicas de liveness
    $isAlive = true; // A aplicação está rodando se chegou até aqui
    
    http_response_code($isAlive ? 200 : 503);
    echo json_encode([
        'status' => $isAlive ? 'alive' : 'dead',
        'timestamp' => date('c'),
        'uptime' => time() - $_SERVER['REQUEST_TIME']
    ]);
    exit;
}

// Resposta detalhada para monitoring tools
echo json_encode($systemInfo, JSON_PRETTY_PRINT);
?>