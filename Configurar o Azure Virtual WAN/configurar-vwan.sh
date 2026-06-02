#!/usr/bin/env bash
# Configurar o Azure Virtual WAN: cria o Virtual WAN, o Virtual Hub, o VPN Gateway,
# registra um VPN Site (filial), conecta uma VNet spoke ao hub e habilita o Routing
# Intent (Azure Firewall no hub) para inspeção centralizada de tráfego.
# Artigo: https://jeffersoncastilho.com.br/2026/06/02/configurar-azure-virtual-wan/
set -euo pipefail

# ── Identificação ─────────────────────────────────────────────────────────────
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION="eastus"

# ── Nomes dos Recursos ────────────────────────────────────────────────────────
RESOURCE_GROUP="rg-vwan-castilho"
VWAN_NAME="vwan-castilho"
HUB_NAME="vhub-castilho-eastus"
VPN_GW_NAME="vpngw-castilho"
VPN_SITE_NAME="vpnsite-filial-sp"
VPN_CONNECTION_NAME="conn-filial-sp"
VNET_NAME="vnet-spoke-castilho"
VNET_CONNECTION_NAME="conn-vnet-spoke"
FIREWALL_POLICY_NAME="fw-policy-castilho"
FIREWALL_NAME="fw-castilho"

# ── Endereçamento ─────────────────────────────────────────────────────────────
HUB_ADDRESS_PREFIX="10.0.0.0/23"          # Endereço do hub (mín. /24)
VNET_ADDRESS_PREFIX="10.10.0.0/16"        # Endereço da VNet spoke
BRANCH_ADDRESS_PREFIX="192.168.1.0/24"    # CIDR da filial on-premises
BRANCH_PUBLIC_IP="${BRANCH_PUBLIC_IP:?defina o IP público do roteador da filial}"

# ── VPN ───────────────────────────────────────────────────────────────────────
VPN_PSK="$(openssl rand -base64 32)"      # Pré-shared key aleatória

echo "==> Registrando o provider de rede (idempotente)"
az provider register --namespace Microsoft.Network
az provider show --namespace Microsoft.Network --query "registrationState" -o tsv

echo "==> Passo 1 — Criando o Resource Group"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags projeto="vwan-castilho" ambiente="producao"

echo "==> Passo 2 — Criando o Virtual WAN (tipo Standard)"
az network vwan create \
  --name "$VWAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --type Standard \
  --tags projeto="vwan-castilho" ambiente="producao"

echo "==> Passo 3 — Criando o Virtual Hub (provisionamento leva 30-60 min)"
az network vhub create \
  --name "$HUB_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --vwan "$VWAN_NAME" \
  --address-prefix "$HUB_ADDRESS_PREFIX" \
  --sku Standard \
  --tags projeto="vwan-castilho" ambiente="producao"

echo "==> Passo 4 — Criando o VPN Gateway no Hub (1 unidade = 500 Mbps)"
az network vpn-gateway create \
  --name "$VPN_GW_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --vhub "$HUB_NAME" \
  --scale-unit 1 \
  --tags projeto="vwan-castilho" ambiente="producao"

echo "==> Passo 5 — Registrando o VPN Site (filial)"
az network vpn-site create \
  --name "$VPN_SITE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --virtual-wan "$VWAN_NAME" \
  --ip-address "$BRANCH_PUBLIC_IP" \
  --address-prefixes "$BRANCH_ADDRESS_PREFIX" \
  --device-vendor "Cisco" \
  --device-model "ASR1000" \
  --link-speed 100 \
  --tags projeto="vwan-castilho" filial="sao-paulo"

VPN_SITE_ID=$(az network vpn-site show \
  --name "$VPN_SITE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)

echo "==> Passo 6 — Conectando o VPN Site ao Hub (túnel IPsec/IKEv2)"
az network vpn-gateway connection create \
  --name "$VPN_CONNECTION_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --gateway-name "$VPN_GW_NAME" \
  --vpn-site "$VPN_SITE_ID" \
  --shared-key "$VPN_PSK" \
  --enable-bgp false \
  --protocol-type IKEv2 \
  --connection-bandwidth 100

echo "==> Passo 7 — Conectando uma VNet spoke ao Virtual Hub"
az network vnet create \
  --name "$VNET_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --address-prefixes "$VNET_ADDRESS_PREFIX" \
  --tags projeto="vwan-castilho" ambiente="producao"

VNET_ID=$(az network vnet show \
  --name "$VNET_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)

az network vhub connection create \
  --name "$VNET_CONNECTION_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --vhub-name "$HUB_NAME" \
  --remote-vnet "$VNET_ID"

echo "==> Passo 8 — Habilitando Routing Intent (Azure Firewall centralizado no hub)"
az network firewall policy create \
  --name "$FIREWALL_POLICY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Premium \
  --threat-intel-mode Alert

az network firewall create \
  --name "$FIREWALL_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --vhub "$HUB_NAME" \
  --sku AZFW_Hub \
  --tier Premium \
  --firewall-policy "$FIREWALL_POLICY_NAME" \
  --public-ip-count 1

FIREWALL_ID=$(az network firewall show \
  --name "$FIREWALL_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)

az network vhub routing-intent create \
  --name "routing-intent-castilho" \
  --resource-group "$RESOURCE_GROUP" \
  --vhub "$HUB_NAME" \
  --routing-policies \
    name=PrivateTrafficPolicy,destinations=PrivateTraffic,nexthop="$FIREWALL_ID" \
    name=InternetTrafficPolicy,destinations=Internet,nexthop="$FIREWALL_ID"

echo "==> Verificando a configuração"
az network vwan show --name "$VWAN_NAME" --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, tipo:type, status:provisioningState}"
az network vhub show --name "$HUB_NAME" --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, status:provisioningState, routingState:routingState, endereco:addressPrefix}"
az network vpn-gateway connection list --resource-group "$RESOURCE_GROUP" --gateway-name "$VPN_GW_NAME" \
  --query "[].{Nome:name, Status:provisioningState, Conexao:connectionStatus}" -o table

echo "Azure Virtual WAN configurado com sucesso."
