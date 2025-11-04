# Log Stream e App Service Logs (Azure CLI)

Script Azure CLI que ativa os 4 tipos de log do App Service e, opcionalmente, migra o Application Logging pra Blob Storage — evitando o desligamento automático em 12h do modo filesystem.

## 📌 Visão Geral

O script `app-service-logs.sh` realiza:

- Ativação de Application Logging (filesystem), Web Server Logging, Detailed Error Messages e Failed Request Tracing
- Migração opcional (`USE_BLOB=true`) do Application Logging pra Blob Storage, com SAS gerada automaticamente e retenção configurável

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **App Service** já existente
- Se for usar `USE_BLOB=true`: uma **Storage Account** com o container de logs já criado
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export LEVEL="information"
export USE_BLOB="false"          # true pra log persistente em Blob Storage
export STORAGE_ACCOUNT="stmeuapplogs"
export BLOB_CONTAINER="applogs"
export RETENTION_DAYS="30"

chmod +x app-service-logs.sh
./app-service-logs.sh

# Acompanhar em tempo real:
az webapp log tail --name "$APP" --resource-group "$RG"
```

> O artigo completo (incluindo a pegadinha das 12h do filesystem logging e como baixar o histórico) está em:
> **https://jeffersoncastilho.com.br/2025/11/04/log-stream-app-service-logs/**
