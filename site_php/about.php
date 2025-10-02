<?php
require_once 'config.php';
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Sobre</title>
    <link href="assets/style.css" rel="stylesheet">
</head>
<body>
    <header>
        <nav>
            <div class="container">
                <h1><?php echo APP_NAME; ?></h1>
                <ul>
                    <li><a href="index.php">Home</a></li>
                    <li><a href="about.php" class="active">Sobre</a></li>
                    <li><a href="contact.php">Contato</a></li>
                    <li><a href="health.php">Health Check</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <section class="about-content">
            <h1>Sobre Nossa Plataforma</h1>
            
            <div class="about-grid">
                <div class="about-section">
                    <h2>📈 Nossa História</h2>
                    <p>Esta plataforma digital alcançou grande sucesso e crescimento acelerado no número de usuários. 
                    Desenvolvida inicialmente em PHP, nossa aplicação é robusta e atende bem às necessidades do negócio.</p>
                    <p>Com o crescimento exponencial, identificamos a necessidade de modernizar nossa infraestrutura 
                    e processos de deployment para acompanhar a evolução do mercado.</p>
                </div>

                <div class="about-section">
                    <h2>🔧 Desafios Técnicos</h2>
                    <p>Anteriormente, nosso processo de deploy era manual e arriscado:</p>
                    <ul>
                        <li>Deployments via SSH direto aos servidores</li>
                        <li>Git pull manual seguido de comandos manuais</li>
                        <li>Instabilidade em momentos de pico</li>
                        <li>Ambientes inconsistentes entre desenvolvimento e produção</li>
                        <li>Tempo de release medido em semanas</li>
                    </ul>
                </div>

                <div class="about-section">
                    <h2>🚀 Modernização</h2>
                    <p>Estamos implementando um projeto estratégico de modernização que inclui:</p>
                    <ul>
                        <li><strong>Containerização:</strong> Docker para padronização de ambientes</li>
                        <li><strong>CI/CD:</strong> GitHub Actions para automação</li>
                        <li><strong>IaC:</strong> Terraform para infraestrutura como código</li>
                        <li><strong>Orquestração:</strong> Kubernetes/ECS para gestão de containers</li>
                        <li><strong>Observabilidade:</strong> Monitoramento e métricas em tempo real</li>
                    </ul>
                </div>

                <div class="about-section">
                    <h2>📊 Especificações Técnicas</h2>
                    <div class="tech-specs">
                        <div class="spec-item">
                            <strong>Linguagem:</strong> PHP <?php echo phpversion(); ?>
                        </div>
                        <div class="spec-item">
                            <strong>Servidor Web:</strong> Apache/Nginx
                        </div>
                        <div class="spec-item">
                            <strong>Sistema Operacional:</strong> <?php echo php_uname('s') . ' ' . php_uname('r'); ?>
                        </div>
                        <div class="spec-item">
                            <strong>Arquitetura:</strong> <?php echo php_uname('m'); ?>
                        </div>
                        <div class="spec-item">
                            <strong>Memória Alocada:</strong> <?php echo ini_get('memory_limit'); ?>
                        </div>
                        <div class="spec-item">
                            <strong>Timezone:</strong> <?php echo date_default_timezone_get(); ?>
                        </div>
                    </div>
                </div>
            </div>

            <section class="metrics">
                <h2>📈 Métricas da Aplicação</h2>
                <div class="metrics-grid">
                    <div class="metric-card">
                        <h3>Uptime</h3>
                        <p class="metric-value">99.9%</p>
                        <small>Últimos 30 dias</small>
                    </div>
                    <div class="metric-card">
                        <h3>Tempo de Resposta</h3>
                        <p class="metric-value"><?php echo round(microtime(true) - $_SERVER['REQUEST_TIME_FLOAT'], 3); ?>s</p>
                        <small>Esta requisição</small>
                    </div>
                    <div class="metric-card">
                        <h3>Usuários Ativos</h3>
                        <p class="metric-value">12,547</p>
                        <small>Última hora</small>
                    </div>
                    <div class="metric-card">
                        <h3>Deployments</h3>
                        <p class="metric-value">156</p>
                        <small>Este mês</small>
                    </div>
                </div>
            </section>
        </section>
    </main>

    <footer>
        <div class="container">
            <p>&copy; 2025 <?php echo APP_NAME; ?>. Teste Técnico DevOps - Containerização e Automação.</p>
        </div>
    </footer>
</body>
</html>