# Configuração OIDC - GitHub Actions + AWS

## Problema
Erro: `Not authorized to perform sts:AssumeRoleWithWebIdentity`

## Solução para o Repositório: Jovandosg/devops-test-project

### 1. Criar/Atualizar o Identity Provider do GitHub no IAM

No console AWS, vá para **IAM > Identity providers**:

**Se não existir, crie um novo:**
- Clique em **Add provider**
- Escolha **OpenID Connect**
- **Provider URL**: `https://token.actions.githubusercontent.com`
- Clique em **Get thumbprint**
- **Audience**: `sts.amazonaws.com`
- Clique em **Add provider**

### 2. Atualizar a Trust Policy da Role IAM

Acesse a role `GitHubActionRepoApp` no IAM:

1. Vá para **IAM > Roles**
2. Procure e clique em `GitHubActionRepoApp`
3. Vá na aba **Trust relationships**
4. Clique em **Edit trust policy**
5. Cole a seguinte política:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::975050217683:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Jovandosg/app-php:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

6. Clique em **Update policy**

### 3. Verificar Permissões da Role para ECR

A role também precisa ter permissões para acessar o ECR:

1. Na mesma role `GitHubActionRepoApp`, vá na aba **Permissions**
2. Verifique se existe uma policy com permissões ECR
3. Se não existir, clique em **Add permissions > Attach policies**
4. Ou crie uma inline policy com:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ],
      "Resource": "*"
    }
  ]
}
```

### 4. Comandos AWS CLI (Alternativa Rápida)

Se preferir usar CLI, execute os comandos abaixo:

#### 4.1. Criar o OIDC Provider (se não existir)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### 4.2. Criar arquivo trust-policy.json

```bash
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::975050217683:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Jovandosg/app-php:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
```

#### 4.3. Atualizar a Trust Policy da Role

```bash
aws iam update-assume-role-policy \
  --role-name GitHubActionRepoApp \
  --policy-document file://trust-policy.json
```

#### 4.4. Criar e anexar policy de permissões ECR

```bash
cat > ecr-permissions.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionRepoApp \
  --policy-name ECRAccessPolicy \
  --policy-document file://ecr-permissions.json
```

## Checklist de Verificação

- [ ] OIDC Provider criado no IAM (`token.actions.githubusercontent.com`)
- [ ] Trust Policy da role atualizada com `repo:Jovandosg/devops-test-project:*`
- [ ] Permissões ECR anexadas à role
- [ ] ARN da role correto no workflow: `arn:aws:iam::975050217683:role/GitHubActionRepoApp`
- [ ] Repositório ECR existe: `975050217683.dkr.ecr.us-east-1.amazonaws.com/devops`

## Testando

Após fazer as alterações na AWS, faça um novo push para testar:

```bash
cd app-php
git add .
git commit -m "test: validating OIDC configuration"
git push origin main
```

## Troubleshooting

### Se ainda der erro de permissão:

1. **Verifique o OIDC Provider ARN**: Certifique-se que o ARN no Trust Policy corresponde ao provider criado
2. **Verifique o nome do repositório**: Deve ser exatamente `Jovandosg/devops-test-project`
3. **Verifique a branch**: O workflow está configurado para `main`, certifique-se que está fazendo push nessa branch
4. **Aguarde alguns segundos**: Às vezes leva alguns segundos para as permissões propagarem

### Se der erro no ECR:

1. Verifique se o repositório `devops` existe no ECR
2. Verifique se a região está correta (`us-east-1`)
3. Verifique se a role tem permissões de ECR

## Resumo Visual

```
GitHub Actions (seu workflow)
    ↓
Solicita token OIDC
    ↓
AWS STS valida com OIDC Provider
    ↓
Verifica Trust Policy da Role
    ↓
Concede credenciais temporárias
    ↓
GitHub Actions usa credenciais para acessar ECR
```
