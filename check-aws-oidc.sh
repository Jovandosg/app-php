#!/bin/bash

echo "=========================================="
echo "Diagnóstico AWS OIDC + GitHub Actions"
echo "=========================================="
echo ""

echo "1. Verificando OIDC Provider..."
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com

if [ $? -eq 0 ]; then
    echo "✅ OIDC Provider encontrado"
else
    echo "❌ OIDC Provider NÃO encontrado"
    echo ""
    echo "Execute este comando para criar:"
    echo "aws iam create-open-id-connect-provider \\"
    echo "  --url https://token.actions.githubusercontent.com \\"
    echo "  --client-id-list sts.amazonaws.com \\"
    echo "  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1"
fi

echo ""
echo "2. Verificando Trust Policy da Role..."
aws iam get-role --role-name GitHubActionRepoApp --query 'Role.AssumeRolePolicyDocument' --output json

echo ""
echo "3. Verificando Permissões da Role..."
aws iam list-attached-role-policies --role-name GitHubActionRepoApp

echo ""
echo "4. Verificando Inline Policies da Role..."
aws iam list-role-policies --role-name GitHubActionRepoApp

echo ""
echo "=========================================="
echo "Fim do Diagnóstico"
echo "=========================================="
