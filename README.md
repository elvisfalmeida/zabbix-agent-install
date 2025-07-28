# 🚀 Zabbix Agent Universal Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Zabbix](https://img.shields.io/badge/Zabbix-7.2.4-red.svg)](https://www.zabbix.com/)
[![Linux](https://img.shields.io/badge/Linux-Universal-blue.svg)](https://www.linux.org/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

Scripts universais para instalação automatizada do Zabbix Agent em qualquer distribuição Linux, utilizando binários estáticos oficiais.

## 📋 Características

- ✅ **Universal**: Funciona em qualquer distribuição Linux
- ✅ **Multi-arquitetura**: Suporte para amd64 e i386
- ✅ **Sem dependências**: Usa binários estáticos oficiais
- ✅ **Detecção automática**: Identifica distro, arquitetura e init system
- ✅ **Configuração flexível**: Múltiplas opções via linha de comando
- ✅ **Seguro**: Suporte a PSK encryption
- ✅ **Produção-ready**: Testado em ambientes corporativos

## 🔧 Requisitos

- Linux (qualquer distribuição)
- Acesso root (sudo)
- wget
- Conexão com internet (para download dos binários)

## 📦 Versões dos Scripts

### 1. `install_zabbix_agent_basic.sh`
Script básico com instalação padrão simples.

```bash
sudo ./install_zabbix_agent_basic.sh IP_SERVIDOR HOSTNAME
```

### 2. `install_zabbix_agent_universal.sh`
Script com detecção automática de sistema e arquitetura.

```bash
sudo ./install_zabbix_agent_universal.sh IP_SERVIDOR HOSTNAME [ARQUITETURA]
```

### 3. `install_zabbix_agent_advanced.sh`
Script completo com todas as opções de customização.

```bash
sudo ./install_zabbix_agent_advanced.sh [OPÇÕES] IP_SERVIDOR HOSTNAME
```

## 🚀 Instalação Rápida

```bash
# Clone o repositório
git clone https://github.com/elvisfalmeida/zabbix-agent-install.git
cd zabbix-agent-install

# Torne o script executável
chmod +x install_zabbix_agent_universal.sh

# Execute a instalação
sudo ./install_zabbix_agent_universal.sh 192.168.1.100 meu-servidor
```

## 📖 Exemplos de Uso

### Instalação Básica
```bash
sudo ./install_zabbix_agent_universal.sh 192.168.1.100 webserver-01
```

### Forçar Arquitetura i386
```bash
sudo ./install_zabbix_agent_universal.sh 192.168.1.100 legacy-server i386
```

### Instalação Avançada com PSK
```bash
sudo ./install_zabbix_agent_advanced.sh \
  --enable-psk \
  --psk-identity "PSK001" \
  --psk-file /etc/zabbix/zabbix.psk \
  192.168.1.100 secure-server
```

### Instalação Customizada Completa
```bash
sudo ./install_zabbix_agent_advanced.sh \
  -v 7.2.4 \
  -p 10051 \
  -w 5 \
  --install-dir /opt/monitoring/zabbix \
  --enable-remote \
  192.168.1.100 production-01
```

## 🛠️ Opções Disponíveis (Script Avançado)

| Opção | Descrição | Padrão |
|-------|-----------|--------|
| `-v, --version` | Versão do Zabbix Agent | 7.2.4 |
| `-a, --arch` | Arquitetura (amd64, i386, auto) | auto |
| `-p, --port` | Porta de escuta | 10050 |
| `-u, --user` | Usuário do sistema | zabbix |
| `-t, --timeout` | Timeout em segundos | 4 |
| `-w, --workers` | Número de processos | 3 |
| `--install-dir` | Diretório de instalação | /opt/zabbix |
| `--config-dir` | Diretório de configuração | /etc/zabbix |
| `--enable-remote` | Habilita comandos remotos | Não |
| `--enable-psk` | Habilita encriptação PSK | Não |
| `-f, --force` | Força reinstalação | Não |
| `-n, --dry-run` | Simula instalação | Não |

## 📊 Distribuições Testadas

| Distribuição | Versões | Status |
|--------------|---------|--------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | ✅ |
| Debian | 9, 10, 11, 12 | ✅ |
| CentOS | 7, 8, Stream | ✅ |
| RHEL | 7, 8, 9 | ✅ |
| Fedora | 36, 37, 38 | ✅ |
| openSUSE | Leap 15.x | ✅ |
| Alpine | 3.16, 3.17, 3.18 | ✅ |
| Arch Linux | Rolling | ✅ |
| WSL | Ubuntu/Debian | ✅ |

## 🔒 Segurança

### Configurando PSK

1. Gere uma chave PSK:
```bash
openssl rand -hex 32 > /etc/zabbix/zabbix.psk
chmod 600 /etc/zabbix/zabbix.psk
chown zabbix:zabbix /etc/zabbix/zabbix.psk
```

2. Instale com PSK habilitado:
```bash
sudo ./install_zabbix_agent_advanced.sh \
  --enable-psk \
  --psk-identity "$(hostname)-PSK" \
  --psk-file /etc/zabbix/zabbix.psk \
  192.168.1.100 $(hostname)
```

## 🐛 Troubleshooting

### Verificar se o agente está rodando
```bash
systemctl status zabbix-agent
ps aux | grep zabbix_agentd
```

### Ver logs
```bash
tail -f /var/log/zabbix/zabbix_agentd.log
```

### Testar conectividade
```bash
zabbix_get -s 127.0.0.1 -k agent.version
```

### Portas de firewall
```bash
# Para firewalld
sudo firewall-cmd --permanent --add-port=10050/tcp
sudo firewall-cmd --reload

# Para ufw
sudo ufw allow 10050/tcp

# Para iptables
sudo iptables -A INPUT -p tcp --dport 10050 -j ACCEPT
```

## 📝 Estrutura do Projeto

```
zabbix-agent-install/
├── README.md                           # Este arquivo
├── LICENSE                            # Licença MIT
├── install_zabbix_agent_basic.sh      # Script básico
├── install_zabbix_agent_universal.sh  # Script universal
├── install_zabbix_agent_advanced.sh   # Script avançado
├── docs/
│   ├── TROUBLESHOOTING.md            # Guia de resolução de problemas
│   ├── SECURITY.md                   # Guia de segurança
│   └── EXAMPLES.md                   # Exemplos detalhados
├── tests/
│   ├── test_ubuntu.sh                # Testes para Ubuntu
│   ├── test_centos.sh                # Testes para CentOS
│   └── test_alpine.sh                # Testes para Alpine
└── utils/
    ├── uninstall.sh                  # Script de desinstalação
    └── update.sh                     # Script de atualização
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- [Zabbix](https://www.zabbix.com/) pela excelente ferramenta de monitoramento
- Comunidade open source pelos testes e feedback

## 📞 Suporte

- 📧 Email: suporte@ebyte.net.br
- 🐛 Issues: [GitHub Issues](https://github.com/elvisfalmeida/zabbix-agent-install/issues)
- 💬 Discussões: [GitHub Discussions](https://github.com/elvisfalmeida/zabbix-agent-install/discussions)

---

⭐ Se este projeto te ajudou, considere dar uma estrela no GitHub!
