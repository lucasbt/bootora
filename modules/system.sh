#!/bin/bash
#
# System Module - System Update & Configuration
# Updates system packages and installs essential dependencies
#

# 1. Atualização completa do sistema
system_update() {
    log_info "Updating system packages..."
    if superuser_do dnf update -y; then
        log_success "System packages updated"
    else
        log_error "Failed to update system packages"
        return 1
    fi

    # Install essential dependencies
    log_info "Installing essential dependencies..."
    local essential_packages=(
        "curl"
        "wget"
        "git"
        "unzip"
        "tar"
        "gzip"
        "ca-certificates"
        "gnupg"
        "dnf-plugins-core"
        "software-properties-common"
        "lsb-release"
        "dconf-editor"
        "util-linux"
        "fontconfig"
        "fedora-workstation-repositories"
        "gnome-keyring"
        "libgnome-keyring"
    )

    for package in "${essential_packages[@]}"; do
        install_dnf_package "$package"
    done

    return 0
}

# 2. RPM Fusion + Flathub
configure_repositories() {
    log_info "Configuring RPM Fusion repositories..."
    local fedora_version=$(get_fedora_version)

    # Enable RPM Fusion Free
    local free_repo="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm"
    if ! dnf repolist | grep -q "rpmfusion-free"; then
        if superuser_do dnf install -y "$free_repo"; then
            log_success "RPM Fusion Free repository enabled"
        else
            log_warning "Failed to enable RPM Fusion Free repository"
            return 1
        fi
    else
        log_info "RPM Fusion Free already enabled"
    fi

    # Enable RPM Fusion Non-Free
    local nonfree_repo="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"
    if ! dnf repolist | grep -q "rpmfusion-nonfree"; then
        if superuser_do dnf install -y "$nonfree_repo"; then
            log_success "RPM Fusion Non-Free repository enabled"
        else
            log_warning "Failed to enable RPM Fusion Non-Free repository"
            return 1
        fi
    else
        log_info "RPM Fusion Non-Free already enabled"
    fi

    superuser_do dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

    # Configure Flathub
    log_info "Configuring Flathub repository..."
    install_dnf_package "flatpak"

    if ! flatpak remotes | grep -q "flathub"; then
        if flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
            log_success "Flathub repository added"
        else
            log_warning "Failed to add Flathub repository"
            return 1
        fi
    else
        log_info "Flathub already configured"
    fi

    return 0
}

# 3. Otimizações do DNF
optimize_dnf() {
    log_info "Applying DNF optimizations..."

    # Enable fastest mirror
    if ! grep -q "fastestmirror=True" /etc/dnf/dnf.conf; then
        echo "fastestmirror=True" | superuser_do tee -a /etc/dnf/dnf.conf > /dev/null
        log_success "DNF fastest mirror enabled"
    else
        log_info "DNF fastest mirror already enabled"
    fi

    # Set parallel downloads
    if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
        echo "max_parallel_downloads=10" | superuser_do tee -a /etc/dnf/dnf.conf > /dev/null
        log_success "DNF parallel downloads configured (10 threads)"
    else
        log_info "DNF parallel downloads already configured"
    fi

    # Enable delta RPMs
    if ! grep -q "deltarpm=True" /etc/dnf/dnf.conf; then
        echo "deltarpm=True" | superuser_do tee -a /etc/dnf/dnf.conf > /dev/null
        log_success "DNF delta RPMs enabled"
    else
        log_info "DNF delta RPMs already enabled"
    fi

    # Set keepcache
    if ! grep -q "keepcache=True" /etc/dnf/dnf.conf; then
        echo "keepcache=True" | superuser_do tee -a /etc/dnf/dnf.conf > /dev/null
        log_success "DNF cache retention enabled"
    else
        log_info "DNF cache retention already enabled"
    fi

    # Clean and rebuild cache
    log_info "Rebuilding DNF cache with optimizations..."
    if superuser_do dnf makecache --refresh; then
        log_success "DNF cache rebuilt successfully"
    else
        log_warning "Failed to rebuild DNF cache"
        return 1
    fi

    return 0
}

# Execute system module
execute_system_module() {
    log_subheader "System Update & Configuration"

    # Execute each component
    if ! system_update; then
        log_error "System update failed"
        return 1
    fi

    if ! configure_repositories; then
        log_error "Repository configuration failed"
        return 1
    fi

    if ! optimize_dnf; then
        log_error "DNF optimization failed"
        return 1
    fi

    log_success "System module configuration completed successfully"
    return 0
}