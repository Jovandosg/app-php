<?php
require_once 'config.php';

// Função simples para logging
function logAccess() {
    $log = date('Y-m-d H:i:s') . ' - Acesso à página principal - IP: ' . $_SERVER['REMOTE_ADDR'] . PHP_EOL;
    file_put_contents('logs/access.log', $log, FILE_APPEND | LOCK_EX);
}

// Cria diretório de logs se não existir
if (!is_dir('logs')) {
    mkdir('logs', 0755, true);
}

logAccess();
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Página Principal</title>
    <link href="assets/style.css" rel="stylesheet">
</head>
<body>
    <header>
        <nav>
            <div class="container">
                <h1><?php echo APP_NAME; ?></h1>
                <ul>
                    <li><a href="index.php">Home</a></li>
                    <li><a href="about.php">Sobre</a></li>
                    <li><a href="contact.php">Contato</a></li>
                    <li><a href="health.php">Health Check</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <section class="hero">
            <h2>Bem-vindo à nossa Plataforma Digital!</h2>
            <p>Esta é uma aplicação PHP legada que está sendo modernizada através de práticas DevOps.</p>
            
            <div class="stats">
                <div class="stat-item">
                    <h3>Versão da Aplicação</h3>
                    <p><?php echo APP_VERSION; ?></p>
                </div>
                <div class="stat-item">
                    <h3>Ambiente</h3>
                    <p><?php echo APP_ENV; ?></p>
                </div>
                <div class="stat-item">
                    <h3>Data/Hora do Servidor</h3>
                    <p><?php echo date('d/m/Y H:i:s'); ?></p>
                </div>
                <div class="stat-item">
                    <h3>Versão do PHP</h3>
                    <p><?php echo phpversion(); ?></p>
                </div>
            </div>
        </section>

        <section class="features">
            <h2>Funcionalidades da Plataforma</h2>
            <div class="feature-grid">
                <div class="feature-card">
                    <h3>🚀 Alta Performance</h3>
                    <p>Aplicação otimizada para atender milhares de usuários simultaneamente.</p>
                </div>
                <div class="feature-card">
                    <h3>🔒 Segurança</h3>
                    <p>Implementação de melhores práticas de segurança para proteção de dados.</p>
                </div>
                <div class="feature-card">
                    <h3>📊 Analytics</h3>
                    <p>Sistema de métricas e monitoramento em tempo real.</p>
                </div>
                <div class="feature-card">
                    <h3>🔄 CI/CD</h3>
                    <p>Pipeline automatizado para deployments seguros e rápidos.</p>
                </div>
            </div>
        </section>
    </main>

    <footer>
        <div class="container">
            <p>&copy; 2025 <?php echo APP_NAME; ?>. Teste Técnico DevOps - Containerização e Automação.</p>
        </div>
    </footer>
</body>
</html>