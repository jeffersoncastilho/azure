# Criar Cluster AKS Azure usando PowerShell

Este repositório contém um script PowerShell para **criar um cluster AKS no Azure** de forma automatizada, seguindo boas práticas de segurança, organização e DevOps.

## 📌 Visão Geral

O script realiza as seguintes tarefas:

- Autenticação no Azure
- Seleção da assinatura
- Criação do Resource Group
- Criação do Azure Kubernetes Service (AKS)
- Configuração de acesso via `kubectl`
- Validação do cluster

Ideal para ambientes de:
- Laboratório
- Desenvolvimento
- Homologação
- Base inicial para produção

---

## 🛠️ Pré-requisitos

Antes de executar o script, certifique-se de que possui:

- Assinatura ativa no **Microsoft Azure**
- Permissão **Contributor** ou **Owner**
- **PowerShell 7 ou superior**
- Módulo **Az PowerShell**
- `kubectl` instalado

### Instalar o módulo Az PowerShell

```powershell
Install-Module Az -Repository PSGallery -Force -AllowClobber
Update-Module Az

## Artigo no meu blog

Para saber mais sobre o Script pode usar o Link abaixo para o meu artigo no meu blog.

https://jeffersoncastilho.com.br/2025/12/22/criar-cluster-aks-azure/

