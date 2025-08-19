# Key Vault References no App Service (Azure CLI)

Script Azure CLI que habilita a Managed Identity do App Service, concede leitura de segredo no Key Vault via RBAC e troca um app setting em texto puro por uma **Key Vault Reference** — resolvida automaticamente pela plataforma em tempo de execução.

## 📌 Visão Geral

O script `key-vault-references.sh` realiza:

- Habilitação da Managed Identity (system-assigned) do App Service
- Concessão da role **Key Vault Secrets User** (RBAC) pro cofre indicado
- Configuração do app setting com a sintaxe `@Microsoft.KeyVault(SecretUri=...)`, sem versão fixa (sempre resolve pra versão mais recente do segredo)

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Owner/User Access Administrator (pra criar role assignment)
- **App Service** e **Key Vault** já existentes
- O segredo já criado no Key Vault
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export VAULT="nome-do-seu-key-vault"
export SECRET_NAME="db-password"
export APP_SETTING_NAME="DB_PASSWORD"

chmod +x key-vault-references.sh
./key-vault-references.sh
```

> O artigo completo (incluindo o equivalente em PowerShell e a tabela de troubleshooting) está em:
> **https://jeffersoncastilho.com.br/2025/08/19/key-vault-references-app-service/**
