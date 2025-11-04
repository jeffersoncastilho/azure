#!/usr/bin/env bash
# Log Stream e App Service Logs: ativa os 4 tipos de log, faz tail em tempo real
# e (opcionalmente) migra o Application Logging pra Blob Storage (log persistente, sem limite de 12h).
# Artigo: https://jeffersoncastilho.com.br/2025/11/04/log-stream-app-service-logs/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
LEVEL="${LEVEL:-information}"
USE_BLOB="${USE_BLOB:-false}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-}"
BLOB_CONTAINER="${BLOB_CONTAINER:-applogs}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

echo "==> Ativando Application Logging (filesystem), Web Server Logging, Detailed Errors e Failed Request Tracing"
az webapp log config \
    --name "$APP" \
    --resource-group "$RG" \
    --application-logging filesystem \
    --level "$LEVEL" \
    --web-server-logging filesystem \
    --detailed-error-messages true \
    --failed-request-tracing true

if [ "$USE_BLOB" = "true" ]; then
    : "${STORAGE_ACCOUNT:?defina STORAGE_ACCOUNT pra usar USE_BLOB=true}"
    echo "==> Migrando Application Logging pra Blob Storage (sem o limite de 12h do filesystem)"
    sasUrl=$(az storage container generate-sas \
        --name "$BLOB_CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --permissions rwdl \
        --expiry "$(date -u -d "+30 days" '+%Y-%m-%dT%H:%MZ')" \
        --https-only \
        -o tsv)

    az webapp log config \
        --name "$APP" \
        --resource-group "$RG" \
        --application-logging azureblobstorage \
        --level "$LEVEL"

    az webapp config appsettings set \
        --name "$APP" \
        --resource-group "$RG" \
        --settings \
            DIAGNOSTICS_AZUREBLOBCONTAINERSASURL="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${BLOB_CONTAINER}?${sasUrl}" \
            DIAGNOSTICS_AZUREBLOBRETENTIONINDAYS="$RETENTION_DAYS"
fi

echo "==> Concluído. Pra acompanhar em tempo real:"
echo "    az webapp log tail --name $APP --resource-group $RG"
