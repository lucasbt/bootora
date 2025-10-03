#!/bin/bash
#
# Configuration Module - System Configuration & Tweaks
# Applies system configurations and user customizations
#

# Execute configuration module
execute_configuration_module() {
    log_subheader "System Configuration & Tweaks"

    # Configure Git
    configure_git_settings

    # Configure shell environment
    configure_shell_environment

    # Configure system services
    configure_system_services

    # Apply system tweaks
    apply_system_tweaks

    # Configure development environment
    configure_folders_development_environment

    # Setup useful aliases and functions
    setup_shell_enhancements

    configure_environment_apps

    log_success "Configuration module completed successfully"
    return 0
}

# Configure Git settings
configure_git_settings() {
    log_info "Configuring Git settings..."

    # Check if Git is already configured
    if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
        log_info "Git already configured"
        local current_name=$(git config --global user.name)
        local current_email=$(git config --global user.email)
        log_info "Current Git user: $current_name <$current_email>"
    else
        log_info "Git not configured, prompting for user information..."

        # Get user information
        local git_name=$(ask_input "Enter your Git username" "")
        local git_email=$(ask_input "Enter your Git email" "")

        if [ -n "$git_name" ] && [ -n "$git_email" ]; then
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            log_success "Git user configured: $git_name <$git_email>"
        else
            log_warning "Git user configuration skipped"
        fi
    fi

    # Set useful Git configurations
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor nano
    git config --global color.ui auto
    git config --global push.default simple

    log_success "Git configuration completed"
}

enable_nano_syntax_highlighting() {
    log_info "Enabling nano syntax highlighting..."

    local nanorc_file="$HOME/.nanorc"
    local include_line="include /usr/share/nano/*"

    # Check if the include line is already present
    if grep -Fxq "$include_line" "$nanorc_file" 2>/dev/null; then
        log_info "Syntax highlighting already enabled in $nanorc_file"
        return 0
    fi

    # Add the include line with a comment
    {
        echo ""
        echo "# Enable syntax highlighting for all filetypes"
        echo "$include_line"
    } >> "$nanorc_file"

    log_success "Nano syntax highlighting enabled in $nanorc_file"
}


# Configure shell environment
configure_shell_environment() {
    log_info "Configuring shell environment..."

    # Configure Bash
    configure_bash

    # Configure Zsh if installed
    if is_command_available "zsh"; then
        configure_zsh
    fi

    # Install and configure useful shell tools
    install_shell_tools

    log_success "Shell environment configured"
}

# Configure Bash
configure_bash() {
    log_info "Configuring Bash..."

    local bashrc="$HOME/.bashrc"

    # Backup existing bashrc
    backup_file "$bashrc"

    # Add useful Bash configurations
    if ! grep -q "# Bootora configurations" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Bootora configurations
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:ls *:cd:cd -:pwd:exit:date:* --help"
shopt -s histappend
shopt -s checkwinsize
shopt -s autocd
shopt -s cdspell
# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Better tab completion
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'

# Improved prompt
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# Load custom aliases if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Load custom functions if they exist
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi
EOF
        log_success "Bash configuration added"
    else
        log_info "Bash already configured by Bootora"
    fi
}

