
<#
.SYNOPSIS
Script para criar um cluster AKS com node pool Windows no Azure.
.DESCRIPTION
Este script automatiza a criação de um cluster AKS com um node pool Linux padrão e adiciona um node pool Windows.
Autor: Jefferson Castilho 
Data: 2025-12-22
#>

# Variáveis
$resourceGroup = "blogDoCastilhoRG"
$clusterName   = "blogDoCastilhoCluster"
$location      = "eastus"
$nodeCountLinux = 1
$nodeCountWindows = 2
$windowsPoolName = "winpool"

Write-Host "Iniciando criação do cluster AKS com node groups Windows..." -ForegroundColor Cyan

# Passo 1: Criar grupo de recursos (se não existir)
Write-Host "Criando grupo de recursos: $resourceGroup" -ForegroundColor Yellow
az group create --name $resourceGroup --location $location

# Passo 2: Criar cluster AKS com node pool Linux
Write-Host "Criando cluster AKS: $clusterName" -ForegroundColor Yellow
az aks create `
  --resource-group $resourceGroup `
  --name $clusterName `
  --node-count $nodeCountLinux `
  --enable-addons monitoring `
  --generate-ssh-keys `
  --location $location

# Passo 3: Adicionar node pool Windows
Write-Host "Adicionando node pool Windows: $windowsPoolName" -ForegroundColor Yellow
az aks nodepool add `
  --resource-group $resourceGroup `
  --cluster-name $clusterName `
  --os-type Windows `
  --name $windowsPoolName `
  --node-count $nodeCountWindows

# Passo 4: Validar nodes
Write-Host "Validando nodes no cluster..." -ForegroundColor Yellow
az aks get-credentials --resource-group $resourceGroup --name $clusterName
kubectl get nodes

Write-Host "Cluster AKS com node groups Windows criado com sucesso!" -ForegroundColor Green
