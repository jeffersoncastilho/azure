

# Naming Convention
APP_NAME="blog-do-castilho"

# Região Origem (Primary)
RG_PRI="rg-$APP_NAME-prod"
LOC_PRI="eastus"
HUB_PRI="vnet-hub-prod"
SPOKE_PRI="vnet-spoke-prod"

# Região Destino (DR)
RG_DR="rg-$APP_NAME-dr"
LOC_DR="westus"
HUB_DR="vnet-hub-dr"
SPOKE_DR="vnet-spoke-dr"

#variaveis para peering global
ID_HUB_PRI=$(az network vnet show -g $RG_PRI -n $HUB_PRI --query id -o tsv)
ID_HUB_DR=$(az network vnet show -g $RG_DR -n $HUB_DR --query id -o tsv)

#variavel para policy de regiões permitidas
POLICY_DEF_ID=$(az policy definition list --query "[?displayName=='Allowed locations'].name" -o tsv)

#origem

# Criar Grupo de Recursos
az group create --name $RG_PRI --location $LOC_PRI

# Hub Origem (10.0.0.0/16)
az network vnet create -g $RG_PRI -n $HUB_PRI --address-prefix 10.0.0.0/16 --subnet-name snet-shared --subnet-prefix 10.0.1.0/24

# Spoke Origem (10.1.0.0/16)
az network vnet create -g $RG_PRI -n $SPOKE_PRI --address-prefix 10.1.0.0/16 --subnet-name snet-app --subnet-prefix 10.1.1.0/24

# --- NAT GATEWAY (Saída de Internet) ---
az network public-ip create -g $RG_PRI -n pip-nat-$APP_NAME-pri --sku Standard --location $LOC_PRI
az network nat gateway create -g $RG_PRI -n nat-gw-$APP_NAME-pri --location $LOC_PRI --public-ip-addresses pip-nat-$APP_NAME-pri

# Associar NAT Gateway à Subnet do Blog
az network vnet subnet update -g $RG_PRI --vnet-name $SPOKE_PRI -n snet-app --nat-gateway nat-gw-$APP_NAME-pri

# Peering Hub <-> Spoke
az network vnet peering create -g $RG_PRI -n HubToSpoke --vnet-name $HUB_PRI --remote-vnet $SPOKE_PRI --allow-vnet-access
az network vnet peering create -g $RG_PRI -n SpokeToHub --vnet-name $SPOKE_PRI --remote-vnet $HUB_PRI --allow-vnet-access

#Destino

# Criar Grupo de Recursos DR
az group create --name $RG_DR --location $LOC_DR

# Hub DR (10.2.0.0/16)
az network vnet create -g $RG_DR -n $HUB_DR --address-prefix 10.2.0.0/16 --subnet-name snet-shared-dr --subnet-prefix 10.2.1.0/24

# Spoke DR (10.3.0.0/16)
az network vnet create -g $RG_DR -n $SPOKE_DR --address-prefix 10.3.0.0/16 --subnet-name snet-app-dr --subnet-prefix 10.3.1.0/24

# --- NAT GATEWAY DR ---
az network public-ip create -g $RG_DR -n pip-nat-$APP_NAME-dr --sku Standard --location $LOC_DR
az network nat gateway create -g $RG_DR -n nat-gw-$APP_NAME-dr --location $LOC_DR --public-ip-addresses pip-nat-$APP_NAME-dr

# Associar NAT Gateway à Subnet do Blog DR
az network vnet subnet update -g $RG_DR --vnet-name $SPOKE_DR -n snet-app-dr --nat-gateway nat-gw-$APP_NAME-dr

# Peering Hub <-> Spoke (DR)
az network vnet peering create -g $RG_DR -n HubToSpoke-DR --vnet-name $HUB_DR --remote-vnet $SPOKE_DR --allow-vnet-access
az network vnet peering create -g $RG_DR -n SpokeToHub-DR --vnet-name $SPOKE_DR --remote-vnet $HUB_DR --allow-vnet-access

#peering global

az network vnet peering create -g $RG_PRI -n Peering-To-DR --vnet-name $HUB_PRI --remote-vnet $ID_HUB_DR --allow-vnet-access
az network vnet peering create -g $RG_DR -n Peering-To-Primary --vnet-name $HUB_DR --remote-vnet $ID_HUB_PRI --allow-vnet-access

#policy

az policy assignment create --name "DR" \
    --display-name "DR - Regiões Permitidas Blog do Castilho" \
    --policy $POLICY_DEF_ID \
    --params "{\"listOfAllowedLocations\": {\"value\": [\"$LOC_PRI\", \"$LOC_DR\"]}}" \
    --scope "/subscriptions/$(az account show --query id -o tsv)"