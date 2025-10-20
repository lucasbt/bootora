#!/bin/bash
#
# Bootora - Fedora Post-Install Bootstrapper
# This script downloads and sets up the complete Fedora post-install system
# Usage: curl -fsSL https://raw.githubusercontent.com/lucasbt/bootora/main/boot.sh | bash
#

set -e

echo -e "\033[1;37m
██████╗  ██████╗  ██████╗ ████████╗ ██████╗ ██████╗  █████╗
██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗
██████╔╝██║   ██║██║   ██║   ██║   ██║   ██║██████╔╝███████║
██╔══██╗██║   ██║██║   ██║   ██║   ██║   ██║██╔══██╗██╔══██║
██████╔╝╚██████╔╝╚██████╔╝   ██║   ╚██████╔╝██║  ██║██║  ██║
╚═════╝  ╚═════╝  ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
\033[0m"

# Constants
readonly SCRIPT_NAME="bootora"
readonly REPO_URL="https://github.com/lucasbt/bootora.git"
readonly INSTALL_DIR="$HOME/.local/share/bootora"
readonly BIN_DIR="$HOME/.local/bin"
readonly MAIN_SCRIPT="$INSTALL_DIR/bootora"

# Colors
readonly RED='\033[1;91m'
readonly GREEN='\033[1;92m'
readonly YELLOW='\033[1;93m'
readonly BLUE='\033[1;94m'
readonly NC='\033[0m'

# Utility functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {

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


# Check if running on Fedora
check_system() {
    if ! command -v dnf &> /dev/null; then
        print_error "This script is designed for Fedora systems with DNF package manager"
        exit 1
    fi

    if [ ! -f /etc/fedora-release ]; then
        print_error "This script is designed for Fedora systems"
        exit 1
    fi

    print_status "Running on Fedora $(cat /etc/fedora-release)"
}

# Install essential dependencies
install_dependencies() {
    print_header "Installing Bootora Dependencies"

    # Check for sudo privileges
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
    else
        SUDO="sudo"
    fi

    print_status "Installing git and essential tools..."
    sudo dnf install -y git curl wget unzip jq

    print_status "Dependencies installed successfully"
}

# Create necessary directories
create_directories() {
    print_status "Creating installation directories..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"

    # Add ~/.local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_status "Adding $BIN_DIR to PATH..."

        # Add to .bashrc
        if [ -f "$HOME/.bashrc" ] && ! grep -q "$BIN_DIR" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Added by Bootora installer" >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi

        # Add to .zshrc if it exists
        if [ -f "$HOME/.zshrc" ] && ! grep -q "$BIN_DIR" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Added by Bootora installer" >> "$HOME/.zshrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        fi

        # Export for current session
        export PATH="$BIN_DIR:$PATH"

        print_warning "Added $BIN_DIR to PATH. Please restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc'"
    fi
}

# Clone or update repository
setup_repository() {
    print_header "Setting up Bootora Repository"

    if [ -d "$INSTALL_DIR/.git" ]; then
        print_status "Updating existing repository..."
        cd "$INSTALL_DIR"
        git config --global credential.helper 'cache --timeout=3600'
        git fetch --all
        git reset --hard origin/main
        git pull origin main
        cd -
    else
        print_status "Cloning repository..."
        rm -rf "$INSTALL_DIR"
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    # Make scripts executable
    find "$INSTALL_DIR" -name "*.sh" -exec chmod +x {} \;

    print_status "Repository setup completed"
}

# Create main executable
create_main_executable() {
    print_status "Creating main executable for system..."

    cat > "$BIN_DIR/bootora" << 'EOF'
#!/bin/bash
#
# Bootora - Main executable
# Fedora Post-Install System
#

BOOTORA_HOME_LINE='export BOOTORA_HOME="$HOME/.local/share/bootora"'

# Bash
if [ -f "$HOME/.bashrc" ] && ! grep -Fxq "$BOOTORA_HOME_LINE" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# Bootora environment variable" >> "$HOME/.bashrc"
    echo "$BOOTORA_HOME_LINE" >> "$HOME/.bashrc"
fi

# Zsh
if [ -f "$HOME/.zshrc" ] && ! grep -Fxq "$BOOTORA_HOME_LINE" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Bootora environment variable" >> "$HOME/.zshrc"
    echo "$BOOTORA_HOME_LINE" >> "$HOME/.zshrc"
fi

# Exporta para o shell atual
export BOOTORA_HOME="$HOME/.local/share/bootora"

if [ ! -d "$BOOTORA_HOME" ]; then
    echo "Error: Bootora not properly installed. Please run the bootstrap script again."
    exit 1
fi

# Execute the main script
exec "$BOOTORA_HOME/bootora" "$@"
EOF

    sudo chmod +x -R "$BIN_DIR/bootora"
    sudo chmod +x -R "$INSTALL_DIR/bootora"

    print_status "Main executable created at $BIN_DIR/bootora"
}

setup_autocomplete() {
    print_header "Setting up Autocomplete"

    # Diretórios de autocompletion
    local bash_completion_dir="$HOME/.bash_completion.d"
    local zsh_completion_dir="$HOME/.zsh/completions"

    mkdir -p "$bash_completion_dir"
    mkdir -p "$zsh_completion_dir"

    local bash_autocomplete="$bash_completion_dir/bootora"
    local zsh_autocomplete="$zsh_completion_dir/_bootora"

    # Script de autocomplete para Bash
    cat > "$bash_autocomplete" << 'EOF'
_bootora() {
    # Só funciona no bash
    if [ -z "$BASH_VERSION" ]; then
        return 1
    fi

    local cur prev

    # Tenta carregar bash-completion se necessário
    if ! type _init_completion &>/dev/null; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
        fi
    fi

    # Usa _init_completion se existir, senão pega cur e prev manualmente
    if type _init_completion &>/dev/null; then
        _init_completion || return
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
    fi

    local commands="install update module list status clean self-update help version"

    case "$prev" in
        module)
            local modules
            modules=$(bootora autocomplete_modules 2>/dev/null)
            COMPREPLY=( $(compgen -W "${modules}" -- "$cur") )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${commands}" -- "$cur") )
            return 0
            ;;
    esac
}
complete -F _bootora bootora
EOF

    # Script de autocomplete para Zsh (sem --plain)
    cat > "$zsh_autocomplete" << 'EOF'
#compdef bootora

_bootora() {
  local -a commands
  commands=(
    'install:Run full installation'
    'update:Update installed packages and tools'
    'module:Run specific module'
    'list:List available modules'
    'status:Show installation status'
    'clean:Clean cache and temporary files'
    'self-update:Update Bootora itself'
    'help:Show help'
    'version:Show version'
  )

  _arguments \
    '1:command:->cmds' \
    '2:module name:->modules'

  case $state in
    cmds)
      _describe 'command' commands
      ;;
    modules)
      if [[ $words[2] == module ]]; then
        local -a modules
        # Executa bootora autocomplete_modules e remove linhas vazias
        modules=("${(@f)$(bootora autocomplete_modules 2>/dev/null | grep -v '^\s*$')}")
        _values 'modules' $modules
      fi
      ;;
  esac
}

