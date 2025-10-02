# Solução Rápida - Erro OIDC GitHub Actions

## ⚠️ Erro Atual
```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

## 🔍 Diagnóstico Rápido

Execute estes comandos para verificar o problema:

### 1. Verificar se o OIDC Provider existe
```bash
aws iam list-open-id-connect-providers
```

**Resultado esperado**: Deve aparecer algo como:
```json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::975050217683:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```

Se **NÃO aparecer**, o provider não existe. Pule para a seção "Solução Completa" abaixo.

### 2. Verificar a Trust Policy atual
```bash
aws iam get-role --role-name GitHubActionRepoApp --query 'Role.AssumeRolePolicyDocument'
```

Compare o resultado com a política correta que deve estar configurada.

---

## ✅ Solução Completa (Execute na Ordem)

### Passo 1: Criar o OIDC Provider (se não existir)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Nota**: Se der erro dizendo que já existe, tudo bem! Prossiga para o próximo passo.

### Passo 2: Criar arquivo com a Trust Policy correta

Crie um arquivo chamado `trust-policy.json` com este conteúdo:

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

### Passo 3: Atualizar a Trust Policy da Role

```bash
aws iam update-assume-role-policy \
  --role-name GitHubActionRepoApp \
  --policy-document file://trust-policy.json
```

### Passo 4: Verificar se a role tem permissões ECR

```bash
aws iam list-attached-role-policies --role-name GitHubActionRepoApp
aws iam list-role-policies --role-name GitHubActionRepoApp
```

Se não houver nenhuma policy relacionada ao ECR, crie uma:

```bash
cat > ecr-policy.json << 'EOF'
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
  --policy-document file://ecr-policy.json

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
```

---

## 🎯 Solução Alternativa: Via Console AWS

Se preferir usar o console:

### 1. Criar OIDC Provider
1. Acesse **IAM > Identity providers**
2. Clique em **Add provider**
3. Selecione **OpenID Connect**
4. **Provider URL**: `https://token.actions.githubusercontent.com`
5. Clique em **Get thumbprint**
6. **Audience**: `sts.amazonaws.com`
7. Clique em **Add provider**

### 2. Atualizar Trust Policy
1. Acesse **IAM > Roles > GitHubActionRepoApp**
2. Aba **Trust relationships**
3. Clique em **Edit trust policy**
4. Cole a política JSON do Passo 2 acima
5. Clique em **Update policy**

### 3. Adicionar Permissões ECR
1. Na mesma role, aba **Permissions**
2. Clique em **Add permissions > Create inline policy**
3. Aba **JSON**
4. Cole a política ECR do Passo 4 acima

---

## 🔍 Checklist de Verificação

- [ ] OIDC Provider criado no IAM (`token.actions.githubusercontent.com`)
- [ ] Trust Policy da role atualizada com `repo:Jovandosg/app-php:ref:refs/heads/main`
- [ ] Permissões ECR anexadas à role
- [ ] ARN da role correto no workflow: `arn:aws:iam::975050217683:role/GitHubActionRepoApp`
- [ ] Repositório ECR existe: `975050217683.dkr.ecr.us-east-1.amazonaws.com/devops`
5. Nome: `ECRAccessPolicy`
6. Clique em **Create policy**

---

## 🧪 Testar

Após fazer as configurações, faça um novo push:

```bash
git add .
git commit -m "test: OIDC configuration"
git push origin main
```

---

## 🔧 Troubleshooting Adicional

### Se ainda der erro, verifique:

1. **Nome do repositório está correto?**
   - Deve ser exatamente: `Jovandosg/app-php`
   - Verifique no GitHub se o nome está correto (case-sensitive)

2. **Branch está correta?**
   - O workflow está configurado para `main`
   - Verifique se você está fazendo push na branch `main`

3. **ARN do OIDC Provider está correto?**
   - Execute: `aws iam list-open-id-connect-providers`
   - O ARN deve ser: `arn:aws:iam::975050217683:oidc-provider/token.actions.githubusercontent.com`

4. **Aguarde alguns segundos**
   - Às vezes leva 10-30 segundos para as permissões propagarem

5. **Verifique os logs do GitHub Actions**
   - Vá no repositório > Actions > Clique no workflow que falhou
   - Expanda o step "Configure AWS Credentials"
   - Procure por mensagens de erro mais detalhadas
   - Execute: `aws iam list-open-id-connect-providers`
   - O ARN deve ser: `arn:aws:iam::975050217683:oidc-provider/token.actions.githubusercontent.com`

4. **Aguarde alguns segundos**
   - Às vezes leva 10-30 segundos para as permissões propagarem

5. **Verifique os logs do GitHub Actions**
   - Vá no repositório > Actions > Clique no workflow que falhou
   - Expanda o step "Configure AWS Credentials"
   - Procure por mensagens de erro mais detalhadas

---

## 📝 Checklist Final

- [ ] OIDC Provider criado com URL `https://token.actions.githubusercontent.com`
- [ ] OIDC Provider tem audience `sts.amazonaws.com`
- [ ] Trust Policy da role atualizada com o repositório correto
- [ ] Trust Policy usa `ref:refs/heads/main` (não `*`)
- [ ] Role tem permissões ECR (GetAuthorizationToken, PutImage, etc)
- [ ] Repositório ECR `devops` existe na região `us-east-1`
- [ ] Nome do repositório GitHub está correto: `Jovandosg/devops-test-project`
- [ ] Push está sendo feito na branch `main`

---

## 💡 Comando Único (All-in-One)

Se quiser executar tudo de uma vez via CLI:

```bash
# 1. Criar OIDC Provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null || echo "Provider já existe"

# 2. Criar e aplicar Trust Policy
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

aws iam update-assume-role-policy \
  --role-name GitHubActionRepoApp \
  --policy-document file://trust-policy.json

# 3. Continuar com o resto do comando...
          "token.actions.githubusercontent.com:sub": "repo:Jovandosg/devops-test-project:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

aws iam update-assume-role-policy \
  --role-name GitHubActionRepoApp \
  --policy-document file://trust-policy.json

# 3. Criar e aplicar ECR Policy
cat > ecr-policy.json << 'EOF'
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
  --policy-document file://ecr-policy.json

echo ""
echo "✅ Configuração concluída!"
echo "Agora faça um push para testar: git push origin main"
```
