#!/usr/bin/env bash
###############################################################################
# az-cli-observabilidade-aks.sh
#
# Reprodução COMPLETA do artigo "Observabilidade no AKS" usando apenas Azure CLI
# (caminho alternativo ao Terraform em ../main.tf). Cobre os três pilares:
#   - Métricas : Azure Monitor Workspace (Managed Prometheus) + Managed Grafana
#   - Logs     : Container Insights (Log Analytics)
#   - Traces   : Application Insights (OpenTelemetry)
#   - Alertas  : Prometheus Rule Group
#
# Requer: az CLI autenticado (az login) + kubectl no cluster alvo.
# Rode passo a passo ou tudo de uma vez. Ajuste as variáveis abaixo.
###############################################################################
set -euo pipefail

# ----------------------------- Variáveis -------------------------------------
RG="${RG:-rg-blog-castilho-workload-eastus}"
LOCATION="${LOCATION:-eastus}"
AKS="${AKS:-aks-blog-castilho-eastus}"
PREFIX="${PREFIX:-blog-castilho}"
APP_NAMESPACE="${APP_NAMESPACE:-loja}"

###############################################################################
# PASSO 1 — Managed Prometheus + Managed Grafana
###############################################################################
echo "==> [1] Azure Monitor Workspace (destino das métricas Prometheus)"
AMW_ID=$(az monitor account create \
  --name "amw-${PREFIX}" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --query id -o tsv)

echo "==> [1] Azure Managed Grafana"
GRAFANA_ID=$(az grafana create \
  --name "graf-${PREFIX}" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --query id -o tsv)

echo "==> [1] Conectar o AKS ao Prometheus gerenciado + Grafana"
az aks update \
  --name "$AKS" \
  --resource-group "$RG" \
  --enable-azure-monitor-metrics \
  --azure-monitor-workspace-resource-id "$AMW_ID" \
  --grafana-resource-id "$GRAFANA_ID"

echo "    Validação: pods de coleta de métricas"
kubectl get pods -n kube-system -l dsName=ama-metrics || true

###############################################################################
# PASSO 2 — Logs com Container Insights
###############################################################################
echo "==> [2] Log Analytics Workspace"
LAW_ID=$(az monitor log-analytics workspace create \
  --resource-group "$RG" \
  --workspace-name "law-${PREFIX}" \
  --location "$LOCATION" \
  --query id -o tsv)

echo "==> [2] Habilitar Container Insights no cluster"
az aks enable-addons \
  --name "$AKS" \
  --resource-group "$RG" \
  --addons monitoring \
  --workspace-resource-id "$LAW_ID"

###############################################################################
# PASSO 3 — Métricas customizadas da aplicação (PodMonitor)
###############################################################################
echo "==> [3] PodMonitor para scrape do endpoint /metrics da aplicação"
cat <<YAML | kubectl apply -f -
apiVersion: azmonitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: pm-checkout-app
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: checkout
  namespaceSelector:
    matchNames:
      - ${APP_NAMESPACE}
  podMetricsEndpoints:
    - port: metrics
      interval: 30s
      path: /metrics
YAML

###############################################################################
# PASSO 4 — Endpoint do Grafana (data source já vinculado no Passo 1)
###############################################################################
echo "==> [4] URL do Grafana"
az grafana show \
  --name "graf-${PREFIX}" \
  --resource-group "$RG" \
  --query properties.endpoint -o tsv

###############################################################################
# PASSO 5 — Alertas com Prometheus Rule Group
###############################################################################
echo "==> [5] Prometheus Rule Group (SLO de taxa de erro 5xx > 5% por 10min)"
az resource create \
  --resource-group "$RG" \
  --namespace "Microsoft.AlertsManagement" \
  --resource-type "prometheusRuleGroups" \
  --name "prg-checkout-slo" \
  --location "$LOCATION" \
  --properties '{
    "scopes": ["'"$AMW_ID"'"],
    "clusterName": "'"$AKS"'",
    "interval": "PT1M",
    "rules": [{
      "alert": "HighErrorRate",
      "expression": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) > 0.05",
      "for": "PT10M",
      "labels": { "severity": "critical" },
      "annotations": { "description": "Taxa de erro 5xx acima de 5% no checkout" }
    }]
  }'

###############################################################################
# PASSO 6 — Traces com OpenTelemetry + Application Insights
###############################################################################
echo "==> [6] Application Insights (workspace-based) + Secret no cluster"
APPI_CONN=$(az monitor app-insights component create \
  --app "appi-${PREFIX}" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --workspace "$LAW_ID" \
  --query connectionString -o tsv)

kubectl create secret generic appinsights \
  --namespace "$APP_NAMESPACE" \
  --from-literal=connection-string="$APPI_CONN" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "OK — stack de observabilidade provisionada via Azure CLI."
echo "Grafana : $(az grafana show -n graf-${PREFIX} -g $RG --query properties.endpoint -o tsv)"
echo "AMW ID  : $AMW_ID"
echo "LAW ID  : $LAW_ID"
