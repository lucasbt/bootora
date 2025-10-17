#!/bin/bash
#
# Flatpak Module - Flatpak Applications
# Installs Flatpak applications from the package list
#

# Execute flatpak module
execute_flatpak_module() {
    log_subheader "Flatpak Applications Installation"

    # Ensure Flatpak is installed and configured
    setup_flatpak

    # Install Flatpak applications from list
    install_flatpak_applications

    # Configure Flatpak settings
    configure_flatpak_settings

    log_success "Flatpak module completed successfully"
    return 0
}

# Setup Flatpak
setup_flatpak() {
    log_info "Setting up Flatpak..."

    # Install Flatpak if not present
    if ! is_command_available "flatpak"; then
        install_dnf_package "flatpak" "Flatpak"
    fi

    # Add Flathub repository if not present
    if ! flatpak remotes | grep -q "flathub"; then
        log_info "Adding Flathub repository..."
        if superuser_do flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
            log_success "Flathub repository added"
        else
            log_error "Failed to add Flathub repository"
            return 1
        fi
    else
        log_info "Flathub repository already configured"
    fi

    # Update Flatpak repositories
    log_info "Updating Flatpak repositories..."
    flatpak update --appstream &>/dev/null || log_warning "Failed to update appstream data"
}

# Install Flatpak applications
install_flatpak_applications() {
    local packages_file="$SCRIPT_DIR/packages/flatpak.list"

    if [ ! -f "$packages_file" ]; then
        log_error "Flatpak packages file not found: $packages_file"
        return 1
    fi

    log_info "Installing Flatpak applications..."

    local installed_count=0
    local failed_count=0
    local total_count=0

    # Count total packages
    while IFS= read -r package || [ -n "$package" ]; do
        if [[ -z "$package" || "$package" =~ ^#.*$ ]]; then
            continue
        fi
        total_count=$((total_count + 1))
    done < "$packages_file"

    log_info "Found $total_count Flatpak applications to install"

    local current=0

    # Install applications
    while IFS= read -r package || [ -n "$package" ]; do
        if [[ -z "$package" || "$package" =~ ^#.*$ ]]; then
            continue
        fi

        package=$(echo "$package" | xargs)
        current=$((current + 1))

        show_progress $current $total_count "Installing $package"

        if is_flatpak_installed "$package"; then
            installed_count=$((installed_count + 1))
        else
            if install_flatpak_with_retry "$package"; then
                installed_count=$((installed_count + 1))
            else
                failed_count=$((failed_count + 1))
                echo
                log_warning "Failed to install: $package"
            fi
        fi
    done < "$packages_file"

    echo  # Clear progress line

    log_success "Flatpak applications installation completed"
    log_info "Installed/Already present: $installed_count applications"
    if [ $failed_count -gt 0 ]; then
        log_warning "Failed: $failed_count applications"
    fi
}

# Install Flatpak with retry mechanism
install_flatpak_with_retry() {
    local package="$1"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if flatpak install -y flathub "$package"; then
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            sleep 2  # Wait before retry
        fi
    done

    return 1
}

# Configure Flatpak settings
configure_flatpak_settings() {
    log_info "Configuring Flatpak settings..."

    # Configure Flatpak themes
    configure_flatpak_themes

    # Set up Flatpak desktop integration
    setup_flatpak_desktop_integration

    install_special_flatpak_apps

    log_success "Flatpak settings configured"
}

# Configure Flatpak themes
configure_flatpak_themes() {
    log_info "Configuring Flatpak themes..."

    # Install Flatpak theme extensions if using GNOME
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
        # Install GNOME themes for Flatpak
        if ! is_flatpak_installed "org.gtk.Gtk3theme.Adwaita-dark"; then
            flatpak install -y flathub org.gtk.Gtk3theme.Adwaita-dark || true
        fi

        if ! is_flatpak_installed "org.freedesktop.Platform.gtk-theme.Adwaita-dark"; then
            flatpak install -y flathub org.freedesktop.Platform.gtk-theme.Adwaita-dark || true
        fi
    fi

    # Set theme permissions for better integration
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro || true
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro || true

    log_success "Flatpak themes configured"
}

# Setup Flatpak desktop integration
setup_flatpak_desktop_integration() {
    log_info "Setting up Flatpak desktop integration..."

    # Update desktop database
    if is_command_available "update-desktop-database"; then
        update-desktop-database "$HOME/.local/share/applications" || true
    fi

    # Update icon cache
    if is_command_available "gtk-update-icon-cache"; then
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" || true
    fi

    log_success "Desktop integration configured"
}

# Install specific popular applications with extra configuration
install_special_flatpak_apps() {
    log_info "Installing and configuring special Flatpak applications..."

    # Spotify with media keys support
    if install_flatpak_package "com.spotify.Client" "Spotify"; then
        flatpak override --user --socket=session-bus com.spotify.Client 
        flatpak override --user --socket=system-bus com.spotify.Client 
    fi
}
