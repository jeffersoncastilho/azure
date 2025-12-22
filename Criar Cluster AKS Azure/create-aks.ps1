<#
.SYNOPSIS
  Script para criar um Cluster AKS no Azure usando PowerShell.

.DESCRIPTION
  Este script cria:
  - Resource Group
  - Cluster AKS com Managed Identity
  - Node Pool padrão

.REQUIREMENTS
  - PowerShell 7+
  - Módulo Az PowerShell
  - Permissão Contributor ou Owner
#>

# =========================
# VARIÁVEIS
# =========================
$subscriptionId = "<SUBSCRIPTION_ID>"
$location       = "Brazil South"
$resourceGroup  = "rg-aks-blog-castilho"
$aksName        = "aks-blog-castilho"
$nodeCount      = 3
$nodeSize       = "Standard_DS2_v2"
$k8sVersion     = "1.29.4"

# =========================
# LOGIN NO AZURE
# =========================
Write-Host "Autenticando no Azure..." -ForegroundColor Cyan
Connect-AzAccount

Set-AzContext -SubscriptionId $subscriptionId

# =========================
# CRIAR RESOURCE GROUP
# =========================
Write-Host "Criando Resource Group..." -ForegroundColor Cyan
New-AzResourceGroup `
  -Name $resourceGroup `
  -Location $location `
  -ErrorAction Stop

# =========================
# CRIAR CLUSTER AKS
# =========================
Write-Host "Criando Cluster AKS..." -ForegroundColor Cyan
New-AzAksCluster `
  -ResourceGroupName $resourceGroup `
  -Name $aksName `
  -Location $location `
  -NodeCount $nodeCount `
  -NodeVmSize $nodeSize `
  -KubernetesVersion $k8sVersion `
  -EnableManagedIdentity `
  -GenerateSshKey `
  -ErrorAction Stop

# =========================
# IMPORTAR CREDENCIAIS
# =========================
Write-Host "Configurando acesso ao cluster..." -ForegroundColor Cyan
Import-AzAksCredential `
  -ResourceGroupName $resourceGroup `
  -Name $aksName `
  -Force

# =========================
# VALIDAR CLUSTER
# =========================
Write-Host "Validando nós do cluster..." -ForegroundColor Green
kubectl get nodes

Write-Host "Cluster AKS criado com sucesso!" -ForegroundColor Green
