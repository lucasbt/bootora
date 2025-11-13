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
readonly GNOME_STATE_FILE="$BOOTORA_CACHE/gnome_state.conf"

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
    echo -e "${BLUE}[INFO] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[${CHECKMARK}] $1${NC}"
}

log_failed() {
    echo -e "${RED}[${CROSS}] $1${NC}"
}

log_header() {

    local text="$1"

    # Detecta largura do terminal ou usa 60 como padrão
    local width=60
    if command -v tput >/dev/null 2>&1; then
        width=$(tput cols 2>/dev/null || echo 60)
    fi

    [[ "$width" -lt 20 ]] && width=60

    local border=$(printf '=%.0s' $(seq 1 "$width"))

    # Limpa texto e limita comprimento
    local clean_text=$(echo "$text" | tr -d '\n' | cut -c1-$((width - 4)))

    # Centraliza o texto
    local padding=$(( (width - 2 - ${#clean_text}) / 2 ))
    local left_pad=$(printf ' %.0s' $(seq 1 $padding))
    local right_pad=$(printf ' %.0s' $(seq 1 $((width - 2 - padding - ${#clean_text}))) )

    echo
    echo -e "${PURPLE}${border}${NC}"
    echo -e "${PURPLE}|${left_pad}${clean_text}${right_pad}|${NC}"
    echo -e "${PURPLE}${border}${NC}"
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
    if flatpak install --or-update --assumeyes --noninteractive flathub "$package"; then
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
        read -e -p "$(echo -e "${PURPLE}${ARROW_R} ${question} ${prompt}: ${NC}")" -n 1 -r
        #read -e -p "$(printf "${PURPLE}${ARROW_R} %s %s: ${NC}" "$question" "$prompt")" -n 1 -r

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

# ============================================
# Função: inibe temporariamente bloqueio de tela e suspensão (GNOME)
# ============================================
inhibit_blockage_gnome() {

    # --- Se houver estado pendente, não mexe e avisa ---
    if [ -f "$GNOME_STATE_FILE" ]; then
        log_warning "Detected GNOME state pending restoration — will not be modified in this run."
        return
    fi

    # --- Desativa temporariamente se GNOME estiver ativo ---
    if pgrep -x gnome-shell >/dev/null 2>&1; then
        log_info "GNOME session detected — temporarily disabling screen lock and sleep..."

        OLD_IDLE_DELAY=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null || echo "300")
        OLD_LOCK_ENABLED=$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null || echo "true")
        OLD_SLEEP_BATTERY=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 2>/dev/null || echo "'suspend'")
        OLD_SLEEP_AC=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || echo "'suspend'")

        # --- Salva no cache para restauração futura ---
        {
            echo "OLD_IDLE_DELAY=\"$OLD_IDLE_DELAY\""
            echo "OLD_LOCK_ENABLED=\"$OLD_LOCK_ENABLED\""
            echo "OLD_SLEEP_BATTERY=\"$OLD_SLEEP_BATTERY\""
            echo "OLD_SLEEP_AC=\"$OLD_SLEEP_AC\""
        } > "$GNOME_STATE_FILE"

        # --- Desativa bloqueio e suspensão temporariamente ---
        gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null && \
            log_success "Automatic sleep temporarily disabled." || \
            log_warning "Failed to disable idle-delay"

        gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null && \
            log_success "Screen lock temporarily disabled." || \
            log_warning "Failed to disable screen lock"

        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' 2>/dev/null && \
            log_success "Sleep on battery temporarily disabled." || \
            log_warning "Failed to disable sleep on battery"

        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null && \
            log_success "Sleep on AC power temporarily disabled." || \
            log_warning "Failed to disable sleep on AC power"
    else
        log_info "GNOME session not detected — running without changing screen lock."
    fi
}

# ============================================
# Função: restaura configuração original do GNOME
# ============================================
restaurar_gnome_config() {
    if [ ! -f "$GNOME_STATE_FILE" ]; then
        log_warning "No GNOME state file found — nothing to restore."
        return
    fi

    log_info "Restoring original screen lock and sleep settings..."
    source "$GNOME_STATE_FILE"

    gsettings set org.gnome.desktop.session idle-delay "$OLD_IDLE_DELAY" 2>/dev/null && \
        log_success "Inactivity time restored to $OLD_IDLE_DELAY" || \
        log_warning "Failed to restore idle-delay"

    gsettings set org.gnome.desktop.screensaver lock-enabled "$OLD_LOCK_ENABLED" 2>/dev/null && \
        log_success "Screen lock restored to $OLD_LOCK_ENABLED" || \
        log_warning "Failed to restore screen lock."

    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "$OLD_SLEEP_BATTERY" 2>/dev/null && \
        log_success "Battery sleep mode restored to $OLD_SLEEP_BATTERY" || \
        log_warning "Failed to restore battery sleep type."

    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "$OLD_SLEEP_AC" 2>/dev/null && \
        log_success "AC sleep mode restored to $OLD_SLEEP_AC" || \
        log_warning "Failed to restore AC sleep type."

    rm -f "$GNOME_STATE_FILE" 2>/dev/null || true
    log_info "Original GNOME screen lock and sleep settings restored."
}


# --- Função de cleanup segura ---
bootora_cleanup() {
    # Desativa trap temporariamente para evitar loop
    trap - EXIT SIGINT SIGTERM ERR

    log_info "Performing cleanup..."

    # Restaura GNOME apenas se o arquivo existir
    if [ -f "$GNOME_STATE_FILE" ]; then
        restaurar_gnome_config
    fi

    # Remove arquivos temporários
    cleanup_temp_files
}

# Initialize bootora environment
init_bootora_env() {
    # --- Configura modo seguro de execução ---
    # -e: sai no primeiro erro
    # -o pipefail: falha se qualquer comando do pipe falhar
    # -E: garante que trap ERR seja propagado para funções e subshells
    set -eEo pipefail

    check_sudo
    ensure_directory "$BOOTORA_CACHE"
    ensure_directory "$BOOTORA_CONFIG"
    set_error_trap

    # Cria diretório temporário
    export TEMP_DIR=$(mktemp -d)

    # --- Traps ---
    # Saída normal ou erro: cleanup
    trap 'bootora_cleanup' EXIT

    # Interrupção (Ctrl+C, SIGTERM): cleanup e sai imediatamente
    trap 'log_warning "Execution interrupted! Exiting immediately."; bootora_cleanup; exit 1' SIGINT SIGTERM

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
    if [ "$fedora_version" -lt 43 ]; then
        log_warning "This tool is tested on Fedora 43+. Your version: $fedora_version"
    fi
}

spinner_run() {
    if [ $# -lt 2 ]; then
        log_failed "Uso: spinner_run <mensagem> <comando>"
        return 1
    fi

    local msg="$1"
    shift
    local cmd_str="$*"
    local tmpfile
    tmpfile=$(mktemp)
    local exit_code
    local delay=0.1
    local spinner=('|' '/' '-' '\')
    local i=0
    local clear_line='\r\033[K'
    local hide_cursor='\033[?25l'
    local show_cursor='\033[?25h'

    printf "%b" "$hide_cursor"

    bash -c "$cmd_str" >"$tmpfile" 2>&1 &
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        printf "${clear_line}%s %s" "$msg" "${spinner[i]}"
        sleep "$delay"
        ((i=(i+1)%4))
    done

    wait "$pid"
    exit_code=$?

    printf "%b" "$clear_line$show_cursor"

    if [ "$exit_code" -eq 0 ]; then
        log_success "$msg concluído com sucesso!"
    else
        log_failed "$msg falhou!"
        echo "" 
        cat "$tmpfile"
        echo "" 
    fi

    rm -f "$tmpfile"
    return "$exit_code"
}

# Export all functions for use in other scripts
export -f log_info log_warning log_error log_success log_failed spinner_run
export -f log_header log_subheader show_progress
export -f get_system_info get_fedora_version check_sudo superuser_do
export -f is_package_installed is_flatpak_installed is_command_available
export -f install_dnf_package install_flatpak_package
export -f backup_file ensure_directory add_to_path add_environment_variable
export -f download_file enable_service start_service
export -f ask_yes_no ask_input handle_error set_error_trap
export -f cleanup_temp_files version_gt version_ge
export -f init_bootora_env check_environment
