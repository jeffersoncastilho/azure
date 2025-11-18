# Deploy do App Service via GitHub Actions (Azure CLI + OIDC)

Script Azure CLI que configura o deploy contínuo do App Service via GitHub Actions usando **OIDC** (sem publish profile, sem secret de longa duração) — com um único comando.

## 📌 Visão Geral

- `setup-github-actions.sh`: roda `az webapp deployment github-actions add --login-with-github`, que cria o app registration, a credencial federada (federated identity) e já commita o workflow no repositório indicado
- `workflow-exemplo.yml`: exemplo do workflow gerado, mostrando o login via OIDC (`azure/login@v2`) e o deploy (`azure/webapps-deploy@v3`), com comentário de como publicar num slot em vez de produção direto

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Owner/Contributor + acesso pra criar app registrations no Azure AD
- **App Service** já existente
- Repositório no **GitHub** com permissão de admin (pra autorizar a integração e criar o workflow)
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export REPO="minhaorg/meurepo"
export BRANCH="main"

chmod +x setup-github-actions.sh
./setup-github-actions.sh
```

O comando abre um fluxo de device code: copie o código exibido, autorize numa página do GitHub, e a CLI cuida do resto.

> O artigo completo (incluindo por que OIDC é preferível ao publish profile e a tabela de troubleshooting) está em:
> **https://jeffersoncastilho.com.br/2025/11/18/deploy-app-service-github-actions/**
