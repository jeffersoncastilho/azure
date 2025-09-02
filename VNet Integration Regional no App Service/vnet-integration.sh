#!/usr/bin/env bash
# VNet Integration Regional no App Service: cria uma subnet dedicada delegada,
# ativa a integração e (opcionalmente) roteia todo o tráfego de saída pela VNet.
# Artigo: https://jeffersoncastilho.com.br/2025/09/02/vnet-integration-regional-app-service/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
VNET="${VNET:?defina VNET (nome da rede virtual)}"
SUBNET="${SUBNET:-snet-integration}"
SUBNET_PREFIX="${SUBNET_PREFIX:-10.0.1.0/27}"
ROUTE_ALL="${ROUTE_ALL:-false}"

echo "==> Criando a subnet dedicada, delegada a Microsoft.Web/serverFarms"
az network vnet subnet create \
    --resource-group "$RG" \
    --vnet-name "$VNET" \
    --name "$SUBNET" \
    --address-prefixes "$SUBNET_PREFIX" \
    --delegations Microsoft.Web/serverFarms

echo "==> Ativando a VNet Integration Regional"
az webapp vnet-integration add \
    --name "$APP" \
    --resource-group "$RG" \
    --vnet "$VNET" \
    --subnet "$SUBNET"

az webapp vnet-integration list \
    --name "$APP" \
    --resource-group "$RG" \
    -o table

if [ "$ROUTE_ALL" = "true" ]; then
    echo "==> Roteando TODO o tráfego de saída pela VNet (vnetRouteAllEnabled)"
    az webapp config set \
        --name "$APP" \
        --resource-group "$RG" \
        --generic-configurations '{"vnetRouteAllEnabled": true}'
fi

echo "==> Concluído. Pra validar conectividade, use o console SSH do Kudu:"
echo "    https://${APP}.scm.azurewebsites.net/webssh/host"
