#!/usr/bin/env bash
# Conectar Filiais ao Azure Virtual WAN com VPN: cria o VPN Gateway no hub,
# registra uma ou mais filiais como VPN Site e estabelece a conexão IPsec/IKEv2
# entre cada filial e o hub. Pressupõe que o Virtual WAN e o Virtual Hub já
# existem (artigo anterior da série).
# Artigo: https://jeffersoncastilho.com.br/2026/06/02/filiais-ao-azure-virtual-wan/
set -euo pipefail

# ── Herdadas do artigo de criação do Virtual WAN ─────────────────────────────
RESOURCE_GROUP="rg-vwan-castilho"
VWAN_NAME="vwan-castilho"
HUB_NAME="vhub-castilho-eastus"
LOCATION="eastus"

# ── Novos recursos deste artigo ──────────────────────────────────────────────
VPN_GW_NAME="vpngw-castilho"
VPN_SITE_NAME="vpnsite-filial-sp"
VPN_CONNECTION_NAME="conn-filial-sp"

# ── Dados da filial (substitua pelos valores reais) ──────────────────────────
BRANCH_PUBLIC_IP="${BRANCH_PUBLIC_IP:?defina o IP público do roteador da filial}"
BRANCH_ADDRESS_PREFIX="192.168.1.0/24"

VPN_PSK="$(openssl rand -base64 32)"
echo "PSK gerada (configure também no roteador da filial): $VPN_PSK"

echo "==> Passo 1 — Criando o VPN Gateway no Hub (~30 min de provisionamento)"
az network vpn-gateway create \
  --name "$VPN_GW_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --vhub "$HUB_NAME" \
  --scale-unit 1 \
  --tags projeto="vwan-castilho" ambiente="producao"

az network vpn-gateway show \
  --name "$VPN_GW_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "{nome:name, status:provisioningState, bgpAsn:bgpSettings.asn, ips:ipConfigurations[].publicIpAddress}" -o json

echo "==> Passo 2 — Registrando o VPN Site (filial)"
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
echo "VPN Site criado: $VPN_SITE_ID"

echo "==> Passo 3 — Criando a conexão VPN (túnel IPsec/IKEv2)"
az network vpn-gateway connection create \
  --name "$VPN_CONNECTION_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --gateway-name "$VPN_GW_NAME" \
  --vpn-site "$VPN_SITE_ID" \
  --shared-key "$VPN_PSK" \
  --enable-bgp false \
  --protocol-type IKEv2 \
  --connection-bandwidth 100

az network vpn-gateway connection show \
  --name "$VPN_CONNECTION_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --gateway-name "$VPN_GW_NAME" \
  --query "{nome:name, status:provisioningState, conexao:connectionStatus}" -o table

echo "==> Verificando o status da conexão e os IPs públicos do Gateway"
az network vpn-gateway connection list \
  --resource-group "$RESOURCE_GROUP" \
  --gateway-name "$VPN_GW_NAME" \
  --query "[].{Nome:name, Status:provisioningState, Conexao:connectionStatus, Largura:connectionBandwidth}" -o table

az network vpn-gateway show \
  --name "$VPN_GW_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "ipConfigurations[].{IP:publicIpAddress}" -o table

# ── Conectar múltiplas filiais de uma vez ────────────────────────────────────
conectar_multiplas_filiais() {
  declare -A FILIAIS=(
    ["filial-rj"]="200.100.50.1:10.1.0.0/24"
    ["filial-bh"]="177.80.30.5:10.2.0.0/24"
    ["filial-cu"]="189.45.20.8:10.3.0.0/24"
  )

  for NOME in "${!FILIAIS[@]}"; do
    IFS=':' read -r IP CIDR <<< "${FILIAIS[$NOME]}"
    PSK="$(openssl rand -base64 32)"

    az network vpn-site create \
      --name "vpnsite-$NOME" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --virtual-wan "$VWAN_NAME" \
      --ip-address "$IP" \
      --address-prefixes "$CIDR" \
      --tags filial="$NOME"

    SITE_ID=$(az network vpn-site show \
      --name "vpnsite-$NOME" \
      --resource-group "$RESOURCE_GROUP" \
      --query id -o tsv)

    az network vpn-gateway connection create \
      --name "conn-$NOME" \
      --resource-group "$RESOURCE_GROUP" \
      --gateway-name "$VPN_GW_NAME" \
      --vpn-site "$SITE_ID" \
      --shared-key "$PSK" \
      --protocol-type IKEv2

    echo "Filial $NOME conectada | IP: $IP | CIDR: $CIDR | PSK: $PSK"
  done
}
# Descomente para conectar o lote de filiais de exemplo acima:
# conectar_multiplas_filiais

echo "Filial(is) conectada(s) ao Azure Virtual WAN via VPN."
