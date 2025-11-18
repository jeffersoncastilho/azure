#!/usr/bin/env bash
# Deploy do App Service via GitHub Actions: configura a integração OIDC (sem publish profile)
# com um único comando — cria o app registration, a credencial federada e o workflow no repositório.
# Artigo: https://jeffersoncastilho.com.br/2025/11/18/deploy-app-service-github-actions/
set -euo pipefail

RG="${RG:?defina RG (resource group)}"
APP="${APP:?defina APP (nome do App Service)}"
REPO="${REPO:?defina REPO (formato owner/repo, ex: minhaorg/meurepo)}"
BRANCH="${BRANCH:-main}"

echo "==> Configurando GitHub Actions via OIDC (abre device code flow do GitHub)"
az webapp deployment github-actions add \
    --name "$APP" \
    --resource-group "$RG" \
    --repo "$REPO" \
    --branch "$BRANCH" \
    --login-with-github

echo "==> Concluído. O workflow foi commitado em .github/workflows/ no repositório $REPO."
echo "    Veja workflow-exemplo.yml nesta pasta pra entender a estrutura gerada."
