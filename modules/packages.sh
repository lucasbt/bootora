#!/bin/bash
#
# Packages Module - Base Package Installation
# Installs commonly used base packages
#

# Execute packages module
execute_packages_module() {
    log_subheader "Base Package Installation"

    local packages_file="$SCRIPT_DIR/packages/packages.list"

    if [ ! -f "$packages_file" ]; then
        log_error "Package list file not found: $packages_file"
        return 1
    fi

    log_info "Installing base packages from $packages_file..."

    local installed_count=0
    local failed_count=0
    local total_count=0

    # Count total packages (excluding comments and empty lines)
    while IFS= read -r package || [ -n "$package" ]; do
        # Skip empty lines and comments
        if [[ -z "$package" || "$package" =~ ^#.*$ ]]; then
            continue
        fi
        total_count=$((total_count + 1))
    done < "$packages_file"

    log_info "Found $total_count packages to install"

    local current=0

    # Install packages
    while IFS= read -r package || [ -n "$package" ]; do
        # Skip empty lines and comments
        if [[ -z "$package" || "$package" =~ ^#.*$ ]]; then
            continue
        fi

        # Clean package name
        package=$(echo "$package" | xargs)
        current=$((current + 1))

        show_progress $current $total_count "Installing $package"

        if is_package_installed "$package"; then
            installed_count=$((installed_count + 1))
        else
            if superuser_do dnf install -y "$package"; then
                installed_count=$((installed_count + 1))
            else
                failed_count=$((failed_count + 1))
                echo
                log_warning "Failed to install: $package"
            fi
        fi
    done < "$packages_file"

    echo  # Clear progress line

    # Install special packages
    install_special_packages

    # Summary
    log_success "Package installation completed"
    log_info "Installed/Already present: $installed_count packages"
    if [ $failed_count -gt 0 ]; then
        log_warning "Failed: $failed_count packages"
    fi

    return 0
}

# Install special packages that need custom handling
install_special_packages() {
    log_subheader "Installing Special Packages"

    # Install Chrome/Chromium
    install_chrome

    # Install Opera
    install_opera

    # Install additional development tools
    install_additional_dev_tools

    # Install security tools
    install_bitwarden_gui
    install_bitwarden_cli

    #install_ulauncher
}

install_opera() {
    if is_command_available "opera"; then
        log_info "Opera already installed"
        return 0
    fi

    log_info "Installing Opera Browser..."

    # Importa chave GPG do Opera
    superuser_do rpm --import https://rpm.opera.com/rpmrepo.key

    # Adiciona repositório do Opera
    cat << 'EOF' | superuser_do tee /etc/yum.repos.d/opera.repo > /dev/null
[Opera]
name=Opera packages
type=rpm-md
baseurl=https://rpm.opera.com/rpm
gpgcheck=1
gpgkey=https://rpm.opera.com/rpmrepo.key
enabled=1
EOF

    # Instala Opera
    if superuser_do dnf install -y opera-stable; then
        log_success "Opera Browser installed"
    else
        log_failed "Failed to install Opera Browser"
    fi
}


# Install Google Chrome
install_chrome() {
    if is_command_available "google-chrome"; then
        log_info "Google Chrome already installed"
        return 0
    fi

    log_info "Installing Google Chrome..."

    # Add Google repository
    cat << 'EOF' | superuser_do tee /etc/yum.repos.d/google-chrome.repo > /dev/null
[Google-Chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
EOF

    if superuser_do dnf install -y google-chrome-stable; then
        log_success "Google Chrome installed"
    else
        log_warning "Failed to install Google Chrome, trying Chromium..."
        install_dnf_package "chromium" "Chromium Browser"
    fi
}

# Install additional development tools
install_additional_dev_tools() {
    log_info "Installing additional development tools packages..."

    local dev_tools=(
        "vim-enhanced"
        "meld"
        "autoconf"
        "automake"
        "breezy"
        "git"
        "git-delta"
        "git-subtree"
        "hexedit"
    )

    for tool in "${dev_tools[@]}"; do
        install_dnf_package "$tool" "$tool" || true  # Don't fail if optional tools fail
    done
}

install_bitwarden_gui() {
    log_info "Installing Bitwarden (GUI)..."

    local install_dir="/opt/bitwarden"
    local appimage_path="$install_dir/Bitwarden.AppImage"
    local bin_symlink="/usr/local/bin/bitwarden"
    local desktop_file="$HOME/.local/share/applications/bitwarden.desktop"
    local temp_dir="/tmp/bitwarden"
    local temp_appimage="$temp_dir/Bitwarden.AppImage"
    local download_url="https://vault.bitwarden.com/download/?app=desktop&platform=linux" # redirects to AppImage

    # Check if already installed
    if [[ -f "$appimage_path" && -x "$appimage_path" ]]; then
        log_info "Bitwarden already installed at $install_dir"
        return 0
    fi

    mkdir -p "$temp_dir"
    superuser_do mkdir -p "$install_dir"
    superuser_do chmod 755 "$install_dir"

    log_info "Downloading Bitwarden AppImage..."
    if curl -L -o "$temp_appimage" "$download_url"; then
        superuser_do mv "$temp_appimage" "$appimage_path"
        superuser_do chmod +x "$appimage_path"
        sudo curl -L -o "$install_dir/bitwarden.png" https://raw.githubusercontent.com/bitwarden/clients/main/apps/desktop/resources/icons/256x256.png        

        # Create symlink
        superuser_do ln -sf "$appimage_path" "$bin_symlink"
        log_info "Created symlink: $bin_symlink → Bitwarden"

        # Create .desktop launcher
        mkdir -p "$(dirname "$desktop_file")"
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Bitwarden
Exec=$appimage_path
Icon=$install_dir/bitwarden.png
Terminal=false
Categories=Utility;Security;
StartupNotify=true
EOF

        chmod +x "$desktop_file"
        log_success "Bitwarden GUI installed successfully and launcher created"
    else
        log_failed "Failed to download Bitwarden"
        return 1
    fi

    # Clean temp
    rm -rf "$temp_dir"
}

install_bitwarden_cli() {
    log_info "Installing Bitwarden CLI..."

    local install_dir="/opt/bitwarden-cli"
    local bin_symlink="/usr/local/bin/bw"
    local temp_dir="/tmp/bitwarden-cli"
    local archive_path="$temp_dir/bw.zip"
    local download_url="https://vault.bitwarden.com/download/?app=cli&platform=linux"

    # Check if already installed
    if [[ -f "$install_dir/bw" && -x "$install_dir/bw" ]]; then
        log_info "Bitwarden CLI already installed at $install_dir"
        return 0
    fi

    mkdir -p "$temp_dir"
    superuser_do mkdir -p "$install_dir"

    log_info "Downloading Bitwarden CLI..."
    if curl -L -o "$archive_path" "$download_url"; then
        unzip -q "$archive_path" -d "$temp_dir"
        superuser_do mv "$temp_dir/bw" "$install_dir/"
        superuser_do chmod +x "$install_dir/bw"

        # Create symlink
        superuser_do ln -sf "$install_dir/bw" "$bin_symlink"
        log_info "Created symlink: $bin_symlink → bw"

        log_success "Bitwarden CLI installed successfully"
    else
        log_failed "Failed to download Bitwarden CLI"
        return 1
    fi

    # Clean temp
    rm -rf "$temp_dir"
}

install_ulauncher() {
    log_info "Installing Ulauncher..."

    local desktop_file="$HOME/.config/autostart/ulauncher.desktop"
    local config_file="$HOME/.config/ulauncher/settings.json"
    local exec_path="/usr/bin/ulauncher"

    # Verifica se o Ulauncher está instalado
    if ! command -v ulauncher >/dev/null 2>&1; then
        log_info "Ulauncher not found, installing..."
        superuser_do dnf install -y ulauncher
    else
        log_info "Ulauncher is already installed"
    fi

    # Cria o atalho .desktop
    log_info "Creating autostart desktop entry..."
    mkdir -p "$(dirname "$desktop_file")"
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=Ulauncher
Comment=Application launcher for Linux
GenericName=Launcher
Categories=GNOME;GTK;Utility;
TryExec=$exec_path
Exec=env GDK_BACKEND=wayland $exec_path --hide-window
Icon=ulauncher
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF

    chmod +x "$desktop_file"
    log_info "Desktop entry created at $desktop_file"

    # Cria o arquivo de configuração JSON
    log_info "Creating Ulauncher config file..."
    mkdir -p "$(dirname "$config_file")"
    cat > "$config_file" <<EOF
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

    log_success "Ulauncher installed and configured successfully"
}