# Configure Zsh
configure_zsh() {
    log_info "Configuring Zsh with Starship..."

    local zshrc="$HOME/.zshrc"

    # Ensure Zsh is installed
    if ! command -v zsh &>/dev/null; then
        log_failed "Zsh is not installed. Aborting."
        return 1
    fi

    # Install Starship prompt
    if ! command -v starship &>/dev/null; then
        log_info "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | bash -s -- -y
        log_success "Starship installed"
    else
        log_info "Starship already installed"
    fi

    # Install Zsh plugins
    install_zsh_plugins

    # Configure .zshrc
    log_info "Setting up ~/.zshrc..."

    cat > "$zshrc" << 'EOF'
# ============================
# Zsh Optimized Configuration
# ============================

# disable CTRL + S and CTRL + Q
stty -ixon

# Key bindings for navigation and history search

# navigate words using Ctrl + arrow keys
# >>> CRTL + right arrow | CRTL + left arrow
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# search history using Up and Down keys
# >>> up arrow | down arrow
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# jump to the start and end of the command line
# >>> CTRL + A | CTRL + E
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

# >>> Home | End
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# delete characters using the "delete" key
bindkey "^[[3~" delete-char

# fzf alias: CTRL + SPACE (gadget parameters configured in the FZF_CTRL_T_COMMAND environment variable)
bindkey "^@" fzf-file-widget

# =========================
# History settings
# =========================
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST="$HISTSIZE"
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
# save each command to the history file as soon as it is executed
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
# append new history entries to the history file
setopt APPEND_HISTORY
# ignore commands that start with a space in the history
setopt HIST_IGNORE_SPACE
# enable comments "#" expressions in the prompt shell
setopt INTERACTIVE_COMMENTS
setopt AUTO_CD
setopt CORRECT

# =========================
# Load aliases and functions
# =========================
[ -f ~/.bash_aliases ] && source ~/.bash_aliases
[ -f ~/.bash_functions ] && source ~/.bash_functions
[ -f ~/.dev_aliases ] && source ~/.dev_aliases

# =========================
# Plugins
# =========================
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fpath+=(~/.zsh/plugins/zsh-completions/src)

# load fzf keybindings and completions
eval "$(fzf --zsh)"

# =========================
# Starship prompt lazy init
# =========================
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi
EOF

    log_success "Zsh configured with Starship and plugins"

    # Ask to set Zsh as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        if ask_yes_no "Set Zsh as your default shell?" "n"; then
            chsh -s "$(which zsh)"
            log_success "Zsh set as default shell (effective after logout/login)"
        fi
    fi
}

