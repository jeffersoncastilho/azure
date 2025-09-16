#!/usr/bin/env bash
# App Service Managed Certificate: emite e vincula (SNI) um certificado SSL grátis
# e gerenciado pra um domínio customizado já validado no App Service.
# Artigo: https://jeffersoncastilho.com.br/2025/09/16/app-service-managed-certificate/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
HOSTNAME="${HOSTNAME:?defina HOSTNAME (ex: www.meusite.com.br)}"

echo "==> Garantindo que o hostname está adicionado ao App Service"
az webapp config hostname add \
    --webapp-name "$APP" \
    --resource-group "$RG" \
    --hostname "$HOSTNAME" || echo "(hostname já existe, seguindo)"

echo "==> Emitindo o certificado gerenciado gratuito"
thumbprint=$(az webapp config ssl create \
    --resource-group "$RG" \
    --name "$APP" \
    --hostname "$HOSTNAME" \
    --query thumbprint -o tsv)
echo "thumbprint: $thumbprint"

echo "==> Vinculando via SNI"
az webapp config ssl bind \
    --resource-group "$RG" \
    --name "$APP" \
    --certificate-thumbprint "$thumbprint" \
    --ssl-type SNI

echo "==> Certificados vinculados:"
az webapp config ssl list \
    --resource-group "$RG" \
    -o table

echo "==> Concluído. A renovação automática acontece ~45 dias antes do vencimento,"
echo "    desde que o DNS/hostname não seja alterado."
