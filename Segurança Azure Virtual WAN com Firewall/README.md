# Segurança Azure Virtual WAN com Firewall (Azure CLI)

Script Azure CLI que conecta uma VNet spoke ao Virtual Hub, implanta um **Azure Firewall Premium** no hub (Secured Virtual Hub) e habilita o **Routing Intent** — forçando todo o tráfego privado e de Internet a passar pela inspeção centralizada. Fecha a série de 5 artigos sobre Azure Virtual WAN.

## 📌 Visão Geral

O script `seguranca-firewall-routing-intent.sh` realiza:

- Criação de uma VNet spoke e conexão ao Virtual Hub (Hub VNet Connection, peering automático)
- Criação da Firewall Policy (tier Premium: IDPS + inspeção TLS)
- Deploy do Azure Firewall no hub com SKU `AZFW_Hub` (diferente do `AZFW_VNet` tradicional)
- Habilitação do Routing Intent (políticas `PrivateTraffic` e `Internet` apontando pro Firewall — modelo Zero Trust)
- Regras de exemplo no Firewall (tráfego interno VNet↔filial e FQDNs de Internet) — **necessárias antes de habilitar o Routing Intent em produção**, já que o padrão é deny-all
- Função `limpar_recursos` pra desprovisionar o laboratório na ordem correta

## 🛠️ Pré-requisitos

- Virtual WAN Standard, Virtual Hub e VPN Gateway já provisionados (artigos anteriores da série)
- Virtual Hub com `routingState: Provisioned`
- Quota na subscription para Azure Firewall Premium

## 🚀 Uso

```bash
chmod +x seguranca-firewall-routing-intent.sh
./seguranca-firewall-routing-intent.sh
```

> O artigo completo (com troubleshooting de `RoutingIntentConflict` e `FirewallNotInHub`) está em:
> **https://jeffersoncastilho.com.br/2026/06/02/seguranca-azure-virtual-wan/**