_bootora
EOF

    # Bash: adiciona ao .bashrc se ainda não estiver
    if [ -f "$HOME/.bashrc" ]; then
        local bash_line="[ -f \"$bash_autocomplete\" ] && . \"$bash_autocomplete\""
        if ! grep -Fxq "$bash_line" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Bootora autocomplete" >> "$HOME/.bashrc"
            echo "if [ -n \"\$BASH_VERSION\" ]; then" >> "$HOME/.bashrc"
            echo "  $bash_line" >> "$HOME/.bashrc"
            echo "fi" >> "$HOME/.bashrc"
        fi
    fi

    # Zsh: adiciona ao .zshrc se ainda não estiver
    if [ -f "$HOME/.zshrc" ]; then
        local zsh_completion_dir=~/.zsh/completions
        local zsh_line="fpath=($zsh_completion_dir \$fpath)"
        if ! grep -Fxq "$zsh_line" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Bootora autocomplete" >> "$HOME/.zshrc"
            echo "$zsh_line" >> "$HOME/.zshrc"
            echo "autoload -Uz compinit && compinit" >> "$HOME/.zshrc"
        fi
    fi

    print_status "Autocomplete installed for Bash and Zsh"
    print_warning "To enable autocomplete, restart your terminal or run: source ~/.bashrc ou source ~/.zshrc"
}

# Main bootstrap function
main() {
    print_header "Bootora Bootstrap"
    print_status "Setting up Fedora post-install system..."

    check_system
    install_dependencies
    create_directories
    setup_repository
    create_main_executable
    setup_autocomplete

    print_header "Bootstrap Complete!"
    print_status "Bootora has been installed successfully!"
    print_status "Run 'bootora --help' to see available options"
    print_status "Run 'bootora install' to start the full installation"

    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_warning "Please restart your terminal or run 'source ~/.bashrc' to use the 'bootora' command"
    fi
}

# Run main function
main "$@"
