# Criação de Cluster AKS com Node Pools Windows

Este script em PowerShell automatiza o provisionamento de um cluster **Azure Kubernetes Service (AKS)** híbrido. Ele cria o cluster inicial com nós Linux (obrigatório para o plano de controle do sistema) e adiciona um node pool secundário rodando **Windows Server**, permitindo a execução de containers Windows.

## 📋 Funcionalidades

O script executa as seguintes etapas sequenciais:
1.  **Criação do Resource Group**: Cria um grupo de recursos no Azure para organizar os serviços.
2.  **Provisionamento do AKS**: Cria o cluster AKS com um node pool Linux padrão.
3.  **Adição de Node Pool Windows**: Adiciona um pool de nós Windows ao cluster existente.
4.  **Validação**: Configura as credenciais locais (`kubectl`) e lista os nós para confirmar o status.

## 🛠️ Pré-requisitos

Antes de executar o script, certifique-se de ter:

*   **Azure CLI (`az`)**: Instalado e autenticado.
    *   Login: `az login`
*   **kubectl**: Ferramenta de linha de comando do Kubernetes (instalada via `az aks install-cli` se necessário).
*   **PowerShell**: Para execução do script.

## ⚙️ Configurações Padrão

As seguintes variáveis estão definidas no início do script e podem ser ajustadas conforme a necessidade:

| Variável | Valor Padrão | Descrição |
| :--- | :--- | :--- |
| `$resourceGroup` | `blogDoCastilhoRG` | Nome do Grupo de Recursos |
| `$clusterName` | `blogDoCastilhoCluster` | Nome do Cluster AKS |
| `$location` | `eastus` | Região do Azure |
| `$nodeCountLinux` | `1` | Quantidade de nós Linux |
| `$nodeCountWindows` | `2` | Quantidade de nós Windows |
| `$windowsPoolName` | `winpool` | Nome do pool Windows |

## 🚀 Como usar

1.  Abra o terminal do PowerShell.
2.  Certifique-se de estar logado no Azure:
    ```powershell
    az login
    ```
3.  Execute o script:
    ```powershell
    .\criar-aks-nodegroups-windows.ps1
    ```
4.  Aguarde a finalização. O processo pode levar de 10 a 20 minutos dependendo da região e recursos do Azure.

## 🔗 Referência

*   Artigo no Blog: AKS com Node Groups Windows

https://jeffersoncastilho.com.br/2025/12/23/aks-com-node-groups-windows/ 

