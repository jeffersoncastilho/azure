# 1. VARIÁVEIS DE AMBIENTE

APP_NAME="blog-do-castilho"
LOC_PRI="eastus"
LOC_DR="westus"
RG_PRI="rg-$APP_NAME-prod"
RG_DR="rg-$APP_NAME-dr"

# Nomes dos recursos
ST_CACHE_PRI="stcastilhocachepri"
ST_CACHE_DR="stcastilhocachedr" 
RSV_PRI="rsv-blog-do-castilho-pri"
RSV_DR="rsv-blog-do-castilho-dr"
SP_NAME="sp-blog-do-castilho-dr-manager"

# ==============================================================================
# 1.5 CRIAÇÃO DOS RESOURCE GROUPS
# ==============================================================================
az group create --name $RG_PRI --location $LOC_PRI
az group create --name $RG_DR --location $LOC_DR

# ==============================================================================
# 2. CRIAÇÃO DOS STORAGE ACCOUNTS (CACHE/STAGING)
# ==============================================================================
# Storage na Origem (Necessário para o Churn de replicação)
az storage account create \
    --name $ST_CACHE_PRI \
    --resource-group $RG_PRI \
    --location $LOC_PRI \
    --sku Standard_LRS \
    --kind StorageV2

# Storage no Destino (Para suporte a failback futuro)
az storage account create \
    --name $ST_CACHE_DR \
    --resource-group $RG_DR \
    --location $LOC_DR \
    --sku Standard_LRS \
    --kind StorageV2

# ==============================================================================
# 3. CRIAÇÃO DOS RECOVERY SERVICES VAULTS
# ==============================================================================
# Vault na Origem
az backup vault create \
    --name $RSV_PRI \
    --resource-group $RG_PRI \
    --location $LOC_PRI

# Vault no Destino (Principal orquestrador do Failover)
az backup vault create \
    --name $RSV_DR \
    --resource-group $RG_DR \
    --location $LOC_DR

# ==============================================================================
# 4. SERVICE PRINCIPAL E PERMISSÕES (RBAC)
# ==============================================================================
# Criar o Service Principal e exibir credenciais (IMPORTANTE: Salve o appId e password)
az ad sp create-for-rbac --name $SP_NAME --skip-assignment

# Capturar o App ID do SP recém-criado
SP_APP_ID=$(az ad sp list --display-name $SP_NAME --query "[0].appId" -o tsv)

# Atribuição de permissões no Grupo de Origem (Leitura de rede e escrita no Cache)
for role in "Site Recovery Contributor" "Storage Account Contributor" "Storage Blob Data Contributor" "Network Contributor"
do
    az role assignment create --assignee $SP_APP_ID --role "$role" --resource-group $RG_PRI
done

# Atribuição de permissões no Grupo de Destino (Criação de VMs e Discos no Failover)
for role in "Site Recovery Contributor" "Virtual Machine Contributor" "Network Contributor" "Storage Account Contributor"
do
    az role assignment create --assignee $SP_APP_ID --role "$role" --resource-group $RG_DR
done

echo "Componentes de Storage, Vaults e Identidade criados com sucesso!"