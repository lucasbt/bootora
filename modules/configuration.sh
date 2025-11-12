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

    apply_gnome_configs

    # Configure development environment
    configure_folders_development_environment

    # Setup useful aliases and functions
    setup_shell_enhancements

    configure_environment_apps

    log_success "Configuration module completed successfully"
    return 0
}

apply_gnome_configs(){
    log_info "Applying Gnome Hotkeys..."

    # Alt+F4 is very cumbersome
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
    
    # Make it easy to maximize like you can fill left/right
    gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"

    # Make it easy to resize undecorated windows
    gsettings set org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"

    # Full-screen with title/navigation bar
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"

    # Use super for workspaces
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"

    # Reserve slots for custom keybindings
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/']"

    # Set flameshot (with the sh fix for starting under Wayland) on alternate print screen key
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Flameshot'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'sh -c -- "flameshot gui"'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Control>Print'

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'taskmanager'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gnome-system-monitor'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Control><Shift>Escape'

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'terminal'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'ptyxis'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Control><Alt>t'

    # Center new windows in the middle of the screen
    gsettings set org.gnome.mutter center-new-windows true
    
    # Set Cascadia Mono as the default monospace font
    gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaMono Nerd Font 10'

    # Reveal week numbers in the Gnome calendar
    gsettings set org.gnome.desktop.calendar show-weekdate true

    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

    gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true

    gsettings set org.gnome.SessionManager logout-prompt false

    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

    gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"

    gsettings set org.gnome.nautilus.preferences show-create-link 'true'
    gsettings set org.gnome.nautilus.preferences show-delete-permanently 'true'
    gsettings set org.gtk.Settings.FileChooser sort-directories-first 'true'
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

    gsettings set org.gnome.TextEditor show-line-numbers 'true'
    gsettings set org.gnome.TextEditor spellcheck 'false'

    gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

    add_nodisplay_true
}

