#!/bin/bash
#
# Multimedia Module - Multimedia Packages & Codecs
# Installs multimedia packages and codecs
#

# Execute multimedia module
execute_multimedia_module() {
    log_subheader "Multimedia Packages & Codecs Installation"

    # Install multimedia packages from list
    install_multimedia_packages_from_list

    # Install multimedia codecs
    install_multimedia_codecs

    # Set default applications
    configure_default_multimedia_apps

    log_success "Multimedia module completed successfully"
    return 0
}

# Install multimedia packages from list
install_multimedia_packages_from_list() {
    local packages_file="$SCRIPT_DIR/packages/multimedia.list"

    if [ ! -f "$packages_file" ]; then
        log_error "Multimedia packages file not found: $packages_file"
        return 1
    fi

    log_info "Installing multimedia packages..."

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

    log_info "Found $total_count multimedia packages to install"

    local current=0

    # Install packages
    while IFS= read -r package || [ -n "$package" ]; do
        if [[ -z "$package" || "$package" =~ ^#.*$ ]]; then
            continue
        fi

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

    log_success "Multimedia packages installation completed"
    log_info "Installed/Already present: $installed_count packages"
    if [ $failed_count -gt 0 ]; then
        log_warning "Failed: $failed_count packages"
    fi
}

# Install multimedia codecs
install_multimedia_codecs() {
    log_info "Installing multimedia codecs..."

    # Install additional codecs from RPM Fusion
    if dnf repolist | grep -q "rpmfusion"; then
        log_info "Installing additional codecs from RPM Fusion..."

        # Install multimedia group            
        if sudo dnf4 group install multimedia -y --best --allowerasing --skip-broken --with-optional --exclude=PackageKit-gstreamer-plugin; then
            log_success "Multimedia group installed"
        else
            log_warning "Failed to install Multimedia group"
        fi
        
        log_info "Installing ffmpeg..."
        sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing
        sudo dnf upgrade @multimedia -y --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
        
        log_info "Installing Lame plugins..."
        superuser_do dnf install -y --best --allowerasing --skip-broken lame lame-libs --exclude=lame-devel
        log_info "Update groups core and multimedia..."
        sudo dnf update -y '@core' '@multimedia' --exclude='PackageKit-gstreamer-plugin' --allowerasing && sync
        sudo dnf group install -y sound-and-video
        sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
    else
        log_warning "RPM Fusion repositories not available, skipping additional codecs"
    fi
}

# Configure default multimedia applications
configure_default_multimedia_apps() {
    log_info "Setting default multimedia applications..."

    # Set VLC as default video player if installed
    if is_command_available "vlc"; then
        xdg-mime default vlc.desktop video/mp4
        xdg-mime default vlc.desktop video/x-msvideo
        xdg-mime default vlc.desktop video/quicktime
        xdg-mime default vlc.desktop video/x-ms-wmv
        log_info "VLC set as default video player"
    fi

    # Set default audio player
    if is_command_available "rhythmbox"; then
        xdg-mime default org.gnome.Rhythmbox3.desktop audio/mpeg
        xdg-mime default org.gnome.Rhythmbox3.desktop audio/x-mp3
        xdg-mime default org.gnome.Rhythmbox3.desktop audio/flac
        log_info "Rhythmbox set as default audio player"
    fi

    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

    log_success "Default multimedia applications configured"
}
