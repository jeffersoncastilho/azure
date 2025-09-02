# VNet Integration Regional no App Service (Azure CLI)

Script Azure CLI que cria uma subnet dedicada delegada a `Microsoft.Web/serverFarms`, ativa a **VNet Integration Regional** e, opcionalmente, roteia todo o tráfego de saída do App Service pela rede virtual.

## 📌 Visão Geral

O script `vnet-integration.sh` realiza:

- Criação de uma subnet dedicada (mínimo /28, padrão /27 no script) delegada ao App Service
- Ativação da integração regional entre o App Service e a subnet
- Roteamento total do tráfego de saída pela VNet (`vnetRouteAllEnabled`), opcional via variável de ambiente

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **App Service** em plano Standard, Premium ou Elastic Premium (não funciona em Free/Shared/Basic)
- **Virtual Network** já existente, na mesma região do App Service
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export VNET="nome-da-sua-vnet"
export SUBNET="snet-integration"
export SUBNET_PREFIX="10.0.1.0/27"
export ROUTE_ALL="false"   # true pra rotear todo tráfego de saída pela VNet

chmod +x vnet-integration.sh
./vnet-integration.sh
```

> O artigo completo (incluindo o equivalente em PowerShell e a tabela de troubleshooting) está em:
> **https://jeffersoncastilho.com.br/2025/09/02/vnet-integration-regional-app-service/**
