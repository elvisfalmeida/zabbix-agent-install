#!/bin/bash

# Script avançado de instalação do Zabbix Agent
# Suporta múltiplas opções de configuração via linha de comando

set -e

# Valores padrão
DEFAULT_VERSION="7.2.4"
DEFAULT_ARCH="auto"
DEFAULT_PORT="10050"
DEFAULT_INSTALL_DIR="/opt/zabbix"
DEFAULT_CONFIG_DIR="/etc/zabbix"
DEFAULT_LOG_DIR="/var/log/zabbix"
DEFAULT_PID_DIR="/var/run/zabbix"
DEFAULT_USER="zabbix"
DEFAULT_TIMEOUT="4"
DEFAULT_START_AGENTS="3"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variáveis globais
ZABBIX_SERVER=""
HOSTNAME=""
ZABBIX_VERSION="$DEFAULT_VERSION"
SYSTEM_ARCH="$DEFAULT_ARCH"
LISTEN_PORT="$DEFAULT_PORT"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
CONFIG_DIR="$DEFAULT_CONFIG_DIR"
LOG_DIR="$DEFAULT_LOG_DIR"
PID_DIR="$DEFAULT_PID_DIR"
ZABBIX_USER="$DEFAULT_USER"
TIMEOUT="$DEFAULT_TIMEOUT"
START_AGENTS="$DEFAULT_START_AGENTS"
ENABLE_REMOTE_COMMANDS=0
ENABLE_PSK=0
PSK_IDENTITY=""
PSK_FILE=""
FORCE_INSTALL=0
SKIP_SERVICE=0
QUIET_MODE=0
DRY_RUN=0

