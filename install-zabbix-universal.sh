#!/bin/bash

# Script universal de instalação do Zabbix Agent
# Suporta múltiplas distribuições Linux e arquiteturas (amd64, i386)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Por favor, execute como root (use sudo)"
    exit 1
fi

# Verificar parâmetros
if [ $# -lt 2 ]; then
    echo "Uso: $0 IP_SERVIDOR_ZABBIX NOME_HOST [ARQUITETURA]"
    echo "Exemplo: $0 192.168.1.100 servidor-web-01"
    echo "         $0 192.168.1.100 servidor-legacy i386"
    echo ""
    echo "Arquiteturas suportadas: amd64 (padrão), i386"
    exit 1
fi

ZABBIX_SERVER=$1
HOSTNAME=$2
FORCE_ARCH=${3:-"auto"}
ZABBIX_VERSION="7.2.4"

# Detectar arquitetura do sistema
detect_architecture() {
    local arch=$(uname -m)
    
    case $arch in
        x86_64|amd64)
            SYSTEM_ARCH="amd64"
            ;;
        i386|i486|i586|i686)
            SYSTEM_ARCH="i386"
            ;;
        *)
            print_error "Arquitetura não suportada: $arch"
            print_info "Este script suporta apenas amd64 (x86_64) e i386"
            exit 1
            ;;
    esac
    
    # Se o usuário forçou uma arquitetura, usar ela
    if [ "$FORCE_ARCH" != "auto" ]; then
        if [ "$FORCE_ARCH" = "amd64" ] || [ "$FORCE_ARCH" = "i386" ]; then
            print_warning "Forçando arquitetura: $FORCE_ARCH (sistema detectado: $SYSTEM_ARCH)"
            SYSTEM_ARCH=$FORCE_ARCH
        else
            print_error "Arquitetura inválida: $FORCE_ARCH. Use 'amd64' ou 'i386'"
            exit 1
        fi
    fi
    
    print_info "Arquitetura selecionada: $SYSTEM_ARCH"
}

# Detectar distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        DISTRO_NAME=$PRETTY_NAME
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        DISTRO_NAME=$(cat /etc/redhat-release)
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_NAME="Debian $(cat /etc/debian_version)"
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown Linux"
    fi
    
    print_info "Distribuição detectada: $DISTRO_NAME"
}

# Detectar sistema de init
detect_init_system() {
    if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
        INIT_SYSTEM="systemd"
    elif command -v service >/dev/null 2>&1; then
        INIT_SYSTEM="sysv"
    elif [ -d /etc/init.d ]; then
        INIT_SYSTEM="sysv"
    else
        INIT_SYSTEM="unknown"
    fi
    
    print_info "Sistema de init detectado: $INIT_SYSTEM"
}

# Verificar se a arquitetura i386 pode rodar em sistema amd64
check_multiarch_support() {
    if [ "$SYSTEM_ARCH" = "i386" ] && [ "$(uname -m)" = "x86_64" ]; then
        print_warning "Tentando instalar Zabbix i386 em sistema x86_64"
        
        # Verificar se tem suporte a 32 bits
        if [ -f /lib/ld-linux.so.2 ] || [ -f /lib32/ld-linux.so.2 ]; then
            print_info "Suporte a 32 bits detectado"
        else
            print_warning "Suporte a 32 bits pode não estar disponível"
            print_info "Em Debian/Ubuntu, instale: apt-get install libc6-i386"
            print_info "Em RHEL/CentOS, instale: yum install glibc.i686"
            
            read -p "Deseja continuar mesmo assim? [s/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Ss]$ ]]; then
                exit 1
            fi
        fi
    fi
}

# Instalar wget se necessário
ensure_wget() {
    if ! command -v wget >/dev/null 2>&1; then
        print_warning "wget não encontrado. Tentando instalar..."
        
        case $DISTRO in
            ubuntu|debian)
                apt-get update && apt-get install -y wget
                ;;
            rhel|centos|fedora)
                yum install -y wget || dnf install -y wget
                ;;
            alpine)
                apk add wget
                ;;
            arch)
                pacman -S --noconfirm wget
                ;;
            *)
                print_error "Não foi possível instalar wget automaticamente. Por favor, instale manualmente."
                exit 1
                ;;
        esac
    fi
}

