#!/usr/bin/env bash
# Auto Heal no App Service: configura regras de erro 500 e requisições lentas
# pra reciclar o processo automaticamente, com proteção contra loop de reciclagem.
# Artigo: https://jeffersoncastilho.com.br/2025/10/07/auto-heal-app-service/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
STATUS_CODE="${STATUS_CODE:-500}"
STATUS_COUNT="${STATUS_COUNT:-20}"
SLOW_SECONDS="${SLOW_SECONDS:-00:00:10}"
SLOW_COUNT="${SLOW_COUNT:-50}"
TIME_INTERVAL="${TIME_INTERVAL:-00:05:00}"
MIN_PROCESS_TIME="${MIN_PROCESS_TIME:-00:01:00}"

echo "==> Configurando as regras de Auto Heal"
az webapp config set \
    --name "$APP" \
    --resource-group "$RG" \
    --generic-configurations "{
      \"autoHealEnabled\": true,
      \"autoHealRules\": {
        \"triggers\": {
          \"statusCodes\": [
            { \"status\": ${STATUS_CODE}, \"count\": ${STATUS_COUNT}, \"timeInterval\": \"${TIME_INTERVAL}\" }
          ],
          \"slowRequests\": {
            \"timeTaken\": \"${SLOW_SECONDS}\",
            \"count\": ${SLOW_COUNT},
            \"timeInterval\": \"${TIME_INTERVAL}\"
          }
        },
        \"actions\": {
          \"actionType\": \"Recycle\",
          \"minProcessExecutionTime\": \"${MIN_PROCESS_TIME}\"
        }
      }
    }"

echo "==> Configuração aplicada:"
az webapp config show \
    --name "$APP" \
    --resource-group "$RG" \
    --query "{autoHealEnabled:autoHealEnabled, autoHealRules:autoHealRules}"

echo "==> Concluído. Acompanhe eventos de reciclagem no Log Stream / Event Viewer (origem Auto-Healing)."
