# App Service Managed Certificate (Azure CLI)

Script Azure CLI que emite e vincula (via SNI) um **certificado SSL gratuito e gerenciado** do App Service pra um domínio customizado, com renovação automática sem custo.

## 📌 Visão Geral

O script `managed-certificate.sh` realiza:

- Confirmação/criação do hostname customizado no App Service
- Emissão do certificado gerenciado gratuito (`az webapp config ssl create`)
- Vínculo via SNI (`az webapp config ssl bind`)
- Listagem dos certificados vinculados, com data de expiração

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão de Contributor
- **App Service** em plano Basic ou superior (não funciona em Free/Shared)
- Domínio já configurado no DNS apontando pro App Service
- **Azure CLI** ≥ 2.60 autenticado (`az login`)

## 🚀 Uso

```bash
export RG="rg-do-seu-app-service"
export APP="nome-do-seu-app-service"
export HOSTNAME="www.meusite.com.br"

chmod +x managed-certificate.sh
./managed-certificate.sh
```

> O artigo completo (incluindo o que o Managed Certificate NÃO cobre e a tabela de troubleshooting) está em:
> **https://jeffersoncastilho.com.br/2025/09/16/app-service-managed-certificate/**
