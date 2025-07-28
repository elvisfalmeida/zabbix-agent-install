#!/bin/bash

# Script de desinstalação do Zabbix Agent
# Remove completamente o Zabbix Agent instalado pelos scripts

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Por favor, execute como root (use sudo)"
    exit 1
fi

echo "========================================"
echo "   Desinstalador do Zabbix Agent"
echo "========================================"
echo ""

# Detectar sistema de init
INIT_SYSTEM="unknown"
if command -v systemctl >/dev/null 2>&1; then
    INIT_SYSTEM="systemd"
elif [ -f /etc/init.d/zabbix-agent ]; then
    INIT_SYSTEM="sysv"
fi

print_info "Sistema de init detectado: $INIT_SYSTEM"

# Parar o serviço
print_info "Parando o serviço Zabbix Agent..."
case $INIT_SYSTEM in
    systemd)
        systemctl stop zabbix-agent 2>/dev/null || true
        systemctl disable zabbix-agent 2>/dev/null || true
        ;;
    sysv)
        /etc/init.d/zabbix-agent stop 2>/dev/null || true
        if command -v update-rc.d >/dev/null 2>&1; then
            update-rc.d -f zabbix-agent remove 2>/dev/null || true
        elif command -v chkconfig >/dev/null 2>&1; then
            chkconfig --del zabbix-agent 2>/dev/null || true
        fi
        ;;
esac

# Matar processos remanescentes
print_info "Verificando processos remanescentes..."
pkill -f zabbix_agentd 2>/dev/null || true

# Remover arquivos de serviço
print_info "Removendo arquivos de serviço..."
rm -f /etc/systemd/system/zabbix-agent.service
rm -f /etc/init.d/zabbix-agent
systemctl daemon-reload 2>/dev/null || true

# Fazer backup das configurações
if [ -d /etc/zabbix ]; then
    BACKUP_FILE="/tmp/zabbix-agent-config-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    print_info "Fazendo backup das configurações em: $BACKUP_FILE"
    tar -czf "$BACKUP_FILE" /etc/zabbix 2>/dev/null || true
fi

# Remover diretórios e arquivos
print_info "Removendo arquivos do Zabbix Agent..."
rm -rf /opt/zabbix
rm -rf /etc/zabbix
rm -rf /var/log/zabbix
rm -rf /var/run/zabbix
rm -f /usr/local/sbin/zabbix_agentd
rm -f /usr/local/bin/zabbix_get
rm -f /usr/local/bin/zabbix_sender

# Remover usuário (opcional)
read -p "Remover usuário 'zabbix' do sistema? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    print_info "Removendo usuário zabbix..."
    userdel zabbix 2>/dev/null || true
    groupdel zabbix 2>/dev/null || true
else
    print_warning "Usuário 'zabbix' mantido no sistema"
fi

print_info "Limpando cache..."
rm -f /tmp/zabbix_agent*.tar.gz

echo ""
echo "========================================"
echo "   Desinstalação Concluída!"
echo "========================================"
echo ""

if [ -f "$BACKUP_FILE" ]; then
    echo "Backup das configurações salvo em:"
    echo "  $BACKUP_FILE"
    echo ""
fi

echo "O Zabbix Agent foi completamente removido do sistema."
echo ""
