# 🚀 DevOps Test Platform

**Uma aplicação PHP containerizada demonstrando práticas modernas de DevOps**

![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?style=for-the-badge&logo=php)
![Docker](https://img.shields.io/badge/Docker-Multi--Stage-2496ED?style=for-the-badge&logo=docker)
![Nginx](https://img.shields.io/badge/Nginx-1.24-009639?style=for-the-badge&logo=nginx)
![Security](https://img.shields.io/badge/Security-Non--Root-red?style=for-the-badge&logo=security)

## 📋 Sobre o Projeto

Esta aplicação foi desenvolvida como parte de um teste técnico para demonstrar a implementação de práticas modernas de DevOps em uma aplicação PHP legada. O projeto simula uma plataforma digital que cresceu rapidamente e precisa ser modernizada para suportar deploys automatizados, ambientes consistentes e alta disponibilidade.

## 🏗️ Arquitetura da Aplicação

### Componentes Principais
- **Frontend**: Aplicação PHP com interface web responsiva
- **Servidor Web**: Nginx otimizado para alta performance
- **Runtime**: PHP 8.2 com FPM e OPcache
- **Monitoramento**: Health checks integrados para observabilidade

### Funcionalidades Implementadas
- ✅ Página principal com métricas do sistema
- ✅ Página sobre com especificações técnicas
- ✅ Formulário de contato com validação
- ✅ Health check endpoints para monitoramento
- ✅ Logging estruturado
- ✅ Headers de segurança configurados

## 🐳 Containerização - Dockerfile

### Decisões Técnicas Implementadas

#### 1. **Multi-Stage Builds**
```dockerfile
FROM php:8.2-cli-alpine AS builder  # Stage 1: Build
FROM php:8.2-fpm-alpine AS runtime  # Stage 2: Runtime
```

**Benefícios:**
- **Redução de 60-70% no tamanho** da imagem final
- **Separação de concerns**: build vs runtime
- **Segurança**: ferramentas de build não ficam na imagem final
- **Cache otimizado**: mudanças no código não invalidam camada do composer

#### 2. **Usuário Não-Root**
```dockerfile
RUN adduser -D -H -s /sbin/nologin appuser
USER appuser
```

**Benefícios:**
- **Princípio de menor privilégio** aplicado
- **Reduz superfície de ataque** em caso de comprometimento
- **Compliance** com políticas de segurança corporativas
- **Compatibilidade** com ambientes Kubernetes com PSP/Pod Security Standards

#### 3. **Imagem Base Oficial e Minimalista**
```dockerfile
FROM php:8.2-fpm-alpine
```

**Justificativas:**
- **Imagem oficial** mantida pela comunidade PHP
- **Alpine Linux**: menor superfície de ataque (5MB vs 80MB+)
- **Atualizações regulares** de segurança
- **Compatibilidade** garantida com extensões PHP

#### 4. **Otimizações de Performance**
- **OPcache** configurado para produção
- **Nginx** com compressão gzip e cache de assets
- **PHP-FPM** com configurações otimizadas
- **Supervisor** para gerenciamento eficiente de processos

#### 5. **Configurações de Segurança**
- Headers de segurança (X-Frame-Options, CSP, etc.)
- PHP configurado com `expose_php=off`
- Arquivos sensíveis protegidos
- Porta não-privilegiada (8080)

## 🚀 Como Executar

### Pré-requisitos
- Docker 20.10+
- Docker Compose (opcional)

### Executar com Docker

1. **Build da imagem:**
```bash
docker build -t devops-platform:latest .
```

2. **Executar container:**
```bash
docker run -d \
  --name devops-platform \
  -p 8080:8080 \
  --health-cmd="curl -f http://localhost:8080/health?simple || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  devops-platform:latest
```

3. **Acessar aplicação:**
```bash
open http://localhost:8080
```

### Endpoints Disponíveis

| Endpoint | Descrição | Uso |
|----------|-----------|-----|
| `/` | Página principal | Interface principal |
| `/about.php` | Informações da aplicação | Documentação |
| `/contact.php` | Formulário de contato | Funcionalidade |
| `/health` | Health check completo | Monitoramento |
| `/health?simple` | Health check para LB | Load Balancer |
| `/health?ready` | Readiness probe | Kubernetes |
| `/health?live` | Liveness probe | Kubernetes |

## 📊 Observabilidade e Monitoramento

### Health Checks Implementados

A aplicação possui diferentes tipos de health checks para diferentes cenários:

```php
// Health check completo com métricas
GET /health

// Health check simples para load balancers
GET /health?simple

// Readiness probe para Kubernetes
GET /health?ready

// Liveness probe para Kubernetes  
GET /health?live
```

### Estratégia de Observabilidade Recomendada

Para monitoramento em produção, recomendaria a seguinte stack:

#### Stack de Monitoramento
- **Métricas**: Prometheus + Grafana
- **Logs**: ELK Stack (Elasticsearch + Logstash + Kibana)
- **Tracing**: Jaeger ou Zipkin
- **APM**: New Relic ou Datadog

#### 3 Principais Métricas para Dashboard

1. **Taxa de Resposta (Response Time)**
   - **Por que**: Indica performance percebida pelo usuário
   - **Threshold**: < 200ms para 95% das requests
   - **Alertas**: > 500ms por mais de 2 minutos

2. **Taxa de Erro (Error Rate)**
   - **Por que**: Indica saúde da aplicação
   - **Threshold**: < 1% de errors 5xx
   - **Alertas**: > 5% por mais de 1 minuto

3. **Utilização de Recursos (CPU/Memory)**
   - **Por que**: Indica necessidade de scaling
   - **Threshold**: < 80% CPU, < 85% Memory
   - **Alertas**: > 90% por mais de 5 minutos

#### Implementação de Métricas
```php
// Exemplo de métricas customizadas
$metrics = [
    'response_time' => microtime(true) - $_SERVER['REQUEST_TIME_FLOAT'],
    'memory_usage' => memory_get_usage(true),
    'active_users' => getUserCount(), // função customizada
    'error_rate' => getErrorRate()    // função customizada
];
```

## 🏗️ Estrutura do Projeto

```
devops-test-project/
├── 📁 assets/              # Assets estáticos (CSS, JS)
│   └── style.css          # Estilos da aplicação
├── 📁 logs/               # Diretório de logs (criado em runtime)
├── 📄 index.php           # Página principal
├── 📄 about.php           # Página sobre
├── 📄 contact.php         # Página de contato
├── 📄 health.php          # Endpoints de health check
├── 📄 config.php          # Configurações da aplicação
├── 📄 composer.json       # Dependências PHP
├── 📄 Dockerfile          # Containerização multi-stage
├── 📄 .dockerignore       # Otimização do build
└── 📄 README.md           # Esta documentação
```

## 🔄 Pipeline de CI/CD (Próximos Passos)

### Extensão para Implantação Contínua

O pipeline de CI seria estendido para CD da seguinte forma:

```yaml
# .github/workflows/cd.yml
name: Continuous Deployment

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [build, security-scan] # Jobs do CI
    
    steps:
    - name: Deploy to Staging
      if: github.ref == 'refs/heads/main'
      run: |
        # Deploy para ambiente de staging
        kubectl set image deployment/app \
          app=myregistry.com/devops-platform:${{ github.sha }} \
          -n staging
        kubectl rollout status deployment/app -n staging
        
    - name: Run Smoke Tests
      run: |
        # Testes básicos no ambiente
        curl -f https://staging.platform.com/health
        
    - name: Deploy to Production
      if: startsWith(github.ref, 'refs/tags/v')
      run: |
        # Deploy para produção com aprovação manual
        kubectl set image deployment/app \
          app=myregistry.com/devops-platform:${{ github.ref_name }} \
          -n production
```

### Estratégia de Deployment
- **Blue-Green Deployment** para zero downtime
- **Canary Releases** para reduzir riscos
- **Rollback automático** baseado em health checks
- **Aprovação manual** para produção

## ☁️ Infraestrutura como Código

### Escolha de Tecnologia: Amazon EKS

**Justificativa para Kubernetes (EKS):**
- **Escalabilidade**: Auto-scaling horizontal e vertical
- **Alta Disponibilidade**: Multi-AZ por padrão
- **Ecosystem**: Integração com ferramentas de observabilidade
- **Padrão da Indústria**: Portabilidade entre clouds
- **Gerenciamento de Secrets**: Kubernetes secrets + AWS Secrets Manager

### Alternativa: AWS ECS/Fargate
- **Menor complexidade** operacional
- **Managed service** totalmente gerenciado
- **Integração nativa** com AWS services
- **Custo potencialmente menor** para workloads simples

## 🔧 Comandos Úteis

### Build e Test Local
```bash
# Build da imagem
docker build -t devops-platform:latest .

# Test da aplicação
docker run --rm -p 8080:8080 devops-platform:latest

# Verificar health check
curl http://localhost:8080/health?simple

# Logs do container
docker logs -f devops-platform

# Shell no container (debug)
docker exec -it devops-platform /bin/sh
```

### Análise de Segurança
```bash
# Scan de vulnerabilidades
docker run --rm -v $(pwd):/app clair-scanner:latest \
  --ip $(ip route | awk 'NR==1{print $9}') \
  devops-platform:latest

# Análise de imagem
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/app \
  anchore/syft devops-platform:latest
```

## 📈 Otimizações Implementadas

### Performance
- [x] **Multi-stage builds** - Reduz tamanho da imagem
- [x] **OPcache habilitado** - Cache de bytecode PHP
- [x] **Gzip compression** - Reduz tráfego de rede
- [x] **Static file caching** - Cache de assets por 1 ano
- [x] **Keep-alive connections** - Reutiliza conexões TCP

### Segurança
- [x] **Usuário não-root** - Princípio de menor privilégio
- [x] **Security headers** - Proteção contra XSS, CSRF, etc.
- [x] **File access control** - Nega acesso a arquivos sensíveis
- [x] **PHP hardening** - Configurações seguras
- [x] **Port non-privileged** - Porta 8080 ao invés de 80

### Observabilidade
- [x] **Health checks** - Múltiplos tipos para diferentes usos
- [x] **Structured logging** - Logs em formato JSON
- [x] **Application metrics** - Métricas de performance
- [x] **Error tracking** - Log de erros estruturado

## 🎯 Próximos Passos

### Curto Prazo
- [ ] Implementar testes automatizados (PHPUnit)
- [ ] Configurar GitHub Actions para CI
- [ ] Adicionar análise de código (PHPStan, PHP CS Fixer)
- [ ] Implementar cache Redis

### Médio Prazo
- [ ] Terraform para infraestrutura AWS
- [ ] Kubernetes manifests (Deployment, Service, Ingress)
- [ ] Helm charts para deployment
- [ ] Monitoring com Prometheus/Grafana

### Longo Prazo
- [ ] Service Mesh (Istio) para microservices
- [ ] GitOps com ArgoCD
- [ ] Disaster Recovery automatizado
- [ ] Chaos Engineering

## 👥 Contribuição

Este projeto foi desenvolvido como parte de um teste técnico de DevOps, demonstrando:

- ✅ Containerização com melhores práticas
- ✅ Segurança aplicada desde o design
- ✅ Observabilidade built-in
- ✅ Documentação técnica completa
- ✅ Planejamento de infraestrutura moderna

---

**Desenvolvido por:** DevOps Team  
**Versão:** 2.1.3  
**Licença:** MIT  
**Data:** 2025

> 💡 **Nota**: Este projeto demonstra uma fundação sólida para modernização de aplicações legadas, aplicando princípios de DevOps, segurança e observabilidade desde o início.