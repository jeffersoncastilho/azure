#!/usr/bin/env bash
# Deployment Slots no App Service: cria o slot de staging, publica um deploy nele,
# marca app settings como "sticky" e executa o swap com preview (warm-up antes de trocar).
# Artigo: https://jeffersoncastilho.com.br/2025/08/05/deployment-slots-app-service/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
PLAN="${PLAN:?defina PLAN (nome do App Service Plan)}"
SRC_ZIP="${SRC_ZIP:-./app.zip}"

echo "==> Garantindo tier Standard ou superior (Deployment Slots exige S1+)"
az appservice plan update \
    --name "$PLAN" \
    --resource-group "$RG" \
    --sku S1

echo "==> Criando o slot de staging (clonado da config de produção)"
az webapp deployment slot create \
    --name "$APP" \
    --resource-group "$RG" \
    --slot staging \
    --configuration-source "$APP"

az webapp deployment slot list \
    --name "$APP" \
    --resource-group "$RG" \
    -o table

echo "==> Publicando o deploy no slot de staging"
az webapp deploy \
    --name "$APP" \
    --resource-group "$RG" \
    --slot staging \
    --src-path "$SRC_ZIP" \
    --type zip

echo "==> Marcando settings que não devem trocar no swap (sticky / slot settings)"
az webapp config appsettings set \
    --name "$APP" \
    --resource-group "$RG" \
    --slot staging \
    --slot-settings ENVIRONMENT=staging

echo "==> Swap com preview: fase 1 (aplica config de produção no staging, sem trocar tráfego)"
az webapp deployment slot swap \
    --name "$APP" \
    --resource-group "$RG" \
    --slot staging \
    --target-slot production \
    --action preview

echo "Valide agora em https://${APP}-staging.azurewebsites.net com a config real de produção."
read -rp "Pressione Enter para completar o swap (ou Ctrl+C pra abortar aqui)..."

echo "==> Swap com preview: fase 2 (completa o swap, troca o tráfego)"
az webapp deployment slot swap \
    --name "$APP" \
    --resource-group "$RG" \
    --slot staging \
    --target-slot production \
    --action swap

echo "==> Concluído. Pra rollback: az webapp deployment slot swap --name $APP --resource-group $RG --slot production --target-slot staging"
