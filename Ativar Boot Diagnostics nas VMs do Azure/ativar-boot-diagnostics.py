#!/usr/bin/env python3
"""
Ativa o Boot Diagnostics (modo gerenciado) em todas as VMs de uma subscription do Azure.

O Boot Diagnostics captura a tela de boot e o log serial da VM, essenciais para
diagnosticar VMs que não inicializam. Este script percorre todas as máquinas
virtuais da subscription e habilita o recurso onde ele estiver desativado.

Autenticação: usa DefaultAzureCredential (Azure CLI `az login` ou Service Principal
via variáveis AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET).

Modos:
  - Gerenciado (padrão): sem storage account, recomendado pela Microsoft.
  - Storage customizado:  passe --storage-uri https://<conta>.blob.core.windows.net/

Exemplos:
  python ativar-boot-diagnostics.py --dry-run
  python ativar-boot-diagnostics.py
  python ativar-boot-diagnostics.py --resource-group rg-prod-eus
  python ativar-boot-diagnostics.py --storage-uri https://stdiag.blob.core.windows.net/

Autor: Jefferson Castilho — https://jeffersoncastilho.com.br
"""
from __future__ import annotations

import argparse
import os
import sys

from azure.identity import DefaultAzureCredential
from azure.core.exceptions import HttpResponseError
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.compute.models import (
    VirtualMachineUpdate,
    DiagnosticsProfile,
    BootDiagnostics,
)


def resolver_subscription(credential, subscription_arg: str | None) -> str:
    """Descobre a subscription a usar: argumento > variável de ambiente > primeira ativa."""
    if subscription_arg:
        return subscription_arg
    if os.environ.get("AZURE_SUBSCRIPTION_ID"):
        return os.environ["AZURE_SUBSCRIPTION_ID"]

    # Sem argumento nem env: pega a primeira subscription habilitada da conta.
    from azure.mgmt.resource import SubscriptionClient

    sub_client = SubscriptionClient(credential)
    for sub in sub_client.subscriptions.list():
        if sub.state == "Enabled":
            print(f"Subscription não informada; usando a primeira ativa: {sub.display_name}")
            return sub.subscription_id
    sys.exit("Nenhuma subscription ativa encontrada. Use --subscription <id>.")


def rg_do_id(vm_id: str) -> str:
    """Extrai o nome do resource group a partir do resource ID da VM."""
    partes = vm_id.split("/")
    return partes[partes.index("resourceGroups") + 1]


def esta_habilitado(vm) -> bool:
    """Retorna True se o Boot Diagnostics já estiver ativo na VM."""
    diag = getattr(vm, "diagnostics_profile", None)
    if diag and diag.boot_diagnostics:
        return bool(diag.boot_diagnostics.enabled)
    return False


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ativa o Boot Diagnostics em todas as VMs de uma subscription do Azure."
    )
    parser.add_argument("--subscription", help="ID da subscription (padrão: env ou primeira ativa).")
    parser.add_argument("--resource-group", help="Limita a ação a um único resource group.")
    parser.add_argument(
        "--storage-uri",
        help="URI de um storage account para diagnósticos. Omita para usar o modo gerenciado.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Apenas relata o que seria feito, sem alterar nada.",
    )
    args = parser.parse_args()

    credential = DefaultAzureCredential()
    subscription_id = resolver_subscription(credential, args.subscription)
    compute = ComputeManagementClient(credential, subscription_id)

    modo = "gerenciado" if not args.storage_uri else f"storage: {args.storage_uri}"
    print(f"Subscription : {subscription_id}")
    print(f"Modo         : {modo}")
    print(f"Dry-run      : {'sim' if args.dry_run else 'não'}")
    print("-" * 78)

    # Lista todas as VMs da subscription (ou de um único RG, se filtrado).
    if args.resource_group:
        vms = compute.virtual_machines.list(args.resource_group)
    else:
        vms = compute.virtual_machines.list_all()

    total = ja_ativas = ativadas = erros = 0

    for vm in vms:
        total += 1
        rg = rg_do_id(vm.id)

        if esta_habilitado(vm):
            ja_ativas += 1
            print(f"[=] {vm.name:<24} ({rg}) — já habilitado")
            continue

        if args.dry_run:
            print(f"[»] {vm.name:<24} ({rg}) — seria habilitado")
            ativadas += 1
            continue

        try:
            update = VirtualMachineUpdate(
                diagnostics_profile=DiagnosticsProfile(
                    boot_diagnostics=BootDiagnostics(enabled=True, storage_uri=args.storage_uri)
                )
            )
            compute.virtual_machines.begin_update(rg, vm.name, update).result()
            ativadas += 1
            print(f"[✓] {vm.name:<24} ({rg}) — Boot Diagnostics habilitado")
        except HttpResponseError as exc:
            erros += 1
            print(f"[x] {vm.name:<24} ({rg}) — ERRO: {exc.message}")

    print("-" * 78)
    print(f"Total de VMs .......... {total}")
    print(f"Já habilitadas ........ {ja_ativas}")
    rotulo = "A habilitar (dry-run)" if args.dry_run else "Habilitadas agora"
    print(f"{rotulo} ... {ativadas}")
    print(f"Erros ................. {erros}")

    if erros:
        sys.exit(1)


if __name__ == "__main__":
    main()
