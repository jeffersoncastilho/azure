# Observabilidade no AKS com Prometheus e Grafana (Azure CLI)

Script Azure CLI que provisiona, de ponta a ponta, uma stack de **observabilidade completa** para um cluster AKS — os três pilares em serviços gerenciados do Azure.

## 📌 Visão Geral

O script `observabilidade-aks.sh` realiza:

- **Métricas** — Azure Monitor Workspace (Managed Prometheus) + Azure Managed Grafana, conectados ao cluster
- **Logs** — Container Insights enviando stdout/stderr para o Log Analytics
- **Métricas de aplicação** — PodMonitor para scrape do endpoint `/metrics`
- **Alertas** — Prometheus Rule Group (SLO de taxa de erro 5xx)
- **Traces** — Application Insights (workspace-based) + Secret com a Connection String para OpenTelemetry

Ideal para ambientes de laboratório, desenvolvimento e homologação.

---

## 🛠️ Pré-requisitos

- Assinatura ativa no **Microsoft Azure** com permissão **Contributor** (ou **Owner** para o rule group)
- Cluster **AKS** existente
- **Azure CLI** ≥ 2.60 autenticado (`az login`)
- **kubectl** configurado para o cluster

## 🚀 Uso

```bash
export RG="rg-do-seu-aks"
export AKS="nome-do-seu-aks"
export LOCATION="eastus"
export PREFIX="blog-castilho"

chmod +x observabilidade-aks.sh
./observabilidade-aks.sh
```

> Também há a versão **Terraform** desta stack no repositório de IaC:
> `github.com/jeffersoncastilho/terraform` → `azure/artigos-observabilidade/art-01-observabilidade-aks`

## Artigo no meu blog

Para o passo a passo detalhado, veja o artigo:

https://jeffersoncastilho.com.br/microsoft-azure/observabilidade-aks/
