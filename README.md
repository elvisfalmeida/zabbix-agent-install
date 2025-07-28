# 🚀 Zabbix Agent Universal Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Zabbix](https://img.shields.io/badge/Zabbix-7.2.4-red.svg)](https://www.zabbix.com/)
[![Linux](https://img.shields.io/badge/Linux-Universal-blue.svg)](https://www.linux.org/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

Scripts universais para instalação automatizada do Zabbix Agent em qualquer distribuição Linux, utilizando binários estáticos oficiais.

## ⚡ Instalação Rápida (One-liner)

```bash
# Instalação automática com detecção de hostname
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- IP_SERVIDOR $(hostname)
```

### Exemplo:
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 $(hostname)
```

> 📖 Veja mais opções de one-liner em [ONE-LINER.md](ONE-LINER.md)

## 📋 Características

- ✅ **Universal**: Funciona em qualquer distribuição Linux
- ✅ **Multi-arquitetura**: Suporte para amd64 e i386
- ✅ **Sem dependências**: Usa binários estáticos oficiais
- ✅ **Detecção automática**: Identifica distro, arquitetura e init system
- ✅ **Instalação one-liner**: Um comando para instalar
- ✅ **Configuração flexível**: Múltiplas opções via linha de comando
- ✅ **Seguro**: Suporte a PSK encryption
- ✅ **Produção-ready**: Testado em ambientes corporativos

## 🔧 Requisitos

- Linux (qualquer distribuição)
- Acesso root (sudo)
- curl ou wget
- Conexão com internet

## 📦 Métodos de Instalação

### 1. One-liner (Recomendado)

```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 $(hostname)
```

### 2. Download e Execução Manual

```bash
# Clone o repositório
git clone https://github.com/elvisfalmeida/zabbix-agent-install.git
cd zabbix-agent-install

# Torne executável
chmod +x install_zabbix_agent_universal.sh

# Execute
sudo ./install_zabbix_agent_universal.sh 192.168.1.100 meu-servidor
```

## 📚 Scripts Disponíveis

### 1. `install.sh` - One-liner Wrapper
Facilita a instalação remota com um único comando.

### 2. `install_zabbix_agent_basic.sh` - Script Básico
Instalação simples e direta.
```bash
sudo ./install_zabbix_agent_basic.sh IP_SERVIDOR HOSTNAME
```

### 3. `install_zabbix_agent_universal.sh` - Script Universal
Detecção automática de sistema e arquitetura.
```bash
sudo ./install_zabbix_agent_universal.sh IP_SERVIDOR HOSTNAME [ARQUITETURA]
```

### 4. `install_zabbix_agent_advanced.sh` - Script Avançado
Todas as opções de customização disponíveis.
```bash
sudo ./install_zabbix_agent_advanced.sh [OPÇÕES] IP_SERVIDOR HOSTNAME
```

## 🚀 Exemplos de Uso

### Instalação Básica
```bash
# One-liner
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 webserver-01

# Ou download manual
sudo ./install_zabbix_agent_universal.sh 192.168.1.100 webserver-01
```

### Forçar Arquitetura i386
```bash
# One-liner
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 legacy-server i386

# Ou manual
sudo ./install_zabbix_agent_universal.sh 192.168.1.100 legacy-server i386
```

### Instalação em Múltiplos Servidores
```bash
#!/bin/bash
SERVERS=("web-01" "web-02" "db-01")
for server in "${SERVERS[@]}"; do
    ssh root@$server "curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | bash -s -- 192.168.1.100 $server"
done
```

## 🛠️ Opções Avançadas

Para o script `install_zabbix_agent_advanced.sh`:

| Opção | Descrição | Padrão |
|-------|-----------|--------|
| `-v, --version` | Versão do Zabbix Agent | 7.2.4 |
| `-a, --arch` | Arquitetura (amd64, i386, auto) | auto |
| `-p, --port` | Porta de escuta | 10050 |
| `-u, --user` | Usuário do sistema | zabbix |
| `--enable-psk` | Habilita encriptação PSK | Não |
| `-f, --force` | Força reinstalação | Não |

## 📊 Distribuições Testadas

| Distribuição | Versões | Status |
|--------------|---------|--------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | ✅ |
| Debian | 9, 10, 11, 12 | ✅ |
| CentOS | 7, 8, Stream | ✅ |
| RHEL | 7, 8, 9 | ✅ |
| Alpine | 3.16+ | ✅ |
| WSL | Ubuntu/Debian | ✅ |

## 🔒 Segurança

### Configurando PSK (Script Avançado)

```bash
# Gerar chave PSK
openssl rand -hex 32 > /etc/zabbix/zabbix.psk

# Instalar com PSK
sudo ./install_zabbix_agent_advanced.sh \
  --enable-psk \
  --psk-identity "PSK001" \
  --psk-file /etc/zabbix/zabbix.psk \
  192.168.1.100 secure-server
```

## 🐛 Troubleshooting

### Verificar Status
```bash
systemctl status zabbix-agent
```

### Ver Logs
```bash
tail -f /var/log/zabbix/zabbix_agentd.log
```

### Testar Conectividade
```bash
zabbix_get -s 127.0.0.1 -k agent.version
```

### Liberar Firewall
```bash
# firewalld
sudo firewall-cmd --permanent --add-port=10050/tcp
sudo firewall-cmd --reload

# ufw
sudo ufw allow 10050/tcp
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Add MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

- 🐛 Issues: [GitHub Issues](https://github.com/elvisfalmeida/zabbix-agent-install/issues)
- 💬 Discussões: [GitHub Discussions](https://github.com/elvisfalmeida/zabbix-agent-install/discussions)

## 🙏 Agradecimentos

- [Zabbix](https://www.zabbix.com/) pela excelente ferramenta de monitoramento
- Comunidade open source pelos testes e feedback

---

⭐ Se este projeto te ajudou, considere dar uma estrela no GitHub!