# Criar usuário zabbix
create_user() {
    if ! id "zabbix" &>/dev/null; then
        print_info "Criando usuário zabbix..."
        
        case $DISTRO in
            alpine)
                adduser -S -D -H -s /sbin/nologin zabbix
                ;;
            *)
                useradd -r -s /bin/false zabbix 2>/dev/null || \
                useradd -r -s /sbin/nologin zabbix
                ;;
        esac
    else
        print_info "Usuário zabbix já existe"
    fi
}

# Criar serviço para systemd
create_systemd_service() {
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

    systemctl daemon-reload
    systemctl enable zabbix-agent
    systemctl start zabbix-agent
}

# Criar serviço para SysV init
create_sysv_service() {
    cat > /etc/init.d/zabbix-agent << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-agent
# Required-Start:    $network $syslog
# Required-Stop:     $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start zabbix-agent at boot time
# Description:       Zabbix Agent
### END INIT INFO

NAME=zabbix_agentd
DAEMON=/usr/local/sbin/$NAME
PIDFILE=/var/run/zabbix/$NAME.pid
CONFIG=/etc/zabbix/zabbix_agentd.conf

case "$1" in
    start)
        echo "Starting $NAME..."
        start-stop-daemon --start --pidfile $PIDFILE --exec $DAEMON -- -c $CONFIG
        ;;
    stop)
        echo "Stopping $NAME..."
        start-stop-daemon --stop --pidfile $PIDFILE --retry 5
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    status)
        if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null; then
            echo "$NAME is running"
        else
            echo "$NAME is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

    chmod +x /etc/init.d/zabbix-agent
    
    # Habilitar o serviço
    if command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d zabbix-agent defaults
    elif command -v chkconfig >/dev/null 2>&1; then
        chkconfig --add zabbix-agent
        chkconfig zabbix-agent on
    fi
    
    # Iniciar o serviço
    /etc/init.d/zabbix-agent start
}

# INÍCIO DA INSTALAÇÃO
clear
echo "=============================================="
echo "   Instalador Universal do Zabbix Agent"
echo "=============================================="
echo ""
echo "Versão do Zabbix: ${ZABBIX_VERSION}"
echo "Servidor Zabbix: ${ZABBIX_SERVER}"
echo "Hostname: ${HOSTNAME}"
echo ""

# Detectar sistema
detect_distro
detect_architecture
detect_init_system
check_multiarch_support

# Definir URL de download baseada na arquitetura
DOWNLOAD_URL="https://cdn.zabbix.com/zabbix/binaries/stable/7.2/${ZABBIX_VERSION}/zabbix_agent-${ZABBIX_VERSION}-linux-3.0-${SYSTEM_ARCH}-static.tar.gz"
print_info "URL de download: $DOWNLOAD_URL"

ensure_wget

# 1. Criar diretórios
print_info "Criando diretórios..."
mkdir -p /opt/zabbix
mkdir -p /etc/zabbix
mkdir -p /var/log/zabbix
mkdir -p /var/run/zabbix

# 2. Criar usuário
create_user

# 3. Baixar e extrair
print_info "Baixando Zabbix Agent (${SYSTEM_ARCH})..."
cd /tmp

# Remover arquivo antigo se existir
rm -f zabbix_agent.tar.gz

wget --progress=bar:force "${DOWNLOAD_URL}" -O zabbix_agent.tar.gz || {
    print_error "Falha ao baixar o Zabbix Agent"
    print_error "Verifique sua conexão com a internet e a URL"
    exit 1
}

# Verificar tamanho do arquivo baixado
if [ ! -s zabbix_agent.tar.gz ]; then
    print_error "Arquivo baixado está vazio"
    exit 1
fi

