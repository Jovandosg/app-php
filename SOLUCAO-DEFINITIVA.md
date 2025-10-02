# ⚠️ SOLUÇÃO DEFINITIVA - Via Console AWS

## O problema
O comando CLI não atualizou a Trust Policy corretamente. Vamos fazer via Console AWS.

---

## 🎯 PASSO A PASSO (Siga EXATAMENTE)

### **Passo 1: Verificar/Criar OIDC Provider**

1. Acesse o Console AWS: https://console.aws.amazon.com/iam/
2. No menu lateral, clique em **Identity providers**
3. Procure por um provider com URL: `token.actions.githubusercontent.com`

**Se NÃO existir:**
- Clique em **Add provider**
- Selecione **OpenID Connect**
- **Provider URL**: `https://token.actions.githubusercontent.com`
- Clique em **Get thumbprint** (vai preencher automaticamente)
- **Audience**: `sts.amazonaws.com`
- Clique em **Add provider**

**Se JÁ existir:**
- Clique nele e verifique se o Audience é `sts.amazonaws.com`
- Se não for, adicione clicando em **Add audience**

---

### **Passo 2: Atualizar Trust Policy da Role** ⚠️ CRÍTICO

1. No menu lateral do IAM, clique em **Roles**
2. Na busca, digite: `GitHubActionRepoApp`
3. Clique na role **GitHubActionRepoApp**
4. Clique na aba **Trust relationships**
5. Clique no botão **Edit trust policy**
6. **APAGUE TODO O CONTEÚDO** e cole EXATAMENTE isto:

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

7. Clique em **Update policy**
8. Você deve ver uma mensagem de sucesso

---

### **Passo 3: Verificar Permissões ECR**

1. Ainda na role **GitHubActionRepoApp**, clique na aba **Permissions**
2. Verifique se existe alguma policy relacionada ao ECR
3. Se **NÃO existir**, clique em **Add permissions** > **Create inline policy**
4. Clique na aba **JSON**
5. Cole este conteúdo:

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

6. Clique em **Next**
7. Nome da policy: `ECRAccessPolicy`
8. Clique em **Create policy**

---

### **Passo 4: Verificar Repositório ECR**

1. No console AWS, vá para **ECR** (Elastic Container Registry)
2. Certifique-se de estar na região **us-east-1** (N. Virginia)
3. Verifique se existe um repositório chamado **devops**
4. Se **NÃO existir**, crie um:
   - Clique em **Create repository**
   - Nome: `devops`
   - Deixe as outras opções padrão
   - Clique em **Create repository**

---

## 🧪 Testar

Após fazer TODAS as configurações acima, faça um novo push:

```bash
cd ~/devops-test-project/website/app-php
git add .
git commit -m "test: OIDC configuration fixed"
git push origin main
```

---

## 🔍 Checklist de Verificação

Antes de testar, confirme:

- [ ] OIDC Provider existe com URL `token.actions.githubusercontent.com`
- [ ] OIDC Provider tem audience `sts.amazonaws.com`
- [ ] Trust Policy da role foi SUBSTITUÍDA (não apenas editada)
- [ ] Trust Policy contém `repo:Jovandosg/devops-test-project:ref:refs/heads/main`
- [ ] Role tem permissões ECR (inline policy ou managed policy)
- [ ] Repositório ECR `devops` existe na região `us-east-1`
- [ ] Você está fazendo push na branch `main`

---

## ❓ Troubleshooting

### Se AINDA der erro:

1. **Verifique o nome EXATO do repositório no GitHub:**
   - Vá em: https://github.com/Jovandosg
   - Confirme o nome exato do repositório
   - Pode ser que seja `devops-test-project` ou outro nome

2. **Checklist de Verificação**
   Antes de testar, confirme:

   - [ ] OIDC Provider existe com URL `token.actions.githubusercontent.com`
   - [ ] OIDC Provider tem audience `sts.amazonaws.com`
   - [ ] Trust Policy da role foi SUBSTITUÍDA (não apenas editada)
   - [ ] Trust Policy contém `repo:Jovandosg/app-php:ref:refs/heads/main`
   - [ ] Role tem permissões ECR (inline policy ou managed policy)
   - [ ] Repositório ECR `devops` existe na região `us-east-1`
   - [ ] Você está fazendo push na branch `main`

### Se AINDA der erro:

1. **Verifique o nome EXATO do repositório no GitHub:**
   - Vá em: https://github.com/Jovandosg/app-php
   - Confirme o nome exato do repositório
   - O nome correto é: `app-php`

2. **Verifique se o repositório é público ou privado:**
   - Se for privado, pode precisar de configurações adicionais

3. **Tire um print da Trust Policy:**
   - IAM > Roles > GitHubActionRepoApp > Trust relationships
   - Tire um print e me mostre

4. **Verifique o ARN do OIDC Provider:**
   - IAM > Identity providers
   - Clique no provider do GitHub
   - Copie o ARN e confirme se é: `arn:aws:iam::975050217683:oidc-provider/token.actions.githubusercontent.com`
2. **IAM > Roles > GitHubActionRepoApp > Trust relationships** (mostrando a policy completa)
3. **IAM > Roles > GitHubActionRepoApp > Permissions** (mostrando as policies anexadas)
4. **GitHub > Seu repositório > Settings > Actions > General** (mostrando as configurações de workflow)

---

## 💡 Dica Importante

O erro `Not authorized to perform sts:AssumeRoleWithWebIdentity` geralmente significa:

1. ❌ OIDC Provider não existe
2. ❌ Trust Policy não está correta
3. ❌ Nome do repositório está errado na Trust Policy
4. ❌ Branch está errada na Trust Policy
5. ❌ ARN do OIDC Provider está errado na Trust Policy

Siga o passo a passo acima COM ATENÇÃO e deve funcionar! 🚀