install_zsh_plugins() {
    local plugin_dir="$HOME/.zsh/plugins"
    mkdir -p "$plugin_dir"

    # zsh-autosuggestions
    if [ ! -d "$plugin_dir/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$plugin_dir/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    fi

    # zsh-completions
    if [ ! -d "$plugin_dir/zsh-completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions "$plugin_dir/zsh-completions"
        log_success "zsh-completions installed"
    fi
}


# Install shell tools
install_shell_tools() {
    log_info "Installing shell enhancement tools..."

    # Tools already covered in base packages, just ensure they're configured
    local shell_tools=(
        "fzf"
        "bat"
        "fd-find"
        "ripgrep"
        "htop"
        "tree"
    )

    for tool in "${shell_tools[@]}"; do
        if ! is_package_installed "$tool"; then
            install_dnf_package "$tool" "$tool"
        fi
    done

    # Configure fzf if installed
    if is_command_available "fzf"; then
        configure_fzf
    fi
}

# Configure fzf
configure_fzf() {
    log_info "Configuring fzf..."

    # Add fzf key bindings and completion
    local fzf_config="# fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND=\"\$FZF_DEFAULT_COMMAND\"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# fzf key bindings
source /usr/share/fzf/shell/key-bindings.bash 2>/dev/null || true"

    # Add to bashrc
    if [ -f "$HOME/.bashrc" ] && ! grep -q "fzf configuration" "$HOME/.bashrc"; then
        echo "$fzf_config" >> "$HOME/.bashrc"
    fi

    # Add to zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -q "fzf configuration" "$HOME/.zshrc"; then
        echo "$fzf_config" >> "$HOME/.zshrc"
        echo "source /usr/share/fzf/shell/key-bindings.zsh 2>/dev/null || true" >> "$HOME/.zshrc"
    fi

    log_success "fzf configured"
}

# Configure system services
configure_system_services() {
    log_info "Configuring system services..."

    # Configure SSH if installed
    if is_command_available "ssh"; then
        configure_ssh
    fi

    # Configure automatic updates (optional)
    configure_automatic_updates

    log_success "System services configured"
}

configure_ssh() {
    log_info "Configuring SSH and enabling persistent ssh-agent..."

    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_ed25519"
    local ssh_config_file="$ssh_dir/config"
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    local ssh_env_file="$ssh_dir/agent.env"

    # Create .ssh directory with correct permissions
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Generate SSH key if it doesn't exist
    if [[ ! -f "$ssh_key" ]]; then
        log_info "Generating new SSH key (ed25519)..."
        local ssh_email=$(ask_input "Enter your principal email for namming key" "")
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_key" -N ""
        log_success "SSH key generated: $ssh_key"
    else
        log_info "SSH key already exists: $ssh_key"
    fi

    # Create SSH config file if not exists
    if [[ ! -f "$ssh_config_file" ]]; then
        cat > "$ssh_config_file" <<EOF
Host *
  AddKeysToAgent yes
  IdentityFile $ssh_key
EOF
        chmod 600 "$ssh_config_file"
        log_success "Created SSH config at $ssh_config_file"
    fi

    log_success "SSH agent configured with support for bash, zsh, and tmux"
}

# Configure automatic updates
configure_automatic_updates() {
    log_info "Configuring automatic security updates..."
    if ask_yes_no "Enable automatic security updates?" "y"; then
        install_dnf_package "dnf-automatic" "DNF Automatic"

        # Configure dnf-automatic
        local auto_config="/etc/dnf/automatic.conf"
        if [ -n "$auto_config" ]; then
            if grep -q "apply_updates" "$auto_config"; then
                sudo sed -i 's/^\s*#\?\s*apply_updates\s*=.*/apply_updates = yes/' "$auto_config"
            else
                echo "apply_updates = yes" | superuser_do tee -a "$auto_config" >/dev/null
            fi

            if grep -q "upgrade_type" "$auto_config"; then
                sudo sed -i 's/^\s*#\?\s*upgrade_type\s*=.*/upgrade_type = security/' "$auto_config"
            else
                echo "upgrade_type = security" | superuser_do tee -a "$auto_config" >/dev/null
            fi

            enable_service "dnf-automatic.timer" "Automatic Updates"
            start_service "dnf-automatic.timer" "Automatic Updates"

            log_success "Automatic security updates enabled"
        fi
    fi
}

# Apply system tweaks
apply_system_tweaks() {
    log_info "Applying system tweaks..."

    # Improve swappiness
    apply_swappiness_tweak

    # Configure systemd journal
    configure_systemd_journal

    # Apply filesystem tweaks
    apply_filesystem_tweaks

    log_success "System tweaks applied"
}

# Apply swappiness tweak
apply_swappiness_tweak() {
    local sysctl_conf="/etc/sysctl.d/99-bootora.conf"

    if [ ! -f "$sysctl_conf" ]; then
        cat << 'EOF' | superuser_do tee "$sysctl_conf" > /dev/null
# Bootora system tweaks
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
        log_success "System performance tweaks applied"
    fi
}

# Configure systemd journal
configure_systemd_journal() {
    local journal_conf="/etc/systemd/journald.conf.d/bootora.conf"

    ensure_directory "$(dirname "$journal_conf")"

    if [ ! -f "$journal_conf" ]; then
        cat << 'EOF' | superuser_do tee "$journal_conf" > /dev/null
[Journal]
SystemMaxUse=500M
SystemMaxFiles=10
MaxRetentionSec=1month
EOF
        log_success "Systemd journal configured"
    fi
}

# Apply filesystem tweaks
apply_filesystem_tweaks() {
    # Enable TRIM for SSDs
    if superuser_do fstrim -v / &>/dev/null; then
        enable_service "fstrim.timer" "TRIM Timer"
        log_success "SSD TRIM enabled"
    fi
}

# Configure development environment
configure_folders_development_environment() {
    log_info "Configuring development and folders environment..."

    # Create common development directories
    ensure_directory "$HOME/Develop"
    ensure_directory "$HOME/Develop/personal"
    ensure_directory "$HOME/Develop/work"
    ensure_directory "$HOME/Develop/tools"
    ensure_directory "$HOME/Documents/projects"
    ensure_directory "$HOME/Documents/resources"
    ensure_directory "$HOME/Documents/resources/pictures"
    ensure_directory "$HOME/Documents/resources/pictures/wallpapers"
    ensure_directory "$HOME/Documents/resources/music"
    ensure_directory "$HOME/Documents/resources/videos"
    ensure_directory "$HOME/Documents/archives"
    ensure_directory "$HOME/Documents/areas"
    ensure_directory "$HOME/.local/bin"

    cp -r "$HOME/Pictures/"* "$HOME/Documents/resources/pictures/" 2>/dev/null || true
    rm -rf "$HOME/Pictures" && ln -s "$HOME/Documents/resources/pictures" "$HOME/Pictures"

    log_success "Development and folders environment configured"
}

# Setup shell enhancements
setup_shell_enhancements() {
    log_info "Setting up shell enhancements..."

    enable_nano_syntax_highlighting

    # Configure shell completion
    configure_shell_completion

    # Set up directory bookmarks
    setup_directory_bookmarks

    log_success "Shell enhancements configured"
}

# Configure shell completion
configure_shell_completion() {
    log_info "Configuring shell completion..."

    # Enable bash completion
    if [ -f /etc/bash_completion ] && [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "/etc/bash_completion" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Enable bash completion" >> "$HOME/.bashrc"
            echo "[ -f /etc/bash_completion ] && source /etc/bash_completion" >> "$HOME/.bashrc"
        fi
    fi

    # Install additional completions
    install_dnf_package "bash-completion" "Bash Completion" || true

    log_success "Shell completion configured"
}

# Setup directory bookmarks
setup_directory_bookmarks() {
    local bookmarks_file="$HOME/.bookmarks"

    if [ ! -f "$bookmarks_file" ]; then
        cat > "$bookmarks_file" << EOF
# Directory bookmarks
home=$HOME
projects=$HOME/Documents/projects
dev=$HOME/Develop
downloads=$HOME/Downloads
documents=$HOME/Documents
config=$HOME/.config
local=$HOME/.local
resources=$HOME/Documents/resources
archive=$HOME/Documents/archives
EOF

        # Add bookmark functions to shell functions
        cat >> "$HOME/.bash_functions" << 'EOF'

# Bookmark functions
go() {
    local bookmark=$(grep "^$1=" ~/.bookmarks 2>/dev/null | cut -d'=' -f2)
    if [ -n "$bookmark" ]; then
        cd "$bookmark"
    else
        echo "Bookmark '$1' not found"
        echo "Available bookmarks:"
        cat ~/.bookmarks | grep -v '^#' | cut -d'=' -f1
    fi
}

bookmark() {
    if [ -z "$1" ]; then
        echo "Usage: bookmark <name>"
        return 1
    fi
    echo "$1=$(pwd)" >> ~/.bookmarks
    echo "Bookmarked $(pwd) as '$1'"
}

bookmarks() {
    echo "Available bookmarks:"
    cat ~/.bookmarks | grep -v '^#' | while IFS='=' read -r name path; do
        printf "  %-15s %s\n" "$name" "$path"
    done
}
EOF

        log_success "Directory bookmarks configured"
    else
        log_info "Directory bookmarks already configured"
    fi
}

function configure_environment_apps(){
    configure_ulauncher
}

# Configure Ulauncher
configure_ulauncher() {
    log_info "Configuring Ulauncher..."

    # Instala o pacote caso não exista
    install_dnf_package "ulauncher" "Ulauncher" || true

    # Diretórios de configuração
    CONFIG_DIR="$HOME/.config/ulauncher"
    AUTOSTART_DIR="$HOME/.config/autostart"
    APPLICATIONS_DIR="$HOME/.local/share/applications"

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$AUTOSTART_DIR"
    mkdir -p "$APPLICATIONS_DIR"

    # Cria ulauncher.json
    cat > "$CONFIG_DIR/settings.json" << 'EOF'
{
  "blacklisted-desktop-dirs": "/usr/share/locale:/usr/share/app-install:/usr/share/kservices5:/usr/share/fk5:/usr/share/kservicetypes5:/usr/share/applications/screensavers:/usr/share/kde4:/usr/share/mimelnk",
  "clear-previous-query": true,
  "disable-desktop-filters": false,
  "grab-mouse-pointer": false,
  "hotkey-show-app": "null",
  "render-on-screen": "mouse-pointer-monitor",
  "show-indicator-icon": false,
  "show-recent-apps": "0",
  "terminal-command": "",
  "theme-name": "dark"
}
EOF

    # Conteúdo do .desktop
    DESKTOP_ENTRY='[Desktop Entry]
Name=Ulauncher
Comment=Application launcher for Linux
GenericName=Launcher
Categories=GNOME;GTK;Utility;
TryExec=/usr/bin/ulauncher
Exec=env GDK_BACKEND=wayland /usr/bin/ulauncher --hide-window
Icon=ulauncher
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true'

    # Cria .desktop em ambos os locais
    echo "$DESKTOP_ENTRY" > "$AUTOSTART_DIR/ulauncher.desktop"
    echo "$DESKTOP_ENTRY" > "$APPLICATIONS_DIR/ulauncher.desktop"

    log_success "Ulauncher configured (apps + autostart)"
}

