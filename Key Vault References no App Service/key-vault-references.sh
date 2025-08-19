#!/usr/bin/env bash
# Key Vault References nas Application Settings do App Service: habilita a Managed Identity,
# concede leitura de segredo via RBAC e troca um app setting em texto puro por uma referência resolvida
# automaticamente pela plataforma.
# Artigo: https://jeffersoncastilho.com.br/2025/08/19/key-vault-references-app-service/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
VAULT="${VAULT:?defina VAULT (nome do Key Vault)}"
SECRET_NAME="${SECRET_NAME:-db-password}"
APP_SETTING_NAME="${APP_SETTING_NAME:-DB_PASSWORD}"

echo "==> Habilitando a Managed Identity (system-assigned) do App Service"
az webapp identity assign \
    --name "$APP" \
    --resource-group "$RG" \
    --query principalId -o tsv

principalId=$(az webapp identity show --name "$APP" --resource-group "$RG" --query principalId -o tsv)
echo "principalId: $principalId"

echo "==> Concedendo a role 'Key Vault Secrets User' (modelo RBAC) no cofre"
vaultId=$(az keyvault show --name "$VAULT" --query id -o tsv)
az role assignment create \
    --role "Key Vault Secrets User" \
    --assignee "$principalId" \
    --scope "$vaultId"

echo "==> Apontando o app setting pra referência do Key Vault (sem versão = sempre a mais recente)"
secretUri="https://${VAULT}.vault.azure.net/secrets/${SECRET_NAME}/"
az webapp config appsettings set \
    --name "$APP" \
    --resource-group "$RG" \
    --settings "${APP_SETTING_NAME}=@Microsoft.KeyVault(SecretUri=${secretUri})"

echo "==> Concluído. Confira o status da resolução (Resolved/Disabled/Error) em:"
echo "    Portal → $APP → Configuration → Application settings, coluna Source"
