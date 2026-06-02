#!/usr/bin/env bash
# Criar o Azure Virtual WAN: provisiona o Resource Group, o recurso Virtual WAN
# (SKU Standard) e o Virtual Hub regional — a base sobre a qual VPN Gateway,
# filiais e Azure Firewall são adicionados nos passos seguintes da série.
# Artigo: https://jeffersoncastilho.com.br/2026/06/02/criar-o-azure-virtual-wan/
set -euo pipefail

# ── Identificação ─────────────────────────────────────────────────────────────
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION="eastus"

# ── Nomes dos Recursos ────────────────────────────────────────────────────────
RESOURCE_GROUP="rg-vwan-castilho"
VWAN_NAME="vwan-castilho"
HUB_NAME="vhub-castilho-eastus"

# ── Endereçamento do Hub ──────────────────────────────────────────────────────
# IMPORTANTE: use um bloco /24 exclusivo, não utilizado em nenhuma VNet ou filial
HUB_ADDRESS_PREFIX="10.0.0.0/24"

echo "==> Pré-requisitos: registrando o provider de rede (idempotente)"
az provider register --namespace Microsoft.Network
az provider show --namespace Microsoft.Network --query "registrationState" -o tsv

echo "==> Passo 1 — Criando o Resource Group"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags projeto="vwan-castilho" ambiente="producao" responsavel="seu-email@empresa.com"

az group show --name "$RESOURCE_GROUP" \
  --query "{nome:name, local:location, status:properties.provisioningState}" -o table

echo "==> Passo 2 — Criando o Virtual WAN (SKU Standard — não pode ser alterado depois)"
az network vwan create \
  --name "$VWAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --type Standard \
  --tags projeto="vwan-castilho" ambiente="producao"

VWAN_ID=$(az network vwan show \
  --name "$VWAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)
echo "Virtual WAN criado! ID: $VWAN_ID"

echo "==> Passo 3 — Criando o Virtual Hub (provisionamento leva 30-60 min)"
az network vhub create \
  --name "$HUB_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --vwan "$VWAN_NAME" \
  --address-prefix "$HUB_ADDRESS_PREFIX" \
  --sku Standard \
  --tags projeto="vwan-castilho" ambiente="producao"

echo "Virtual Hub em provisionamento — aguarde routingState: Provisioned."

# Opcional: hub secundário em outra região (hubs do mesmo Virtual WAN se
# interconectam automaticamente via backbone da Microsoft, sem peering manual)
# HUB_NAME_BR="vhub-castilho-brazilsouth"
# HUB_ADDRESS_PREFIX_BR="10.0.1.0/24"
# az network vhub create \
#   --name "$HUB_NAME_BR" \
#   --resource-group "$RESOURCE_GROUP" \
#   --location "brazilsouth" \
#   --vwan "$VWAN_NAME" \
#   --address-prefix "$HUB_ADDRESS_PREFIX_BR" \
#   --sku Standard

echo "==> Verificando o provisionamento"
az network vwan show --name "$VWAN_NAME" --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, tipo:type, status:provisioningState}" -o table
az network vhub show --name "$HUB_NAME" --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, status:provisioningState, roteamento:routingState, endereco:addressPrefix}" -o table
az network vhub list --resource-group "$RESOURCE_GROUP" \
  --query "[].{Nome:name, Regiao:location, Status:provisioningState, Roteamento:routingState}" -o table

echo "Virtual WAN e Virtual Hub criados. Próximo passo: VPN Gateway e filiais."
