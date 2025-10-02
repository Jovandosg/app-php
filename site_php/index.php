<?php
require_once 'config.php';

$pageTitle = "DevOps Platform";
$currentPage = "home";
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $pageTitle; ?></title>
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="container">
            <h1>DevOps Platform</h1>
            <ul>
                <li><a href="index.php" class="active">Home</a></li>
                <li><a href="about.php">Sobre</a></li>
                <li><a href="contact.php">Contato</a></li>
            </ul>
        </div>
    </nav>

    <main class="container">
        <section class="hero">
            <h2>Bem-vindo à Plataforma DevOps</h2>
            <p>Aplicação PHP moderna com práticas de containerização e CI/CD</p>
        </section>

        <section class="metrics">
            <div class="metric-card">
                <h3>Versão PHP</h3>
                <p><?php echo phpversion(); ?></p>
            </div>
            <div class="metric-card">
                <h3>Servidor</h3>
                <p><?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'N/A'; ?></p>
            </div>
            <div class="metric-card">
                <h3>Status</h3>
                <p class="status-ok">Operacional</p>
            </div>
        </section>

        <section class="features">
            <h2>Recursos Implementados</h2>
            <ul>
                <li>Containerização com Docker multi-stage</li>
                <li>Pipeline CI/CD automatizado</li>
                <li>Health checks para monitoramento</li>
                <li>Segurança com usuário não-root</li>
                <li>Otimizações de performance</li>
            </ul>
        </section>
    </main>

    <footer>
        <p>&copy; <?php echo date('Y'); ?> DevOps Platform. Todos os direitos reservados.</p>
    </footer>
</body>
</html>