add_nodisplay_true() {
    log_info "Set display false to gnome apps grid for some apps..."
    for file in /usr/share/applications/htop.desktop /usr/share/applications/btop.desktop; do
        if [ -f "$file" ]; then
            if grep -q "^NoDisplay=" "$file"; then
                # Já existe uma linha NoDisplay, vamos alterar seu valor para true
                sudo sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$file"
            else
                # Adiciona NoDisplay=true logo após a linha [Desktop Entry]
                sudo sed -i '/^\[Desktop Entry\]/a NoDisplay=true' "$file"
            fi
        else
            log_info "File not found: $file"
        fi
    done
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

    # Configure Zsh if installed
    if is_command_available "zsh"; then
        configure_zsh
    fi

    # Install and configure useful shell tools
    install_shell_tools

    log_success "Shell environment configured"
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
        curl -sS https://starship.rs/install.sh | sh
        log_success "Starship installed"
    else
        log_info "Starship already installed"
    fi

    STARSHIP_CMD='eval "$(starship init zsh)"'
    # Verifica se a linha já existe
    if ! grep -Fxq "$STARSHIP_CMD" "$zshrc"; then
        echo "" >> "$zshrc"               # adiciona uma linha em branco
        echo "$STARSHIP_CMD" >> "$zshrc"  # adiciona o comando
        log_success "Starship init adicionado ao ~/.zshrc"
    else
        log_info "Starship init já existe em ~/.zshrc"
    fi

    # Install Zsh plugins
    install_zsh_plugins

    log_success "Zsh configured with Starship and plugins"

    # Ask to set Zsh as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        if ask_yes_no "Set Zsh as your default shell?" "n"; then
            sudo chsh -s $(which zsh) "$USERNAME"
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

# load fzf only when pressing CTRL+T or first fzf command
zle -N fzf-file-widget fzf_lazy

# Set up fzf key bindings and fuzzy completion"

    # Add to bashrc
    if [ -f "$HOME/.bashrc" ] && ! grep -q "fzf configuration" "$HOME/.bashrc"; then
        echo "$fzf_config" >> "$HOME/.bashrc"
        echo "source <(fzf --bash)" >> "$HOME/.bashrc"
    fi

    # Add to zshrc
    if [ -f "$HOME/.zshrc" ] && ! grep -q "fzf configuration" "$HOME/.zshrc"; then
        echo "$fzf_config" >> "$HOME/.zshrc"
        echo "source <(fzf --zsh)" >> "$HOME/.zshrc"
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

    # General tweaks
    sudo systemctl disable NetworkManager-wait-online.service
    sudo rm -rf /etc/yum.repos.d/{_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo,rpmfusion-nonfree-nvidia-driver.repo,rpmfusion-nonfree-steam.repo,google-chrome.repo}
    sudo rm -f /usr/lib64/firefox/browser/defaults/preferences/firefox-redhat-default-prefs.js
    sudo rm -rf /etc/xdg/autostart/org.gnome.Software.desktop

    spinner_run "Update firmwares..." "fwupdmgr refresh --force;fwupdmgr get-devices;fwupdmgr get-updates;fwupdmgr update; sleep 2"

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
    ensure_directory "$HOME/Documents/resources/brain"
    ensure_directory "$HOME/Documents/resources/pictures"
    ensure_directory "$HOME/Documents/resources/pictures/wallpapers"
    ensure_directory "$HOME/Documents/resources/music"
    ensure_directory "$HOME/Documents/resources/videos"
    ensure_directory "$HOME/Documents/archives"
    ensure_directory "$HOME/Documents/areas"
    ensure_directory "$HOME/.local/bin"

    cp -r "$HOME/Pictures/"* "$HOME/Documents/resources/pictures/" 2>/dev/null || true
    rm -rf "$HOME/Pictures" && ln -s "$HOME/Documents/resources/pictures" "$HOME/Pictures"

    # add 'new empty file' in the context menu
	touch ~/Templates/Empty\ File

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
h=$HOME
p=$HOME/Documents/projects
dev=$HOME/Develop
dw=$HOME/Downloads
d=$HOME/Documents
c=$HOME/.config
l=$HOME/.local
r=$HOME/Documents/resources
b=$HOME/Documents/resources/brain
a=$HOME/Documents/archives
EOF

        # Add bookmark functions to shell functions
        cat >> "$HOME/.bash_functions" << 'EOF'

# Bookmark functions
bm() {
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

# Automatically fix Ulauncher hotkey issue on Wayland (GNOME only)
configure_ulauncher() {
    log_info "Configuring Ulauncher..."

    # Instala o pacote caso não exista
    install_dnf_package "ulauncher" "Ulauncher" || true

    # 1. Check if running under Wayland
    if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        log_warning "You are not running a Wayland session (current: $XDG_SESSION_TYPE)"
        log_warning "This fix is only needed when running Wayland."
        return 1
    fi

    # 2. Install wmctrl
    log_info "Installing wmctrl..."
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y wmctrl
    else
        log_failed "Unsupported package manager. Please install manually: sudo dnf/apt install wmctrl"
        return 1
    fi

    # 3. Define hotkey details
    local name="Ulauncher toggle"
    local cmd="ulauncher-toggle"
    local binding="<Super>Space"   # change this key if you want another shortcut

    # 4. Create GNOME custom keybinding via gsettings
    echo "⚙️  Creating GNOME shortcut for '$cmd' with key $binding"

    # Path for the new keybinding
    local new_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ulauncher-toggle/"

    # Get current list of custom keybindings
    local current_shortcuts
    current_shortcuts=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    # Normalize if empty
    if [ "$current_shortcuts" = "@as []" ]; then
        current_shortcuts="[]"
    fi

    # Remove extra spaces
    current_shortcuts=$(echo "$current_shortcuts" | tr -d ' ')

    # 5. Add the new keybinding path if not already present
    if [[ "$current_shortcuts" != *"$new_path"* ]]; then
        if [ "$current_shortcuts" = "[]" ]; then
            new_shortcuts="['$new_path']"
        else
            # Remove closing bracket and safely append the new path
            new_shortcuts="${current_shortcuts%]*}, '$new_path']"
        fi
        echo "🧩 Updating custom shortcuts list..."
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_shortcuts"
    fi

    # 6. Set the name, command, and keybinding
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_path" name "$name"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_path" command "$cmd"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_path" binding "$binding"

    echo "Ulauncher Keybinding: $binding"
     log_success "Ulauncher configured"
}