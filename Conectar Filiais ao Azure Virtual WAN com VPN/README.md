# Conectar Filiais ao Azure Virtual WAN com VPN (Azure CLI)

Script Azure CLI que cria o **VPN Gateway** dentro de um Virtual Hub já existente, registra uma filial on-premises como **VPN Site** e estabelece a **conexão IPsec/IKEv2** entre os dois — incluindo uma função pra conectar várias filiais em lote.

## 📌 Visão Geral

O script `conectar-filiais-vpn.sh` realiza:

- Provisionamento do VPN Gateway no hub (1 unidade de escala = 500 Mbps agregado)
- Registro do VPN Site com IP público e CIDR interno da filial
- Criação da conexão VPN Site-to-Site (IKEv2, PSK gerada aleatoriamente)
- Verificação do status da conexão e dos IPs públicos do Gateway (necessários para configurar o roteador da filial)
- Função `conectar_multiplas_filiais` pra repetir o processo em lote quando há várias unidades

## 🛠️ Pré-requisitos

- Virtual WAN e Virtual Hub já criados (artigo anterior da série), com `provisioningState: Succeeded`
- IP público estático do roteador de cada filial on-premises
- Bloco CIDR da rede interna de cada filial

## 🚀 Uso

```bash
export BRANCH_PUBLIC_IP="203.0.113.10"   # IP público do roteador da filial

chmod +x conectar-filiais-vpn.sh
./conectar-filiais-vpn.sh
```

> O artigo completo (incluindo download da configuração pronta pro roteador e troubleshooting de conexão VPN) está em:
> **https://jeffersoncastilho.com.br/2026/06/02/filiais-ao-azure-virtual-wan/**
