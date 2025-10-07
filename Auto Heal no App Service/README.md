# Auto Heal no App Service (Azure CLI)

Script Azure CLI que configura regras de **Auto Heal** — reciclagem automática do processo do App Service quando a taxa de erro 500 ou de requisições lentas ultrapassa um limiar, com proteção contra loop de reciclagem em apps de boot lento.

## 📌 Visão Geral

O script `auto-heal.sh` realiza:

- Ativação do `autoHealEnabled` no site config
- Gatilho por quantidade de HTTP 500 num intervalo
- Gatilho por requisições lentas (tempo de resposta acima de um limite) num intervalo
- Ação de reciclagem do processo (`Recycle`) com `minProcessExecutionTime`, evitando reciclar antes do app terminar de subir

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **App Service** já existente
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export STATUS_CODE="500"
export STATUS_COUNT="20"
export SLOW_SECONDS="00:00:10"
export SLOW_COUNT="50"
export TIME_INTERVAL="00:05:00"
export MIN_PROCESS_TIME="00:01:00"

chmod +x auto-heal.sh
./auto-heal.sh
```

> O artigo completo (incluindo a tabela de gatilhos disponíveis e quando o Auto Heal NÃO é a solução) está em:
> **https://jeffersoncastilho.com.br/2025/10/07/auto-heal-app-service/**
