#!/usr/bin/env bash
# Segurança Azure Virtual WAN com Firewall: conecta uma VNet spoke ao Virtual Hub,
# implanta o Azure Firewall Premium no hub (Secured Virtual Hub) e habilita o
# Routing Intent para forçar todo o tráfego — privado e de Internet — pela
# inspeção centralizada. Fecha a série de Azure Virtual WAN.
# Artigo: https://jeffersoncastilho.com.br/2026/06/02/seguranca-azure-virtual-wan/
set -euo pipefail

# ── Herdadas dos artigos anteriores ───────────────────────────────────────────
RESOURCE_GROUP="rg-vwan-castilho"
VWAN_NAME="vwan-castilho"
HUB_NAME="vhub-castilho-eastus"
LOCATION="eastus"

# ── VNet Spoke ────────────────────────────────────────────────────────────────
VNET_NAME="vnet-spoke-castilho"
VNET_ADDRESS_PREFIX="10.10.0.0/16"
VNET_CONNECTION_NAME="conn-vnet-spoke-castilho"

# ── Azure Firewall ────────────────────────────────────────────────────────────
FIREWALL_POLICY_NAME="fw-policy-castilho"
FIREWALL_NAME="fw-castilho"

# ── Routing Intent ────────────────────────────────────────────────────────────
ROUTING_INTENT_NAME="routing-intent-castilho"

echo "==> Passo 1 — Conectando a VNet spoke ao Virtual Hub"
az network vnet create \
  --name "$VNET_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --address-prefixes "$VNET_ADDRESS_PREFIX" \
  --tags projeto="vwan-castilho" ambiente="producao"

az network vnet subnet create \
  --name "snet-workload" \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --address-prefixes "10.10.1.0/24"

VNET_ID=$(az network vnet show \
  --name "$VNET_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)

az network vhub connection create \
  --name "$VNET_CONNECTION_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --vhub-name "$HUB_NAME" \
  --remote-vnet "$VNET_ID"

az network vhub connection show \
  --name "$VNET_CONNECTION_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --vhub-name "$HUB_NAME" \
  --query "{nome:name, status:provisioningState, vnet:remoteVnet.id}" -o table

echo "==> Passo 2 — Criando a Azure Firewall Policy (tier Premium: IDPS + TLS inspection)"
az network firewall policy create \
  --name "$FIREWALL_POLICY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Premium \
  --threat-intel-mode Alert \
  --tags projeto="vwan-castilho" ambiente="producao"

echo "==> Passo 3 — Implantando o Azure Firewall no Hub (SKU AZFW_Hub, ~10-20 min)"
az network firewall create \
  --name "$FIREWALL_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --vhub "$HUB_NAME" \
  --sku AZFW_Hub \
  --tier Premium \
  --firewall-policy "$FIREWALL_POLICY_NAME" \
  --public-ip-count 1 \
  --tags projeto="vwan-castilho" ambiente="producao"

FIREWALL_ID=$(az network firewall show \
  --name "$FIREWALL_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv)
echo "Azure Firewall ID: $FIREWALL_ID"

echo "==> Passo 4 — Configurando o Routing Intent (Zero Trust: tudo passa pelo Firewall)"
az network vhub routing-intent create \
  --name "$ROUTING_INTENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --vhub "$HUB_NAME" \
  --routing-policies \
    name=PrivateTrafficPolicy,destinations=PrivateTraffic,nexthop="$FIREWALL_ID" \
    name=InternetTrafficPolicy,destinations=Internet,nexthop="$FIREWALL_ID"

echo "==> Passo 5 — Criando regras no Firewall (ANTES de habilitar em produção: deny-all é o padrão)"
az network firewall policy rule-collection-group create \
  --name "rcg-vwan-castilho" \
  --resource-group "$RESOURCE_GROUP" \
  --policy-name "$FIREWALL_POLICY_NAME" \
  --priority 100

az network firewall policy rule-collection-group collection add-filter-collection \
  --name "allow-vnet-to-branch" \
  --resource-group "$RESOURCE_GROUP" \
  --policy-name "$FIREWALL_POLICY_NAME" \
  --rule-collection-group-name "rcg-vwan-castilho" \
  --action Allow \
  --priority 100 \
  --rule-name "allow-internal-traffic" \
  --rule-type NetworkRule \
  --source-addresses "10.0.0.0/8" "192.168.0.0/16" \
  --destination-addresses "10.0.0.0/8" "192.168.0.0/16" \
  --ip-protocols Any \
  --destination-ports "*"

az network firewall policy rule-collection-group collection add-filter-collection \
  --name "allow-internet-fqdn" \
  --resource-group "$RESOURCE_GROUP" \
  --policy-name "$FIREWALL_POLICY_NAME" \
  --rule-collection-group-name "rcg-vwan-castilho" \
  --action Allow \
  --priority 200 \
  --rule-name "allow-windows-update" \
  --rule-type ApplicationRule \
  --source-addresses "10.0.0.0/8" \
  --protocols "Https=443" \
  --target-fqdns "*.microsoft.com" "*.windows.com" "*.windowsupdate.com"

echo "==> Verificando a configuração completa"
az network vwan show --name "$VWAN_NAME" --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, tipo:type, status:provisioningState}" -o table
az network vhub show --name "$HUB_NAME" --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, status:provisioningState, roteamento:routingState}" -o table
az network vhub routing-intent show \
  --name "$ROUTING_INTENT_NAME" --resource-group "$RESOURCE_GROUP" --vhub "$HUB_NAME" \
  --query "{status:provisioningState, politicas:routingPolicies[].name}" -o json

echo "Segurança do Azure Virtual WAN configurada: tráfego privado e de Internet passando pelo Azure Firewall."

# ── Limpeza (ordem importa: Routing Intent -> Firewall -> conexão de VNet -> RG) ──
limpar_recursos() {
  az network vhub routing-intent delete --name "$ROUTING_INTENT_NAME" \
    --resource-group "$RESOURCE_GROUP" --vhub "$HUB_NAME" --yes
  az network firewall delete --name "$FIREWALL_NAME" --resource-group "$RESOURCE_GROUP"
  az network vhub connection delete --name "$VNET_CONNECTION_NAME" \
    --resource-group "$RESOURCE_GROUP" --vhub-name "$HUB_NAME" --yes
  # ATENÇÃO: remove TODOS os recursos do Resource Group (Virtual WAN, hub, VPN Gateway etc.)
  az group delete --name "$RESOURCE_GROUP" --yes --no-wait
  echo "Limpeza iniciada para o Resource Group: $RESOURCE_GROUP"
}
# Descomente para desprovisionar o laboratório:
# limpar_recursos
