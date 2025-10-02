<?php
require_once 'config.php';

$message = '';
$messageType = '';

// Processa o formulário de contato
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name = trim($_POST['name'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $subject = trim($_POST['subject'] ?? '');
    $messageContent = trim($_POST['message'] ?? '');
    
    // Validação básica
    if (empty($name) || empty($email) || empty($subject) || empty($messageContent)) {
        $message = 'Todos os campos são obrigatórios.';
        $messageType = 'error';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $message = 'Por favor, insira um email válido.';
        $messageType = 'error';
    } else {
        // Simula o envio (em uma aplicação real, enviaria email)
        $logEntry = [
            'timestamp' => date('Y-m-d H:i:s'),
            'name' => $name,
            'email' => $email,
            'subject' => $subject,
            'message' => $messageContent,
            'ip' => $_SERVER['REMOTE_ADDR']
        ];
        
        // Log da mensagem
        file_put_contents('logs/contact.log', json_encode($logEntry) . PHP_EOL, FILE_APPEND | LOCK_EX);
        
        $message = 'Mensagem enviada com sucesso! Entraremos em contato em breve.';
        $messageType = 'success';
        
        // Limpa os campos após envio bem-sucedido
        $name = $email = $subject = $messageContent = '';
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo APP_NAME; ?> - Contato</title>
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
                    <li><a href="contact.php" class="active">Contato</a></li>
                    <li><a href="health.php">Health Check</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <section class="contact-content">
            <h1>Entre em Contato</h1>
            
            <?php if (!empty($message)): ?>
                <div class="alert alert-<?php echo $messageType; ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endif; ?>

            <div class="contact-grid">
                <div class="contact-info">
                    <h2>📞 Informações de Contato</h2>
                    
                    <div class="contact-item">
                        <h3>🏢 Escritório Principal</h3>
                        <p>Rua das Tecnologias, 123<br>
                        São Paulo - SP, 01234-567<br>
                        Brasil</p>
                    </div>

                    <div class="contact-item">
                        <h3>📧 Email</h3>
                        <p>contato@devopsplatform.com<br>
                        suporte@devopsplatform.com</p>
                    </div>

                    <div class="contact-item">
                        <h3>📱 Telefone</h3>
                        <p>+55 (11) 1234-5678<br>
                        +55 (11) 9876-5432</p>
                    </div>

                    <div class="contact-item">
                        <h3>🕒 Horário de Atendimento</h3>
                        <p>Segunda à Sexta: 8h às 18h<br>
                        Sábado: 8h às 12h<br>
                        Domingo: Fechado</p>
                    </div>

                    <div class="contact-item">
                        <h3>🚨 Suporte 24/7</h3>
                        <p>Para emergências críticas:<br>
                        emergency@devopsplatform.com<br>
                        +55 (11) 9999-0000</p>
                    </div>
                </div>

                <div class="contact-form">
                    <h2>💬 Envie uma Mensagem</h2>
                    <form method="POST" action="">
                        <div class="form-group">
                            <label for="name">Nome Completo *</label>
                            <input type="text" id="name" name="name" value="<?php echo htmlspecialchars($name ?? ''); ?>" required>
                        </div>

                        <div class="form-group">
                            <label for="email">Email *</label>
                            <input type="email" id="email" name="email" value="<?php echo htmlspecialchars($email ?? ''); ?>" required>
                        </div>

                        <div class="form-group">
                            <label for="subject">Assunto *</label>
                            <select id="subject" name="subject" required>
                                <option value="">Selecione um assunto</option>
                                <option value="suporte-tecnico" <?php echo (($subject ?? '') === 'suporte-tecnico') ? 'selected' : ''; ?>>Suporte Técnico</option>
                                <option value="vendas" <?php echo (($subject ?? '') === 'vendas') ? 'selected' : ''; ?>>Vendas</option>
                                <option value="parceria" <?php echo (($subject ?? '') === 'parceria') ? 'selected' : ''; ?>>Parcerias</option>
                                <option value="feedback" <?php echo (($subject ?? '') === 'feedback') ? 'selected' : ''; ?>>Feedback</option>
                                <option value="outro" <?php echo (($subject ?? '') === 'outro') ? 'selected' : ''; ?>>Outro</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label for="message">Mensagem *</label>
                            <textarea id="message" name="message" rows="6" placeholder="Descreva sua dúvida, sugestão ou problema..." required><?php echo htmlspecialchars($messageContent ?? ''); ?></textarea>
                        </div>

                        <button type="submit" class="btn-primary">📤 Enviar Mensagem</button>
                    </form>
                </div>
            </div>

            <section class="team-info">
                <h2>👥 Nossa Equipe DevOps</h2>
                <div class="team-grid">
                    <div class="team-member">
                        <h3>🛠️ DevOps Engineering</h3>
                        <p>Especialistas em containerização, CI/CD e automação de infraestrutura.</p>
                    </div>
                    <div class="team-member">
                        <h3>☁️ Cloud Architecture</h3>
                        <p>Arquitetos especializados em AWS, Azure e Google Cloud Platform.</p>
                    </div>
                    <div class="team-member">
                        <h3>📊 Site Reliability Engineering</h3>
                        <p>Engenheiros focados em monitoramento, observabilidade e performance.</p>
                    </div>
                    <div class="team-member">
                        <h3>🔒 Security Operations</h3>
                        <p>Especialistas em segurança de aplicações e infraestrutura.</p>
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