# Aplicação PHP - Teste DevOps

Aplicação web PHP containerizada demonstrando práticas modernas de DevOps e infraestrutura como código.

## Arquitetura

- **Runtime**: PHP 8.2 com FPM
- **Servidor Web**: Nginx
- **Containerização**: Docker multi-stage
- **CI/CD**: GitHub Actions
- **Cloud**: AWS (ECR + EC2)

## Estrutura do Projeto

```
.
├── .github/workflows/    # Pipeline CI/CD
├── assets/              # Recursos estáticos
├── site_php/           # Código-fonte da aplicação
├── Dockerfile          # Containerização
└── docker-compose.yml  # Ambiente local
```

## Executar Localmente

```bash
docker-compose up -d
```

Acesse: http://localhost:8080

## Endpoints

- `/` - Página principal
- `/about.php` - Informações da aplicação
- `/contact.php` - Formulário de contato
- `/health` - Health check

## Pipeline CI/CD

O pipeline automatizado realiza:

1. Build da imagem Docker
2. Push para Amazon ECR
3. Deploy automático em EC2

## Segurança

- Imagem Alpine Linux minimalista
- Execução com usuário não-root
- Headers de segurança configurados
- Porta não-privilegiada (8080)

## Observabilidade

Health checks disponíveis para monitoramento:
- `/health` - Completo
- `/health?simple` - Load balancer
- `/health?ready` - Readiness probe
- `/health?live` - Liveness probe
