#!/usr/bin/env bash
# Health Check Path no App Service: configura o endpoint de saúde e ajusta
# a tolerância a falhas antes de tirar uma instância de rotação.
# Artigo: https://jeffersoncastilho.com.br/2025/10/21/health-check-path-app-service/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
HEALTH_PATH="${HEALTH_PATH:-/health}"
MAX_PING_FAILURES="${MAX_PING_FAILURES:-10}"

echo "==> Configurando o Health Check Path"
az webapp config set \
    --name "$APP" \
    --resource-group "$RG" \
    --generic-configurations "{\"healthCheckPath\": \"${HEALTH_PATH}\"}"

echo "==> Ajustando a tolerância a falhas (WEBSITE_HEALTHCHECK_MAXPINGFAILURES)"
az webapp config appsettings set \
    --name "$APP" \
    --resource-group "$RG" \
    --settings WEBSITE_HEALTHCHECK_MAXPINGFAILURES="$MAX_PING_FAILURES"

echo "==> Concluído. Só tem efeito de balanceamento com 2+ instâncias."
echo "    Lembre-se: o endpoint deve validar dependências REALMENTE críticas, não tudo."
