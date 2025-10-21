# Health Check Path no App Service (Azure CLI)

Script Azure CLI que configura o **Health Check Path** do App Service — endpoint que a plataforma monitora pra tirar instâncias travadas de rotação — e ajusta a tolerância a falhas antes da exclusão.

## 📌 Visão Geral

O script `health-check-path.sh` realiza:

- Configuração do `healthCheckPath` no site config
- Ajuste de `WEBSITE_HEALTHCHECK_MAXPINGFAILURES` (padrão 10, range 1-100)

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **App Service** já existente, idealmente com 2+ instâncias (só aí o recurso tem efeito de balanceamento)
- Um endpoint de health check implementado na aplicação, retornando 200 quando saudável
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export HEALTH_PATH="/health"
export MAX_PING_FAILURES="10"

chmod +x health-check-path.sh
./health-check-path.sh
```

> O artigo completo (incluindo o comportamento de exclusão de instâncias e a rede de segurança contra remover todas ao mesmo tempo) está em:
> **https://jeffersoncastilho.com.br/2025/10/21/health-check-path-app-service/**
