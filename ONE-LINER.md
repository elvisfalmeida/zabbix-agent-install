# 🚀 Instalação Rápida com One-liner

Instale o Zabbix Agent em qualquer Linux com apenas um comando!

## 📋 Instalação Básica

```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- IP_SERVIDOR HOSTNAME
```

### Exemplo real:
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 webserver-01
```

## 🏗️ Instalação com Arquitetura Específica

### Forçar i386 (32 bits):
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 legacy-server i386
```

### Forçar amd64 (64 bits):
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 modern-server amd64
```

## 🔧 Usando wget ao invés de curl

Se você não tem curl instalado, pode usar wget:

```bash
wget -qO- https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- IP_SERVIDOR HOSTNAME
```

## 🎯 Instalação Automatizada em Múltiplos Servidores

### Script para múltiplos hosts:
```bash
#!/bin/bash
# install_multiple.sh

ZABBIX_SERVER="192.168.1.100"
INSTALLER_URL="https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh"

# Lista de servidores
SERVERS=(
    "web-01:192.168.1.10"
    "web-02:192.168.1.11"
    "db-01:192.168.1.20"
    "app-01:192.168.1.30"
)

for server in "${SERVERS[@]}"; do
    IFS=':' read -r hostname ip <<< "$server"
    echo "Instalando em $hostname ($ip)..."
    
    ssh root@$ip "curl -sSL $INSTALLER_URL | bash -s -- $ZABBIX_SERVER $hostname"
    
    if [ $? -eq 0 ]; then
        echo "✅ $hostname - Instalação concluída"
    else
        echo "❌ $hostname - Falha na instalação"
    fi
    echo ""
done
```

## 🐳 Uso em Dockerfile

```dockerfile
FROM ubuntu:22.04

ENV ZABBIX_SERVER=192.168.1.100
ENV HOSTNAME=docker-container

RUN apt-get update && apt-get install -y curl && \
    curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | \
    bash -s -- ${ZABBIX_SERVER} ${HOSTNAME} && \
    apt-get clean

EXPOSE 10050

CMD ["/usr/local/sbin/zabbix_agentd", "-f", "-c", "/etc/zabbix/zabbix_agentd.conf"]
```

## 📊 Instalação via Ansible

```yaml
---
- name: Instalar Zabbix Agent
  hosts: all
  become: yes
  vars:
    zabbix_server: "192.168.1.100"
    
  tasks:
    - name: Download e executa instalador
      shell: |
        curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | \
        bash -s -- {{ zabbix_server }} {{ inventory_hostname }}
      args:
        creates: /usr/local/sbin/zabbix_agentd
```

## 🔒 Verificar Integridade (Opcional)

Para ambientes que exigem maior segurança:

```bash
# 1. Baixar o script primeiro
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh -o install.sh

# 2. Verificar o conteúdo
less install.sh

# 3. Executar após verificação
sudo bash install.sh 192.168.1.100 $(hostname)
```

## ⚡ Instalação Super Rápida (hostname automático)

Use o hostname da máquina automaticamente:

```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 $(hostname)
```

## 🛠️ Variações Úteis

### Com hostname FQDN:
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 $(hostname -f)
```

### Com hostname e domínio:
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 192.168.1.100 "$(hostname).exemplo.com"
```

### Para servidor local (localhost):
```bash
curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- 127.0.0.1 zabbix-server
```

## ❓ Troubleshooting

### Erro de permissão:
```bash
# Certifique-se de usar sudo
curl -sSL ... | sudo bash -s -- ...
```

### Sem curl instalado:
```bash
# Instalar curl primeiro
sudo apt-get update && sudo apt-get install -y curl  # Debian/Ubuntu
sudo yum install -y curl                              # RHEL/CentOS
```

### Verificar instalação:
```bash
# Após instalação
systemctl status zabbix-agent
zabbix_agentd -V
```

## 📝 Notas

- O script detecta automaticamente a distribuição e arquitetura
- Funciona em qualquer Linux com systemd ou SysV init
- Usa binários estáticos oficiais do Zabbix
- Não requer repositórios adicionais
- Configuração básica pronta para uso

---

💡 **Dica**: Salve o comando no seu `.bashrc` como alias para uso futuro:

```bash
echo 'alias install-zabbix="curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s --"' >> ~/.bashrc
source ~/.bashrc

# Uso:
install-zabbix 192.168.1.100 $(hostname)
```
