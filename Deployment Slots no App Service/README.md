# Deployment Slots no App Service (Azure CLI)

Script Azure CLI que cria um slot de staging, publica um deploy nele, marca app settings como "sticky" (não trocam no swap) e executa um **swap com preview** — a forma recomendada de trocar produção sem downtime.

## 📌 Visão Geral

O script `deployment-slots.sh` realiza:

- Scale up do App Service Plan pra Standard (S1), exigido pelo recurso
- Criação do slot `staging`, clonado da configuração de produção
- Deploy via zip no slot de staging (produção continua intocada)
- Marcação de app setting como slot setting (sticky), pra não vazar config de teste pra produção
- Swap com preview em duas fases: aquece o staging com a config de produção, pausa pra validação manual, e só então troca o tráfego

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **App Service** já existente (Linux ou Windows)
- **Azure CLI** ≥ 2.60 autenticado (`az login`)
- Um pacote de deploy zipado (`app.zip`) do seu app

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export PLAN="nome-do-app-service-plan"
export SRC_ZIP="./app.zip"

chmod +x deployment-slots.sh
./deployment-slots.sh
```

> O artigo completo (incluindo o equivalente em PowerShell com `Switch-AzWebAppSlot`) está em:
> **https://jeffersoncastilho.com.br/2025/08/05/deployment-slots-app-service/**
