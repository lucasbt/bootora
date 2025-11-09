#!/bin/bash
#
# Bootora Utility Functions
# Common functions and constants used across all scripts
#

# Constants
readonly BOOTORA_VERSION="1.0.0"
readonly BOOTORA_HOME="$HOME/.local/share/bootora"
readonly BOOTORA_CACHE="$HOME/.cache/bootora"
readonly BOOTORA_CONFIG="$HOME/.config/bootora"

# Colors
readonly RED="\033[1;91m"        # Red
readonly GREEN="\033[1;92m"      # Green
readonly YELLOW="\033[1;93m"     # Yellow
readonly BLUE="\033[1;94m"       # Blue
readonly PURPLE="\033[1;95m"     # Purple
readonly CYAN="\033[1;96m"       # Cyan
readonly WHITE="\033[1;97m"      # White
readonly GRAY="\033[1;37m"       # Gray
readonly NC='\033[0m'

# Icons/Symbols
readonly CHECKMARK="✓"
readonly CROSS="✗"
readonly ARROW_R="→"
readonly STAR="★"

# Número máximo de tentativas sudo permitidas
readonly MAX_SUDO_ATTEMPTS=1

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[${CHECKMARK}]${NC} $1"
}

log_failed() {
    echo -e "${RED}[${CROSS}]${NC} $1"
}

