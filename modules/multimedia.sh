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

    # Configure multimedia settings
    configure_multimedia_settings

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

    # Install GStreamer plugins
    log_info "Installing GStreamer plugins..."
    local gstreamer_plugins=(
        "gstreamer1-plugins-base"
        "gstreamer1-plugins-good"
        "gstreamer1-plugins-bad-free"
        "gstreamer1-plugins-ugly"
        "gstreamer1-plugin-openh264"
        "gstreamer1-libav"
    )

    for plugin in "${gstreamer_plugins[@]}"; do
        install_dnf_package "$plugin" "$plugin"
    done

    # Install additional codecs from RPM Fusion
    if dnf repolist | grep -q "rpmfusion"; then
        log_info "Installing additional codecs from RPM Fusion..."

        # Install multimedia group            
        if sudo dnf group install multimedia -y --best --allowerasing --skip-broken --with-optional --exclude=PackageKit-gstreamer-plugin; then
            log_success "Multimedia group installed"
        else
            log_warning "Failed to install Multimedia group"
        fi

        # Install specific codec packages
        local codec_packages=(
            "libavcodec-freeworld"
            "x264"
            "x265"
            "lame"
            "faac"
            "faad2"
            "libva-intel-media-driver"
        )

        for codec in "${codec_packages[@]}"; do
            install_dnf_package "$codec" "$codec"
        done
        
        log_info "Installing ffmpeg..."
        sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing
        sudo dnf install -y ffmpeg-full --allowerasing
        sudo dnf install -y 'ffmpeg-libs'
        
        log_info "Installing additional GStreamer plugins..."
        superuser_do dnf install -y --best --allowerasing --skip-broken gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
        log_info "Installing Lame plugins..."
        superuser_do dnf install -y --best --allowerasing --skip-broken lame lame-libs --exclude=lame-devel
        log_info "Update groups core and multimedia..."
        sudo dnf update -y '@core' '@multimedia' --exclude='PackageKit-gstreamer-plugin' --allowerasing && sync
    else
        log_warning "RPM Fusion repositories not available, skipping additional codecs"
    fi

    # Install hardware acceleration drivers
    install_hardware_acceleration_drivers
}

# Install hardware acceleration drivers
install_hardware_acceleration_drivers() {
    log_info "Installing hardware acceleration drivers..."

    # VA-API drivers
    local vaapi_drivers=(
        "mesa-va-drivers"
        "intel-media-driver"
        "libva-intel-driver"
    )

    for driver in "${vaapi_drivers[@]}"; do
        install_dnf_package "$driver" "$driver" || true
    done

    # VDPAU drivers
    local vdpau_drivers=(
        "mesa-vdpau-drivers"
        "libvdpau-va-gl"
    )

    for driver in "${vdpau_drivers[@]}"; do
        install_dnf_package "$driver" "$driver" || true
    done

    log_success "Hardware acceleration drivers installed"
}

# Configure multimedia settings
configure_multimedia_settings() {
    log_info "Configuring multimedia settings..."

    # Configure PipeWire (if available)
    if is_command_available "pipewire"; then
        configure_pipewire
    fi

    # Set default applications
    configure_default_multimedia_apps
}

# Configure PipeWire
configure_pipewire() {
    log_info "Configuring PipeWire..."

    # Enable PipeWire services for user
    if systemctl --user is-enabled pipewire.service &>/dev/null; then
        log_info "PipeWire already enabled"
    else
        systemctl --user enable pipewire.service
        systemctl --user enable pipewire-pulse.service
        systemctl --user enable wireplumber.service
        log_success "PipeWire services enabled"
    fi

    # Start PipeWire services
    systemctl --user start pipewire.service || true
    systemctl --user start pipewire-pulse.service || true
    systemctl --user start wireplumber.service || true

    log_success "PipeWire configured"
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

    log_success "Default multimedia applications configured"
}
