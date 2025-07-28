#!/bin/bash

# One-liner installer para Zabbix Agent
# Baixa e executa o script universal de instalação
# Uso: curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- IP_SERVIDOR HOSTNAME [ARQUITETURA]

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# URL do script universal
SCRIPT_URL="https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install_zabbix_agent_universal.sh"
TEMP_SCRIPT="/tmp/install_zabbix_agent_universal_$$.sh"

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║     Zabbix Agent One-liner Installer      ║"
    echo "║        github.com/elvisfalmeida          ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função de limpeza
cleanup() {
    rm -f "$TEMP_SCRIPT"
}

# Configurar trap para limpeza
trap cleanup EXIT

# Verificar se está sendo executado como root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Este script precisa ser executado como root (sudo)"
        echo "Uso: curl -sSL $SCRIPT_URL | sudo bash -s -- IP_SERVIDOR HOSTNAME [ARQUITETURA]"
        exit 1
    fi
}

# Verificar dependências
check_dependencies() {
    local deps_missing=0
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_error "curl ou wget é necessário mas não está instalado"
        deps_missing=1
    fi
    
    if [ $deps_missing -eq 1 ]; then
        print_error "Por favor, instale as dependências necessárias"
        exit 1
    fi
}

# Baixar script
download_script() {
    print_info "Baixando script de instalação..."
    
    if command -v curl &> /dev/null; then
        curl -sSL "$SCRIPT_URL" -o "$TEMP_SCRIPT" || {
            print_error "Falha ao baixar script com curl"
            exit 1
        }
    elif command -v wget &> /dev/null; then
        wget -qO "$TEMP_SCRIPT" "$SCRIPT_URL" || {
            print_error "Falha ao baixar script com wget"
            exit 1
        }
    fi
    
    # Verificar se o download foi bem sucedido
    if [ ! -s "$TEMP_SCRIPT" ]; then
        print_error "Script baixado está vazio"
        exit 1
    fi
    
    # Tornar executável
    chmod +x "$TEMP_SCRIPT"
    print_info "Script baixado com sucesso"
}

# Função principal
main() {
    print_banner
    
    # Verificações
    check_root
    check_dependencies
    
    # Verificar parâmetros
    if [ $# -lt 2 ]; then
        print_error "Parâmetros insuficientes"
        echo ""
        echo "Uso: curl -sSL https://raw.githubusercontent.com/elvisfalmeida/zabbix-agent-install/main/install.sh | sudo bash -s -- IP_SERVIDOR HOSTNAME [ARQUITETURA]"
        echo ""
        echo "Exemplos:"
        echo "  # Instalação básica (detecta arquitetura automaticamente)"
        echo "  curl -sSL ... | sudo bash -s -- 192.168.1.100 webserver-01"
        echo ""
        echo "  # Forçar arquitetura i386"
        echo "  curl -sSL ... | sudo bash -s -- 192.168.1.100 legacy-server i386"
        echo ""
        exit 1
    fi
    
    # Capturar parâmetros
    ZABBIX_SERVER="$1"
    HOSTNAME="$2"
    ARCH="${3:-auto}"
    
    print_info "Configuração detectada:"
    echo "  - Servidor Zabbix: $ZABBIX_SERVER"
    echo "  - Hostname: $HOSTNAME"
    echo "  - Arquitetura: $ARCH"
    echo ""
    
    # Baixar script
    download_script
    
    # Executar script
    print_info "Iniciando instalação do Zabbix Agent..."
    echo ""
    
    # Passar todos os parâmetros para o script
    "$TEMP_SCRIPT" "$@"
    
    # O script de instalação já mostra o status final
}

# Executar
main "$@"
