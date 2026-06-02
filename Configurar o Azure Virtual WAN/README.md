# Configurar o Azure Virtual WAN (Azure CLI)

Script Azure CLI que percorre a configuração completa do **Azure Virtual WAN**: cria o recurso raiz (Standard), o Virtual Hub regional, o VPN Gateway, registra um VPN Site (filial), conecta uma VNet spoke ao hub e habilita o **Routing Intent** com Azure Firewall para inspeção centralizada de todo o tráfego.

## 📌 Visão Geral

O script `configurar-vwan.sh` realiza:

- Criação do Resource Group e do Virtual WAN (SKU Standard — obrigatório para VPN Gateway e Azure Firewall no hub)
- Criação do Virtual Hub regional com endereço `/23` dedicado
- Provisionamento do VPN Gateway (1 unidade de escala = 500 Mbps agregado)
- Registro de um VPN Site (filial on-premises) e da conexão IPsec/IKEv2 com o hub
- Conexão de uma VNet spoke ao Virtual Hub (Hub VNet Connection)
- Deploy de um Azure Firewall Premium no hub (`AZFW_Hub`) e habilitação do Routing Intent, forçando tráfego privado e de Internet pela inspeção centralizada

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **Azure CLI** ≥ 2.60 autenticado (`az login`)
- Provider `Microsoft.Network` registrado na subscription
- IP público do roteador da filial on-premises (para o VPN Site)

## 🚀 Uso

```bash
export BRANCH_PUBLIC_IP="203.0.113.10"   # IP público do roteador da filial

chmod +x configurar-vwan.sh
./configurar-vwan.sh
```

> O artigo completo (com tabelas de SKU, unidades de escala do VPN Gateway e troubleshooting) está em:
> **https://jeffersoncastilho.com.br/2026/06/02/configurar-azure-virtual-wan/**
