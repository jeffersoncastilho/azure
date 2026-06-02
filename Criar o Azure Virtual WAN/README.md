# Criar o Azure Virtual WAN (Azure CLI)

Script Azure CLI que cria o Resource Group, o recurso **Virtual WAN** (SKU Standard) e o **Virtual Hub** regional — a base sobre a qual VPN Gateway, filiais e Azure Firewall são adicionados nos artigos seguintes da série.

## 📌 Visão Geral

O script `criar-vwan.sh` realiza:

- Registro do provider `Microsoft.Network` (idempotente)
- Criação do Resource Group com tags padronizadas
- Criação do Virtual WAN com SKU `Standard` (habilita VPN Gateway, ExpressRoute, Azure Firewall e roteamento inter-hub — o SKU não pode ser alterado após a criação)
- Criação do Virtual Hub com bloco de endereço `/24` exclusivo
- Verificação do `provisioningState` e do `routingState` do hub

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **Azure CLI** ≥ 2.50 autenticado (`az login`)
- Bloco `/24` exclusivo reservado para o hub (não pode sobrepor VNets ou filiais existentes)

## 🚀 Uso

```bash
chmod +x criar-vwan.sh
./criar-vwan.sh
```

> O artigo completo (incluindo o exemplo de hub secundário multi-região) está em:
> **https://jeffersoncastilho.com.br/2026/06/02/criar-o-azure-virtual-wan/**