print_info "Extraindo arquivos..."
# Limpar diretório antigo se existir
rm -rf /opt/zabbix/*

tar -xzf zabbix_agent.tar.gz -C /opt/zabbix || {
    print_error "Falha ao extrair arquivos"
    exit 1
}
rm -f zabbix_agent.tar.gz

# Verificar se os binários foram extraídos corretamente
if [ ! -f /opt/zabbix/sbin/zabbix_agentd ]; then
    print_error "Binário zabbix_agentd não encontrado após extração"
    exit 1
fi

# Verificar arquitetura do binário extraído
print_debug "Verificando binário extraído..."
file /opt/zabbix/sbin/zabbix_agentd

# 4. Configurar permissões
print_info "Configurando permissões..."
chown -R zabbix:zabbix /var/log/zabbix
chown -R zabbix:zabbix /var/run/zabbix

# 5. Criar arquivo de configuração
print_info "Criando arquivo de configuração..."
cat > /etc/zabbix/zabbix_agentd.conf << EOF
# Configuração do Zabbix Agent
# Arquitetura: ${SYSTEM_ARCH}
# Instalado em: $(date)

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
print_info "Criando links simbólicos..."
ln -sf /opt/zabbix/sbin/zabbix_agentd /usr/local/sbin/zabbix_agentd
ln -sf /opt/zabbix/bin/zabbix_get /usr/local/bin/zabbix_get 2>/dev/null || true
ln -sf /opt/zabbix/bin/zabbix_sender /usr/local/bin/zabbix_sender 2>/dev/null || true

# 8. Criar e iniciar serviço baseado no sistema de init
print_info "Configurando serviço..."
case $INIT_SYSTEM in
    systemd)
        create_systemd_service
        ;;
    sysv)
        create_sysv_service
        ;;
    *)
        print_warning "Sistema de init não reconhecido. Você precisará iniciar o Zabbix Agent manualmente:"
        echo "/usr/local/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf"
        ;;
esac

# 9. Verificar se está rodando
sleep 2
if pgrep -x "zabbix_agentd" > /dev/null; then
    print_info "Zabbix Agent está rodando!"
    
    # Testar comunicação
    if [ -x /opt/zabbix/bin/zabbix_get ]; then
        print_info "Testando comunicação local..."
        /opt/zabbix/bin/zabbix_get -s 127.0.0.1 -k agent.version 2>/dev/null || true
        
        # Mostrar informações do agente
        print_info "Informações do agente:"
        /opt/zabbix/bin/zabbix_get -s 127.0.0.1 -k system.uname 2>/dev/null || true
    fi
else
    print_error "Zabbix Agent não está rodando. Verifique os logs em /var/log/zabbix/zabbix_agentd.log"
fi

echo ""
echo "=============================================="
echo "         Instalação concluída!"
echo "=============================================="
echo ""
echo "Informações da instalação:"
echo "- Arquitetura: ${SYSTEM_ARCH}"
echo "- Versão: ${ZABBIX_VERSION}"
echo "- Porta: 10050"
echo "- Configuração: /etc/zabbix/zabbix_agentd.conf"
echo "- Logs: /var/log/zabbix/zabbix_agentd.log"
echo "- PID: /var/run/zabbix/zabbix_agentd.pid"
echo ""

if [ "$INIT_SYSTEM" = "systemd" ]; then
    echo "Comandos úteis:"
    echo "  systemctl status zabbix-agent"
    echo "  systemctl restart zabbix-agent"
    echo "  journalctl -u zabbix-agent -f"
elif [ "$INIT_SYSTEM" = "sysv" ]; then
    echo "Comandos úteis:"
    echo "  /etc/init.d/zabbix-agent status"
    echo "  /etc/init.d/zabbix-agent restart"
fi

echo "  tail -f /var/log/zabbix/zabbix_agentd.log"
echo ""
echo "Próximos passos:"
echo "1. Liberar a porta 10050 no firewall"
echo "2. Adicionar este host no servidor Zabbix"
echo "   - Nome do host: ${HOSTNAME}"
echo "   - IP do agente: $(hostname -I | awk '{print $1}')"
echo ""

# Mostrar aviso se for i386 em sistema 64 bits
if [ "$SYSTEM_ARCH" = "i386" ] && [ "$(uname -m)" = "x86_64" ]; then
    print_warning "Nota: Você instalou a versão i386 em um sistema x86_64"
    print_warning "Certifique-se de que as bibliotecas 32 bits estão instaladas"
fi
