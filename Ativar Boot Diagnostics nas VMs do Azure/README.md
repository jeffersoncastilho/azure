# Ativar Boot Diagnostics em Todas as VMs do Azure (Python)

Script **Python** que ativa o **Boot Diagnostics** em todas as máquinas virtuais de uma subscription do Azure, de uma só vez, usando o Azure SDK de gerenciamento.

## 📌 Visão Geral

O script `ativar-boot-diagnostics.py`:

- Lista **todas as VMs** da subscription (ou de um resource group específico) com `list_all()`
- Verifica em quais o Boot Diagnostics está desativado
- Aplica um **patch** (`begin_update`) habilitando o recurso — sem tocar em disco, rede ou tamanho
- Usa o **modo gerenciado** por padrão (sem storage account); aceita `--storage-uri` para storage customizado
- É **idempotente**: rodar várias vezes é seguro, pula o que já está ok
- Suporta `--dry-run` para simular antes de aplicar

## 🛠️ Pré-requisitos

- **Python 3.10+**
- **Azure CLI** autenticado (`az login`) **ou** Service Principal
- Permissão **Virtual Machine Contributor** (ou Contributor) no escopo desejado

## 🚀 Uso

```bash
pip install -r requirements.txt

# Autenticação (usa a sessão do Azure CLI)
az login
export AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Simular (não altera nada)
python ativar-boot-diagnostics.py --dry-run

# Ativar em todas as VMs da subscription
python ativar-boot-diagnostics.py

# Limitar a um resource group
python ativar-boot-diagnostics.py --resource-group rg-prod-eus

# Usar um storage account customizado
python ativar-boot-diagnostics.py --storage-uri https://stdiag.blob.core.windows.net/
```

### Parâmetros

| Flag | Descrição |
|------|-----------|
| `--subscription` | ID da subscription (padrão: env `AZURE_SUBSCRIPTION_ID` ou a primeira ativa) |
| `--resource-group` | Limita a ação a um único resource group |
| `--storage-uri` | URI de um storage account; omita para o modo gerenciado |
| `--dry-run` | Apenas relata o que seria feito, sem alterar nada |

## 🔒 Segurança

A autenticação usa `DefaultAzureCredential` — **nenhuma credencial fica no código**. Em automações (CI/CD), prefira uma **Managed Identity** ou um Service Principal via `AZURE_TENANT_ID` / `AZURE_CLIENT_ID` / `AZURE_CLIENT_SECRET`.

## Artigo no meu blog

Para o passo a passo detalhado, veja o artigo:

https://jeffersoncastilho.com.br/microsoft-azure/ativar-boot-diagnostics/
