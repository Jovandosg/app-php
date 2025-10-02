#!/bin/bash
# ==============================================================================
# Script para Build e Push de Imagem Docker para AWS ECR
# ==============================================================================
# Uso: ./push-ecr.sh [TAG_VERSION]
# Exemplo: ./push-ecr.sh v1.0.0
# Se não passar TAG_VERSION, usa apenas 'latest'
# ==============================================================================

set -e  # Para o script se houver erro

# ==============================================================================
# CONFIGURAÇÕES
# ==============================================================================
AWS_ACCOUNT_ID=975050217683
REGION=us-east-1
REPO_NAME=devops-test-project
LOCAL_IMAGE_NAME=devops-platform

# Pega a versão da linha de comando ou usa 'latest'
VERSION_TAG=${1:-latest}

# ==============================================================================
# CORES PARA OUTPUT
# ==============================================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ==============================================================================
# FUNÇÕES
# ==============================================================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==============================================================================
# INÍCIO DO SCRIPT
# ==============================================================================
log_info "Iniciando processo de build e push para ECR..."
log_info "Repositório: $REPO_NAME"
log_info "Tags: latest, $VERSION_TAG"

# ==============================================================================
# 1. VERIFICAR SE AWS CLI ESTÁ INSTALADO
# ==============================================================================
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI não está instalado. Instale com: sudo apt install awscli"
    exit 1
fi

# ==============================================================================
# 2. LOGIN NO ECR
# ==============================================================================
log_info "Fazendo login no ECR..."
aws ecr get-login-password --region $REGION \
| docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

if [ $? -eq 0 ]; then
    log_info "Login no ECR realizado com sucesso!"
else
    log_error "Falha no login do ECR. Verifique suas credenciais AWS."
    exit 1
fi

# ==============================================================================
# 3. VERIFICAR/CRIAR REPOSITÓRIO NO ECR
# ==============================================================================
log_info "Verificando se o repositório '$REPO_NAME' existe no ECR..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log_info "Repositório '$REPO_NAME' já existe."
else
    log_warn "Repositório '$REPO_NAME' não existe. Criando..."
    aws ecr create-repository --repository-name $REPO_NAME --region $REGION
    log_info "Repositório '$REPO_NAME' criado com sucesso!"
fi

# ==============================================================================
# 4. BUILD DA IMAGEM DOCKER
# ==============================================================================
log_info "Construindo imagem Docker..."
docker build -t $LOCAL_IMAGE_NAME:latest .

if [ $? -eq 0 ]; then
    log_info "Build da imagem concluído com sucesso!"
else
    log_error "Falha no build da imagem Docker."
    exit 1
fi

# ==============================================================================
# 5. TAGGEAR IMAGEM PARA O ECR
# ==============================================================================
ECR_URI=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME

log_info "Taggeando imagem para o ECR..."

# Tag 'latest'
docker tag $LOCAL_IMAGE_NAME:latest $ECR_URI:latest
log_info "Tag criada: $ECR_URI:latest"

# Tag com versão (se diferente de 'latest')
if [ "$VERSION_TAG" != "latest" ]; then
    docker tag $LOCAL_IMAGE_NAME:latest $ECR_URI:$VERSION_TAG
    log_info "Tag criada: $ECR_URI:$VERSION_TAG"
fi

# ==============================================================================
# 6. PUSH DA IMAGEM PARA O ECR
# ==============================================================================
log_info "Enviando imagem 'latest' para o ECR..."
docker push $ECR_URI:latest

if [ $? -eq 0 ]; then
    log_info "Push da tag 'latest' concluído com sucesso!"
else
    log_error "Falha no push da tag 'latest'."
    exit 1
fi

# Push da versão específica (se diferente de 'latest')
if [ "$VERSION_TAG" != "latest" ]; then
    log_info "Enviando imagem '$VERSION_TAG' para o ECR..."
    docker push $ECR_URI:$VERSION_TAG
    
    if [ $? -eq 0 ]; then
        log_info "Push da tag '$VERSION_TAG' concluído com sucesso!"
    else
        log_error "Falha no push da tag '$VERSION_TAG'."
        exit 1
    fi
fi

# ==============================================================================
# 7. RESUMO FINAL
# ==============================================================================
echo ""
log_info "=========================================="
log_info "✅ PROCESSO CONCLUÍDO COM SUCESSO!"
log_info "=========================================="
log_info "Imagens disponíveis no ECR:"
log_info "  - $ECR_URI:latest"
if [ "$VERSION_TAG" != "latest" ]; then
    log_info "  - $ECR_URI:$VERSION_TAG"
fi
echo ""
log_info "Para usar a imagem em produção:"
log_info "  docker pull $ECR_URI:latest"
echo ""
log_info "Para listar todas as imagens no repositório:"
log_info "  aws ecr list-images --repository-name $REPO_NAME --region $REGION"
echo ""

# ==============================================================================
# FIM DO SCRIPT
# ==============================================================================