# Função para imprimir mensagens
print_info() {
    [ $QUIET_MODE -eq 0 ] && echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

print_warning() {
    [ $QUIET_MODE -eq 0 ] && echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_debug() {
    [ $QUIET_MODE -eq 0 ] && echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Função para mostrar ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES] IP_SERVIDOR HOSTNAME

Script avançado para instalação do Zabbix Agent com suporte a múltiplas configurações.

PARÂMETROS OBRIGATÓRIOS:
    IP_SERVIDOR              IP ou hostname do servidor Zabbix
    HOSTNAME                 Nome do host no Zabbix

OPÇÕES:
    -h, --help              Mostra esta ajuda
    -v, --version VERSION   Versão do Zabbix Agent (padrão: $DEFAULT_VERSION)
    -a, --arch ARCH         Arquitetura: amd64, i386, auto (padrão: $DEFAULT_ARCH)
    -p, --port PORT         Porta de escuta (padrão: $DEFAULT_PORT)
    -u, --user USER         Usuário do sistema (padrão: $DEFAULT_USER)
    -t, --timeout SECONDS   Timeout das operações (padrão: $DEFAULT_TIMEOUT)
    -w, --workers NUMBER    Número de processos (padrão: $DEFAULT_START_AGENTS)
    
DIRETÓRIOS:
    --install-dir DIR       Diretório de instalação (padrão: $DEFAULT_INSTALL_DIR)
    --config-dir DIR        Diretório de configuração (padrão: $DEFAULT_CONFIG_DIR)
    --log-dir DIR           Diretório de logs (padrão: $DEFAULT_LOG_DIR)
    --pid-dir DIR           Diretório do PID (padrão: $DEFAULT_PID_DIR)
    
RECURSOS:
    --enable-remote         Habilita comandos remotos
    --enable-psk            Habilita encriptação PSK
    --psk-identity ID       Identidade PSK
    --psk-file FILE         Arquivo com chave PSK
    
MODOS DE INSTALAÇÃO:
    -f, --force             Força reinstalação mesmo se já existir
    -q, --quiet             Modo silencioso (menos output)
    -n, --dry-run           Simula instalação sem fazer mudanças
    --skip-service          Não configura serviço de inicialização
    
EXEMPLOS:
    # Instalação básica
    $0 192.168.1.100 webserver-01
    
    # Instalação com versão específica e porta customizada
    $0 -v 7.0.0 -p 10051 192.168.1.100 webserver-01
    
    # Instalação i386 com comandos remotos habilitados
    $0 -a i386 --enable-remote 192.168.1.100 legacy-server
    
    # Instalação com PSK
    $0 --enable-psk --psk-identity "PSK001" --psk-file /etc/zabbix/zabbix.psk 192.168.1.100 secure-server
    
    # Instalação em diretório customizado
    $0 --install-dir /usr/local/zabbix --config-dir /usr/local/etc/zabbix 192.168.1.100 custom-server
    
    # Modo dry-run para testar
    $0 -n 192.168.1.100 test-server

VERSÕES DISPONÍVEIS DO ZABBIX:
    7.2.4, 7.2.0, 7.0.0, 6.4.0, 6.2.0, 6.0.0 (LTS)

EOF
}

# Processar argumentos
parse_arguments() {
    # Arrays para armazenar parâmetros posicionais
    local positional_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                ZABBIX_VERSION="$2"
                shift 2
                ;;
            -a|--arch)
                SYSTEM_ARCH="$2"
                shift 2
                ;;
            -p|--port)
                LISTEN_PORT="$2"
                shift 2
                ;;
            -u|--user)
                ZABBIX_USER="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -w|--workers)
                START_AGENTS="$2"
                shift 2
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --config-dir)
                CONFIG_DIR="$2"
                shift 2
                ;;
            --log-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            --pid-dir)
                PID_DIR="$2"
                shift 2
                ;;
            --enable-remote)
                ENABLE_REMOTE_COMMANDS=1
                shift
                ;;
            --enable-psk)
                ENABLE_PSK=1
                shift
                ;;
            --psk-identity)
                PSK_IDENTITY="$2"
                shift 2
                ;;
            --psk-file)
                PSK_FILE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_INSTALL=1
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=1
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            --skip-service)
                SKIP_SERVICE=1
                shift
                ;;
            -*)
                print_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
            *)
                positional_args+=("$1")
                shift
                ;;
        esac
    done
    
    # Verificar argumentos posicionais
    if [ ${#positional_args[@]} -lt 2 ]; then
        print_error "Parâmetros obrigatórios faltando!"
        echo "Uso: $0 [OPÇÕES] IP_SERVIDOR HOSTNAME"
        echo "Use -h ou --help para mais informações"
        exit 1
    fi
    
    ZABBIX_SERVER="${positional_args[0]}"
    HOSTNAME="${positional_args[1]}"
}

# Validar parâmetros
validate_parameters() {
    # Validar versão
    if ! [[ "$ZABBIX_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Versão inválida: $ZABBIX_VERSION"
        exit 1
    fi
    
    # Validar arquitetura
    if [[ "$SYSTEM_ARCH" != "auto" && "$SYSTEM_ARCH" != "amd64" && "$SYSTEM_ARCH" != "i386" ]]; then
        print_error "Arquitetura inválida: $SYSTEM_ARCH"
        exit 1
    fi
    
    # Validar porta
    if ! [[ "$LISTEN_PORT" =~ ^[0-9]+$ ]] || [ "$LISTEN_PORT" -lt 1 ] || [ "$LISTEN_PORT" -gt 65535 ]; then
        print_error "Porta inválida: $LISTEN_PORT"
        exit 1
    fi
    
    # Validar PSK
    if [ $ENABLE_PSK -eq 1 ]; then
        if [ -z "$PSK_IDENTITY" ] || [ -z "$PSK_FILE" ]; then
            print_error "PSK habilitado mas falta --psk-identity ou --psk-file"
            exit 1
        fi
    fi
}

# Detectar arquitetura se auto
detect_architecture() {
    if [ "$SYSTEM_ARCH" = "auto" ]; then
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
                exit 1
                ;;
        esac
    fi
    print_info "Arquitetura: $SYSTEM_ARCH"
}

# Mostrar resumo da instalação
show_summary() {
    echo ""
    echo "========================================"
    echo "   Resumo da Instalação"
    echo "========================================"
    echo "Servidor Zabbix: $ZABBIX_SERVER"
    echo "Hostname: $HOSTNAME"
    echo "Versão: $ZABBIX_VERSION"
    echo "Arquitetura: $SYSTEM_ARCH"
    echo "Porta: $LISTEN_PORT"
    echo "Usuário: $ZABBIX_USER"
    echo ""
    echo "Diretórios:"
    echo "  Instalação: $INSTALL_DIR"
    echo "  Configuração: $CONFIG_DIR"
    echo "  Logs: $LOG_DIR"
    echo "  PID: $PID_DIR"
    echo ""
    echo "Configurações:"
    echo "  Timeout: $TIMEOUT segundos"
    echo "  Workers: $START_AGENTS"
    echo "  Comandos remotos: $([ $ENABLE_REMOTE_COMMANDS -eq 1 ] && echo "Sim" || echo "Não")"
    echo "  PSK: $([ $ENABLE_PSK -eq 1 ] && echo "Sim" || echo "Não")"
    
    if [ $DRY_RUN -eq 1 ]; then
        echo ""
        echo "** MODO DRY-RUN - Nenhuma alteração será feita **"
    fi
    
    echo "========================================"
    echo ""
    
    if [ $DRY_RUN -eq 0 ]; then
        read -p "Continuar com a instalação? [S/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Instalação cancelada."
            exit 0
        fi
    fi
}

# Função principal de instalação (simplificada para exemplo)
do_install() {
    if [ $DRY_RUN -eq 1 ]; then
        print_info "[DRY-RUN] Instalaria o Zabbix Agent com as configurações especificadas"
        return 0
    fi
    
    # Verificar se está rodando como root
    if [ "$EUID" -ne 0 ] && [ $DRY_RUN -eq 0 ]; then 
        print_error "Por favor, execute como root (use sudo)"
        exit 1
    fi
    
    # Verificar instalação existente
    if [ -f "$INSTALL_DIR/sbin/zabbix_agentd" ] && [ $FORCE_INSTALL -eq 0 ]; then
        print_error "Zabbix Agent já instalado em $INSTALL_DIR"
        print_info "Use -f ou --force para forçar reinstalação"
        exit 1
    fi
    
    print_info "Iniciando instalação..."
    
    # URL de download
    local major_version=$(echo $ZABBIX_VERSION | cut -d. -f1,2)
    local download_url="https://cdn.zabbix.com/zabbix/binaries/stable/${major_version}/${ZABBIX_VERSION}/zabbix_agent-${ZABBIX_VERSION}-linux-3.0-${SYSTEM_ARCH}-static.tar.gz"
    
    print_info "URL: $download_url"
    
    # Criar configuração
    local config_content="# Zabbix Agent Configuration
# Gerado por script de instalação em $(date)

PidFile=$PID_DIR/zabbix_agentd.pid
LogFile=$LOG_DIR/zabbix_agentd.log
LogFileSize=0

Server=$ZABBIX_SERVER
ServerActive=$ZABBIX_SERVER
Hostname=$HOSTNAME
ListenPort=$LISTEN_PORT

EnableRemoteCommands=$ENABLE_REMOTE_COMMANDS
LogRemoteCommands=$ENABLE_REMOTE_COMMANDS

StartAgents=$START_AGENTS
Timeout=$TIMEOUT

Include=$CONFIG_DIR/zabbix_agentd.d/*.conf"

    if [ $ENABLE_PSK -eq 1 ]; then
        config_content="$config_content

# PSK Configuration
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=$PSK_IDENTITY
TLSPSKFile=$PSK_FILE"
    fi
    
    print_info "Configuração será criada em: $CONFIG_DIR/zabbix_agentd.conf"
    
    # Aqui continuaria o processo real de instalação...
    print_info "Instalação completa (modo demo)"
}

# Main
main() {
    parse_arguments "$@"
    validate_parameters
    detect_architecture
    show_summary
    do_install
}

# Executar
main "$@"