log_header() {

    local text="$1"

    # Detecta largura do terminal ou usa 80 como padrão
    local width
    #width=$(tput cols 2>/dev/null)
    [[ -z "$width" || "$width" -lt 20 ]] && width=60

    local border=$(printf '=%.0s' $(seq 1 "$width"))

    # Limpa texto e limita comprimento
    local clean_text=$(echo "$text" | tr -d '\n' | cut -c1-$((width - 4)))

    # Centraliza o texto
    local padding=$(( (width - 2 - ${#clean_text}) / 2 ))
    local left_pad=$(printf ' %.0s' $(seq 1 $padding))
    local right_pad=$(printf ' %.0s' $(seq 1 $((width - 2 - padding - ${#clean_text}))) )

    echo
    echo -e "${BLUE}${border}${NC}"
    echo -e "${BLUE}|${left_pad}${clean_text}${right_pad}|${NC}"
    echo -e "${BLUE}${border}${NC}"
    echo
}

log_subheader() {
    echo -e "${CYAN}${ARROW_R} $1${NC}"
}

# Progress indicator (contagem simples)
show_progress() {
    local current=${1:-0}
    local total=${2:-1}
    local description=${3:-}

    # validações / normalizações
    if [ "$total" -le 0 ]; then total=1; fi
    if [ "$current" -lt 0 ]; then current=0; fi
    if [ "$current" -gt "$total" ]; then current=$total; fi

    local remaining=$(( total - current ))

    # cores (fallback caso não estejam definidas)
    : "${GREEN:=$'\e[32m'}"
    : "${YELLOW:=$'\e[33m'}"
    : "${NC:=$'\e[0m'}"

    # limpa a linha atual desde o cursor até o fim
    printf "\r\033[K"

    # proposta visual:
    # [Step 2/5] description... (3 remaining)
    printf "%b[Step %d/%d]%b %s %b(%d remaining)%b " \
        "$PURPLE" "$current" "$total" "$NC" \
        "$description" \
        "$YELLOW" "$remaining" "$NC"

    if [ "$current" -ge "$total" ]; then
        printf "\n"
    fi
}

# System detection
get_system_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME $VERSION"
    else
        echo "Unknown Linux"
    fi
}

get_fedora_version() {
    if [ -f /etc/fedora-release ]; then
        cat /etc/fedora-release | grep -oP '\d+' | head -1
    else
        echo "unknown"
    fi
}

# Privilege checking
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        export SUDO=""
        export USER_HOME="/root"
        export CURRENT_USER="root"
    else
        export SUDO="sudo"
        export USER_HOME="$HOME"
        export CURRENT_USER="$USER"
    fi
}

function superuser_do() {
	# check if current user is root
	if [[ $EUID = 0 ]]; then
		# Running command without sudo
		$@
	else
        request_sudo_password
        sudo $@
	fi
}

function check_sudo_password() {
    # Verifica se o usuário atual é root
    if [[ $EUID = 0 ]]; then
        return 0  # Retorna 0 para indicar que a senha sudo não é necessária
    else
        # Verifica se a senha sudo já foi fornecida recentemente
        sudo -nv &> /dev/null
        # Retorna o código de saída do comando sudo
        return $?
    fi
}

function request_sudo_password() {
    # Se a senha sudo não foi fornecida recentemente, solicita a senha
    if ! check_sudo_password; then
        log_warning 'Admin privileges required! Please enter your password.'

        ATTEMPT=0
        while [ $ATTEMPT -lt $MAX_SUDO_ATTEMPTS ]; do
            # Solicita a senha sudo
            sudo -v
            # Verifica o código de saída do comando sudo
            if [ $? -eq 0 ]; then
                # Senha correta, sai do loop
                break
            else
                # Senha incorreta, incrementa a contagem de tentativas
                let ATTEMPT=ATTEMPT+1

                if [ $ATTEMPT -eq $MAX_SUDO_ATTEMPTS ]; then
                    # Número máximo de tentativas atingido, exibe mensagem de erro e sai do script
                    log_error "Maximum number of password attempts reached. Aborting execution..."
                    exit 1
                else
                    # Mensagem de aviso para tentativas adicionais
                    log_warning "Incorrect password. Attempted $ATTEMPT from $MAX_SUDO_ATTEMPTS. Please try again."
                fi
            fi
        done
    fi
}


# Package management utilities
is_package_installed() {
    local package="$1"
    rpm -q "$package" &> /dev/null
}

is_flatpak_installed() {
    local package="$1"
    flatpak list | grep -q "$package"
}

is_command_available() {
    command -v "$1" &> /dev/null
}

# Installation helpers
install_dnf_package() {
    local package="$1"
    local description="${2:-$package}"

    if is_package_installed "$package"; then
        log_info "$description already installed"
        return 0
    fi

    log_info "Installing $description..."
    if superuser_do dnf install -y --best --allowerasing --skip-broken "$package"; then
        log_success "$description installed successfully"
        return 0
    else
        log_failed "Failed to install $description"
        return 1
    fi
}

install_flatpak_package() {
    local package="$1"
    local description="${2:-$package}"

    if is_flatpak_installed "$package"; then
        log_info "$description already installed"
        return 0
    fi

    log_info "Installing $description..."
    if flatpak install --or-update --assumeyes flathub "$package"; then
        log_success "$description installed successfully"
        return 0
    else
        log_failed "Failed to install $description"
        return 1
    fi
}

# File operations
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up $file"
    fi
}

ensure_directory() {
    local dir="$1"
    [ -n "$dir" ] || return 1

    # Expande ~ para $HOME
    dir="${dir/#\~/$HOME}"

    # Já existe? Nada a fazer
    [ -d "$dir" ] && return 0

    # Se o diretório estiver dentro do $HOME, cria sem sudo
    if [[ "$dir" == "$HOME"* ]]; then
        mkdir -p -- "$dir"
        log_info "Created directory: $dir"
        return 0
    fi

    # Caso contrário, verifica se o diretório pai é gravável
    local parent="$dir"
    while [ ! -e "$parent" ] && [ "$parent" != "/" ]; do
        parent=$(dirname "$parent")
    done

    if [ -w "$parent" ]; then
        mkdir -p -- "$dir"
        log_info "Created directory: $dir"
    else
        superuser_do mkdir -p -- "$dir"
        log_info "Created directory: $dir"
    fi
}

# Configuration helpers
add_to_path() {
    local new_path="$1"
    local shell_file="$2"

    if [ -f "$shell_file" ] && ! grep -q "$new_path" "$shell_file"; then
        echo "" >> "$shell_file"
        echo "# Added by Bootora" >> "$shell_file"
        echo "export PATH=\"$new_path:\$PATH\"" >> "$shell_file"
        log_info "Added $new_path to PATH in $shell_file"
    fi
}

add_environment_variable() {
    local var_name="$1"
    local var_value="$2"
    local shell_file="$3"

    if [ -f "$shell_file" ] && ! grep -q "$var_name" "$shell_file"; then
        echo "" >> "$shell_file"
        echo "# Added by Bootora" >> "$shell_file"
        echo "export $var_name=\"$var_value\"" >> "$shell_file"
        log_info "Added $var_name to $shell_file"
    fi
}

# Network utilities
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"

    log_info "Downloading $description..."
    if curl -fsSL "$url" -o "$output"; then
        log_success "$description downloaded successfully"
        return 0
    else
        log_failed "Failed to download $description"
        return 1
    fi
}

# Service management
enable_service() {
    local service="$1"
    local description="${2:-$service}"

    log_info "Enabling $description service..."
    if superuser_do systemctl enable "$service"; then
        log_success "$description service enabled"
        return 0
    else
        log_failed "Failed to enable $description service"
        return 1
    fi
}

start_service() {
    local service="$1"
    local description="${2:-$service}"

    log_info "Starting $description service..."
    if superuser_do systemctl start "$service"; then
        log_success "$description service started"
        return 0
    else
        log_failed "Failed to start $description service"
        return 1
    fi
}

# User interaction
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"

    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi

    while true; do
        read -e -p "$(printf "${PURPLE}${ARROW_R} %s %s: ${NC}" "$question" "$prompt")" -n 1 -r

        case $REPLY in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" )
                if [ "$default" = "y" ]; then
                    return 0
                else
                    return 1
                fi
                ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

ask_input() {
    local question="$1"
    local default="$2"
    local response

    if [ -n "$default" ]; then
        read -p "$(printf "${YELLOW}${ARROW_R} %s [%s]: ${NC}" "$question" "$default")" response
        #read -p "$question [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$question: " response
        echo "$response"
    fi
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1

    log_error "An error occurred on line $line_number. Exit code: $exit_code"
    exit $exit_code
}

# Set error trap
set_error_trap() {
    trap 'handle_error $LINENO' ERR
}

# Cleanup function
cleanup_temp_files() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned up temporary files"
    fi
}

# Version comparison
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

version_ge() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" = "$2"
}

# Initialize bootora environment
init_bootora_env() {
    check_sudo
    ensure_directory "$BOOTORA_CACHE"
    ensure_directory "$BOOTORA_CONFIG"
    set_error_trap

    # Create temp directory
    export TEMP_DIR=$(mktemp -d)
    trap cleanup_temp_files EXIT

    log_info "Bootora environment initialized"
}

# Check if running in supported environment
check_environment() {
    if ! command -v dnf &> /dev/null; then
        log_error "DNF package manager not found. This tool is designed for Fedora."
        exit 1
    fi

    if [ ! -f /etc/fedora-release ]; then
        log_error "This tool is designed for Fedora systems."
        exit 1
    fi

    local fedora_version=$(get_fedora_version)
    if [ "$fedora_version" -lt 35 ]; then
        log_warning "This tool is tested on Fedora 35+. Your version: $fedora_version"
    fi
}

# Export all functions for use in other scripts
export -f log_info log_warning log_error log_success log_failed
export -f log_header log_subheader show_progress
export -f get_system_info get_fedora_version check_sudo superuser_do
export -f is_package_installed is_flatpak_installed is_command_available
export -f install_dnf_package install_flatpak_package
export -f backup_file ensure_directory add_to_path add_environment_variable
export -f download_file enable_service start_service
export -f ask_yes_no ask_input handle_error set_error_trap
export -f cleanup_temp_files version_gt version_ge
export -f init_bootora_env check_environment
