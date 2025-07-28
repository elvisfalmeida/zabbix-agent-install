#!/bin/bash

# Script de instalação manual do Zabbix Agent
# Uso: sudo ./install_zabbix_agent.sh IP_SERVIDOR_ZABBIX NOME_HOST

set -e

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then 
    echo "Por favor, execute como root (use sudo)"
    exit 1
fi

# Verificar parâmetros
if [ $# -ne 2 ]; then
    echo "Uso: $0 IP_SERVIDOR_ZABBIX NOME_HOST"
    echo "Exemplo: $0 192.168.1.100 servidor-web-01"
    exit 1
fi

ZABBIX_SERVER=$1
HOSTNAME=$2
ZABBIX_VERSION="7.2.4"
DOWNLOAD_URL="https://cdn.zabbix.com/zabbix/binaries/stable/7.2/${ZABBIX_VERSION}/zabbix_agent-${ZABBIX_VERSION}-linux-3.0-amd64-static.tar.gz"

echo "=== Instalando Zabbix Agent ${ZABBIX_VERSION} ==="
echo "Servidor Zabbix: ${ZABBIX_SERVER}"
echo "Hostname: ${HOSTNAME}"
echo ""

# 1. Criar diretórios
echo "Criando diretórios..."
mkdir -p /opt/zabbix
mkdir -p /etc/zabbix
mkdir -p /var/log/zabbix
mkdir -p /var/run/zabbix

# 2. Criar usuário
echo "Criando usuário zabbix..."
if ! id "zabbix" &>/dev/null; then
    useradd -r -s /bin/false zabbix
fi

# 3. Baixar e extrair
echo "Baixando Zabbix Agent..."
cd /tmp
wget -q "${DOWNLOAD_URL}" -O zabbix_agent.tar.gz
echo "Extraindo arquivos..."
tar -xzf zabbix_agent.tar.gz -C /opt/zabbix
rm -f zabbix_agent.tar.gz

# 4. Configurar permissões
echo "Configurando permissões..."
chown -R zabbix:zabbix /var/log/zabbix
chown -R zabbix:zabbix /var/run/zabbix

# 5. Criar arquivo de configuração
echo "Criando arquivo de configuração..."
cat > /etc/zabbix/zabbix_agentd.conf << EOF
# Configuração do Zabbix Agent
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0

# Configuração do servidor
Server=${ZABBIX_SERVER}
ServerActive=${ZABBIX_SERVER}
Hostname=${HOSTNAME}

# Configurações de segurança
EnableRemoteCommands=0
LogRemoteCommands=0

# Configurações de performance
StartAgents=3
Timeout=4

# Incluir configurações adicionais
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

# 6. Criar diretório para configurações adicionais
mkdir -p /etc/zabbix/zabbix_agentd.d

# 7. Criar link simbólico
echo "Criando link simbólico..."
ln -sf /opt/zabbix/sbin/zabbix_agentd /usr/local/sbin/zabbix_agentd

# 8. Criar serviço systemd
echo "Criando serviço systemd..."
cat > /etc/systemd/system/zabbix-agent.service << EOF
[Unit]
Description=Zabbix Agent
After=syslog.target network.target

[Service]
Type=forking
User=zabbix
Group=zabbix
ExecStart=/usr/local/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf
ExecStop=/bin/kill -SIGTERM \$MAINPID
PIDFile=/var/run/zabbix/zabbix_agentd.pid
RestartSec=10s
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 9. Habilitar e iniciar serviço
echo "Habilitando e iniciando serviço..."
systemctl daemon-reload
systemctl enable zabbix-agent
systemctl start zabbix-agent

# 10. Verificar status
echo ""
echo "=== Status do serviço ==="
systemctl status zabbix-agent --no-pager

# 11. Testar comunicação
echo ""
echo "=== Testando comunicação ==="
sleep 2
/opt/zabbix/bin/zabbix_get -s 127.0.0.1 -k agent.version

echo ""
echo "=== Instalação concluída! ==="
echo ""
echo "Informações importantes:"
echo "- Porta: 10050"
echo "- Arquivo de configuração: /etc/zabbix/zabbix_agentd.conf"
echo "- Logs: /var/log/zabbix/zabbix_agentd.log"
echo "- PID: /var/run/zabbix/zabbix_agentd.pid"
echo ""
echo "Comandos úteis:"
echo "- systemctl status zabbix-agent"
echo "- systemctl restart zabbix-agent"
echo "- tail -f /var/log/zabbix/zabbix_agentd.log"
echo ""
echo "Lembre-se de:"
echo "1. Liberar a porta 10050 no firewall"
echo "2. Adicionar este host no servidor Zabbix"
