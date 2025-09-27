#!/bin/bash
#
# Development Module - Development Tools & Languages
# Installs development tools: SDKMAN, Node.js, Go, Docker, Podman, etc.
#

# Podman usually comes with Fedora, but let's make sure
local podman_packages=(
    "podman"
    "podman-docker"
    "podman-compose"
    "buildah"
    "skopeo"
)

local docker_packages=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
    "docker-compose"
)

local npm_packages=(
    "yarn"
    "pnpm"
    "create-react-app"
    "typescript"
    "ts-node"
    "nodemon"
    "pm2"
    "eslint"
    "prettier"
)

local python_packages=(
    "virtualenv"
    "requests"
    "flask"
    "fastapi"
)

# Função genérica para executar um step com feedback em tempo real
run_step() {
    local index=$1
    local total=$2
    local desc=$3
    local func=$4

    # Atualiza barra antes de iniciar
    show_progress "$index" "$total" "$desc"

    # Executa função e exibe output em tempo real
    if ! "$func" 2>&1 | while IFS= read -r line; do
        printf "\n%s\n" "$line"
    done; then
        printf "\n❌ Error in %s\n" "$desc"
        return 1
    fi

    # Atualiza barra mostrando conclusão do step
    show_progress "$index" "$total" "$desc (done)"
}

# Loop principal usando run_step
execute_development_module() {
    log_subheader "Development Tools & Languages Installation"

    local steps=(
        install_sdkman
        install_sdkman_jdks
        install_sdkman_buildtools
        install_nodejs
        install_golang
        install_python_tools
        install_rust
        install_docker
        install_podman
        install_container_tools
        install_git_tools
        install_kubectl
        install_vscode
        install_intellij
        install_minikube
        install_awscli
        install_typora
        install_postman
        install_insomnia
        install_drawio
        install_dbeaver
    )

    local descriptions=(
        "Installing SDKMAN"
        "Installing SDKMAN - JDKs"
        "Installing SDKMAN - Build Tools"
        "Installing Node.js"
        "Installing Go"
        "Installing Python Tools"
        "Installing Rust"
        "Installing Docker"
        "Installing Podman"
        "Installing Container Tools"
        "Installing Git Tools"
        "Installing kubectl"
        "Installing VSCode"
        "Installing IntelliJ IDEA"
        "Installing Minikube"
        "Installing AWS CLI"
        "Installing Typora"
        "Installing Postman"
        "Installing Insomnia"
        "Installing Draw.io"
        "Installing DBeaver"
    )

    local total_steps=${#steps[@]}

    for i in "${!steps[@]}"; do
        local step_index=$((i + 1))
        local step_func="${steps[$i]}"
        local step_desc="${descriptions[$i]}"
        show_progress "$step_index" "$total_steps" "$step_desc"
        $step_func
    done

    printf "\n"
    log_success "Development module completed successfully"
    return 0
}


# Install Visual Studio Code
install_vscode() {
    if is_command_available "code"; then
        log_info "Visual Studio Code already installed"
        return 0
    fi

    log_info "Installing Visual Studio Code..."

    # Add Microsoft repository
    superuser_do rpm --import https://packages.microsoft.com/keys/microsoft.asc

    cat << 'EOF' | superuser_do tee /etc/yum.repos.d/vscode.repo > /dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    if superuser_do dnf install -y code; then
        log_success "Visual Studio Code installed"
    else
        log_failed "Failed to install Visual Studio Code"
    fi
}

# Install SDKMAN
install_sdkman() {
    log_info "Installing SDKMAN..."

    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi

    if is_command_available "sdk"; then
        log_info "SDKMAN already installed"
        return 0
    fi

    # Install SDKMAN
    if curl -s "https://get.sdkman.io" | bash; then
        log_success "SDKMAN installed"

        # Source SDKMAN
        source "$HOME/.sdkman/bin/sdkman-init.sh"

        add_sdkman_to_shellrc "$HOME/.bashrc" "Bash"
		add_sdkman_to_shellrc "$HOME/.zshrc" "Zsh"
        log_success "SDKMAN tool installed"
    else
        log_failed "Failed to install SDKMAN"
        return 1
    fi
}

# Install JDKS
install_sdkman_jdks() {
    log_info "Installing SDKMAN JDKs..."

    source "$HOME/.sdkman/bin/sdkman-init.sh"

    if ! is_command_available "sdk"; then
        log_failed "SDKMAN not installed"
        return 1
    fi

    local jdks=("17.0.10-tem" "21.0.2-tem" "25-tem")
    for jdk in "${jdks[@]}"; do
        log_info "Installing Java $jdk..."
        if ! sdk install java "$jdk"; then
            log_warning "Failed to install Java $jdk"
        fi
    done

    # Set default JDK
    sdk default java "25-tem" || log_warning "Failed to set default Java"

    log_success "SDKMAN JDKs installed"
}


# Install JDKS
install_sdkman_buildtools() {
    log_info "Installing Build Tools..."

    source "$HOME/.sdkman/bin/sdkman-init.sh"

    if is_command_available "sdk"; then
        # Install build tools
        log_info "Installing Maven..."
        sdk install maven || log_warning "Failed to install Maven"

        log_info "Installing Gradle..."
        sdk install gradle || log_warning "Failed to install Gradle"

        log_success "SDKMAN build tools installed"
    else
        log_failed "Failed to install build tools, SDKMAN not installed."
        return 1
    fi
}

# Função para adicionar configuração ao arquivo de configuração do shell, se ainda não estiver presente
add_sdkman_to_shellrc() {
    local shellrc="$1"
	# Configuração para lazy-load no Zsh
    local SDKMAN_LAZY_CONFIG='''

# SDKMAN! Lazy Load
sdk() {
    unset -f sdk
    export SDKMAN_DIR=$HOME/.sdkman
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk "$@"
}
'''

    if [ -f "$shellrc" ]; then
		if ! grep -qF "# SDKMAN! Lazy Load" "$shellrc"; then
			info "Configuring SDKMAN for $2..."
		    echo "$SDKMAN_LAZY_CONFIG" >> "$shellrc"
		else
			success "SDKMAN is already configured for $2..."
		fi
    fi
}

# Install NVM and configure lazy loading + autocompletion in Bash and Zsh
install_nvm() {
    log_info "Installing NVM..."
    local nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"

    # Install NVM if not already installed
    if is_command_available "nvm"; then
        log_info "NVM already installed"
    else
        curl -o- "$nvm_install_url" | bash
        log_success "NVM installed"
    fi

    # Define lazy load blocks
    local lazy_block_bash="
# >>> nvm lazy load >>>
export NVM_DIR=\"\$HOME/.nvm\"
nvm() {
    unset -f nvm
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    [ -s \"\$NVM_DIR/bash_completion\" ] && . \"\$NVM_DIR/bash_completion\"
    nvm \"\$@\"
}
# <<< nvm lazy load <<<"

    local lazy_block_zsh="
# >>> nvm lazy load >>>
export NVM_DIR=\"\$HOME/.nvm\"
autoload -U bashcompinit
bashcompinit
nvm() {
    unset -f nvm
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    [ -s \"\$NVM_DIR/bash_completion\" ] && . \"\$NVM_DIR/bash_completion\"
    nvm \"\$@\"
}
# <<< nvm lazy load <<<"

    # Configure both Bash and Zsh
    for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if grep -q '# >>> nvm lazy load >>>' "$shell_rc"; then
            log_info "NVM lazy load already configured in $shell_rc"
        else
            if [[ "$shell_rc" == *".zshrc" ]]; then
                echo "$lazy_block_zsh" >> "$shell_rc"
                log_info "Added NVM lazy load with completion to $shell_rc"
            else
                echo "$lazy_block_bash" >> "$shell_rc"
                log_info "Added NVM lazy load with completion to $shell_rc"
            fi
        fi
    done

    # Load NVM and completion for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}

# Install Node.js using NVM
install_nodejs() {
    log_info "Installing Node.js with NVM..."

    # Ensure NVM is loaded in this session
    export NVM_DIR="$HOME/.nvm"
    if is_command_available "nvm"; then
        source "$NVM_DIR/nvm.sh"
    else
        log_failed "NVM is not installed or not found."
        return 1
    fi

    if is_command_available "node"; then
        log_info "Node.js already installed ($(node --version))"
    else
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
        npm config set fund false --location=global
        corepack enable
        log_success "Node.js installed via NVM ($(node --version))"
    fi

    # Install global npm packages
    log_info "Installing global npm packages..."
    for package in "${npm_packages[@]}"; do
        if npm list -g "$package" &>/dev/null; then
            log_info "$package already installed globally"
        else
            if npm install -g "$package" &>/dev/null; then
                log_success "Installed $package globally"
            else
                log_warning "Failed to install $package"
            fi
        fi
    done
}

# Install Go
install_golang() {
    log_info "Installing Go..."

    if is_command_available "go"; then
        log_info "Go already installed ($(go version))"
        return 0
    fi

    # Get latest Go version from official website
    local latest_version
    latest_version=$(curl -s https://go.dev/VERSION?m=text | head -n1 | sed 's/^go//')

    if [[ -z "$latest_version" ]]; then
        log_failed "Could not fetch the latest Go version"
        return 1
    fi

    # Get latest Go version
    local go_version="$latest_version"
    local go_archive="go${go_version}.linux-amd64.tar.gz"
    local go_url="https://golang.org/dl/${go_archive}"

    # Download Go
    if download_file "$go_url" "/tmp/${go_archive}" "Go ${go_version}"; then
        # Remove old installation
        superuser_do rm -rf /usr/local/go

        # Extract new installation
        superuser_do tar -C /usr/local -xzf "/tmp/${go_archive}"
        rm "/tmp/${go_archive}"

        # Add to PATH for current session
        export PATH=$PATH:/usr/local/go/bin

        # Add to shell profiles
        add_to_path "/usr/local/go/bin" "$HOME/.bashrc"
        add_to_path "/usr/local/go/bin" "$HOME/.zshrc"

        # Set GOPATH
        add_environment_variable "GOPATH" "$HOME/go" "$HOME/.bashrc"
        add_environment_variable "GOPATH" "$HOME/go" "$HOME/.zshrc"

        log_success "Go installed ($(go version))"
    else
        log_failed "Failed to install Go"
        return 1
    fi
}

# Install Python development tools
install_python_tools() {
    log_info "Installing Python development tools..."

    # Install pip if not available
    if ! is_command_available "pip"; then
        install_dnf_package "python3-pip" "Python pip"
    fi

    # Install Poetry
    if ! is_command_available "poetry"; then
        log_info "Installing Poetry..."
        if curl -sSL https://install.python-poetry.org | python3 -; then
            add_to_path "$HOME/.local/bin" "$HOME/.bashrc"
            add_to_path "$HOME/.local/bin" "$HOME/.zshrc"
            log_success "Poetry installed"
        else
            log_failed "Failed to install Poetry"
        fi
    else
        log_info "Poetry already installed"
    fi

    # Install pipx
    if ! is_command_available "pipx"; then
        log_info "Installing pipx..."
        if pip install --user pipx; then
            pipx ensurepath
            log_success "pipx installed"
        else
            log_failed "Failed to install pipx"
        fi
    else
        log_info "pipx already installed"
    fi

    # Install common Python packages
    log_info "Installing common Python packages..."

    for package in "${python_packages[@]}"; do
        pip install --user "$package" &>/dev/null || log_warning "Failed to install $package"
    done
}

# Install Rust
install_rust() {
    log_info "Installing Rust..."

    if is_command_available "rustc"; then
        log_info "Rust already installed ($(rustc --version))"
        return 0
    fi

    # Install Rust using rustup
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        # Source cargo environment
        source "$HOME/.cargo/env"

        # Add to shell profiles
        add_to_path "$HOME/.cargo/bin" "$HOME/.bashrc"
        add_to_path "$HOME/.cargo/bin" "$HOME/.zshrc"

        log_success "Rust installed ($(rustc --version))"
    else
        log_failed "Failed to install Rust"
        return 1
    fi
}

# Install Docker Engine
install_docker() {
    log_info "Installing Docker Engine..."

    if is_command_available "docker"; then
        log_info "Docker already installed ($(docker --version))"
        return 0
    fi

    # Remove old versions
    superuser_do dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine &>/dev/null || true

    # Add Docker repository
    superuser_do dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    # Install Docker packages
    if superuser_do dnf install -y "${docker_packages[@]}"; then
        mkdir -p /home/"$USER"/.docker
        # Add user to docker group
        if [ "$EUID" -ne 0 ]; then
        	superuser_do groupadd -f docker
            superuser_do gpasswd -a ${USER} docker
            superuser_do usermod -aG docker "$USER"
            chown "$USER":"$USER" /home/"$USER"/.docker -R
            chmod g+rwx "$HOME/.docker" -R
            log_warning "Added $USER to docker group. Please logout and login again."
        fi

        # Start and enable Docker
        enable_service "docker" "Docker"
        start_service "docker" "Docker"
        docker run hello-world
        log_success "Docker Engine installed successfully"
    else
        log_failed "Failed to install Docker Engine"
        return 1
    fi
}

# Install Podman and related tools
install_podman() {
    log_info "Installing Podman..."

    for package in "${podman_packages[@]}"; do
        install_dnf_package "$package" "$package"
    done

    log_success "Podman tools installed"
}

install_container_tools() {
    log_info "Installing container tools and virtualization..."
    # Container tools
    install_dnf_package "kubernetes" "Kubernetes tools" || true
    install_dnf_package "helm" "Helm" || true

    superuser_do dnf group install -y --skip-broken --with-optional --allowerasing Virtualization
}

install_git_tools() {
    log_info "Installing Git and GitHub tools..."

    install_dnf_package "git-lfs" "Git LFS"
    install_dnf_package "gh" "GitHub CLI"
}

# Install kubectl
install_kubectl() {
    log_info "Installing kubectl..."

    # Install kubectl if not available
    if ! is_command_available "kubectl"; then
        log_info "Kubectl already installed."
        return 0
    fi

    local kubectl_url="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

    if download_file "$kubectl_url" "/tmp/kubectl" "kubectl"; then
        superuser_do install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
        rm -rf /tmp/kubectl
        kubectl version --client
        log_success "kubectl installed"
    else
        log_failed "Failed to install kubectl"
    fi
}

# Install IntelliJ IDEA (Community Edition) from JetBrains site
install_intellij() {
    log_info "Installing IntelliJ IDEA..."

    local install_dir="/opt/idea"
    local bin_symlink="/usr/local/bin/intellij"
    local temp_dir="/tmp/intellij"
    local desktop_file="$HOME/.local/share/applications/intellij.desktop"
    local product="ideaIC"  # Use 'ideaIU' for Ultimate Edition

    # Check if IntelliJ is already installed
    if [[ -d "$install_dir" && -x "$install_dir/bin/idea.sh" ]]; then
        log_info "IntelliJ IDEA already installed at $install_dir"
        return 0
    fi

    mkdir -p "$temp_dir"

    # Get the latest version info via JetBrains API
    local json_url="https://data.services.jetbrains.com/products/releases?code=${product}&latest=true&type=release"
    local download_url
    local version

    if command -v curl &>/dev/null && command -v jq &>/dev/null; then
        download_url=$(curl -s "$json_url" | jq -r ".${product}[0].downloads.linux.link")
        version=$(curl -s "$json_url" | jq -r ".${product}[0].version")
    else
        log_failed "Required tools 'curl' and 'jq' are not available"
        return 1
    fi

    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        log_failed "Could not fetch IntelliJ download URL"
        return 1
    fi

    log_info "Latest IntelliJ IDEA version: $version"
    log_info "Downloading from: $download_url"

    # Download and extract
    local archive_path="$temp_dir/intellij.tar.gz"
    if curl -L -o "$archive_path" "$download_url"; then
        superuser_do rm -rf "$install_dir"
        mkdir -p "$install_dir"

        tar -xzf "$archive_path" -C "$temp_dir"
        local extracted_dir
        extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "idea-IC-*" | head -n1)

        if [[ -d "$extracted_dir" ]]; then
            superuser_do mv "$extracted_dir"/* "$install_dir"
            log_success "IntelliJ IDEA extracted to $install_dir"
        else
            log_failed "Failed to extract IntelliJ archive"
            return 1
        fi

        # Create symlink
        superuser_do ln -sf "$install_dir/bin/idea.sh" "$bin_symlink"
        log_info "Created symlink: $bin_symlink → idea.sh"

        # Create desktop launcher
        mkdir -p "$(dirname "$desktop_file")"
         local icon_path="$install_dir/bin/idea.png"
        if [[ ! -f "$icon_path" ]]; then
            # Try to find the .png icon in the bin folder
            icon_path=$(find "$install_dir/bin" -maxdepth 1 -name "*.png" | head -n1)
        fi

        cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=$version
Type=Application
Name=IntelliJ IDEA
Exec="$install_dir/bin/idea.sh" %f
Icon=$icon_path
Terminal=false
Categories=Development;IDE;
StartupNotify=true
EOF

        chmod +x "$desktop_file"
        log_success "Desktop launcher created: $desktop_file"

        log_success "IntelliJ IDEA $version installed successfully"
    else
        log_failed "Failed to download IntelliJ IDEA"
        return 1
    fi

    # Optional: clean temp files
    rm -rf "$temp_dir"
}

# Install Minikube via official RPM
install_minikube() {
    log_info "Installing Minikube..."

    local rpm_url="https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm"
    local rpm_file="/tmp/minikube-latest.rpm"

    # Check if already installed
    if is_command_available "minikube"; then
        local current_version
        current_version=$(minikube version --short 2>/dev/null)
        log_info "Minikube already installed ($current_version)"
        return 0
    fi

    log_info "Downloading Minikube RPM package..."
    if curl -Lo "$rpm_file" "$rpm_url"; then
        if superuser_do dnf install -y "$rpm_file"; then
            log_success "Minikube installed successfully ($(minikube version --short))"
            rm -f "$rpm_file"
        else
            log_failed "Failed to install Minikube from RPM"
            return 1
        fi
    else
        log_failed "Failed to download Minikube RPM from $rpm_url"
        return 1
    fi
}

install_awscli(){
	local AWSCLI_URL_PACKAGE="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
	local AWSCLI_ARCHIVE_NAME="/tmp/awscli.zip"

	log_info "Installing AWS CLI..."

	if is_command_available "aws"; then
		aws --version
		log_success "AWS CLI is already installed. Skipping..."
	else
		wget -nv -c --force-progress -O "$AWSCLI_ARCHIVE_NAME" "$AWSCLI_URL_PACKAGE"
		if [ $? -ne 0 ]; then
    		log_failed "Failed downloading AWS CLI app."
		else
			log_info "Clean old packages, if exists..."
			rm -rf "/tmp/aws"
			log_info "Unzipping awscli file..."
			unzip -u -o "$AWSCLI_ARCHIVE_NAME" -d "/tmp" | pv -l -s $(unzip -Z -1 $AWSCLI_ARCHIVE_NAME | wc -l) >/dev/null
            superuser_do /tmp/aws/install
			aws --version
			log_success "Installation of AWS CLI complete."
		fi
	fi
}

# Install Typora (portable tarball) – funciona em Wayland via XWayland
install_typora() {
    log_info "Installing Typora via portable archive..."

    local install_dir="$HOME/.local/share/typora"
    local bin_link="$HOME/.local/bin/typora"
    local desktop_file="$HOME/.local/share/applications/typora.desktop"
    local temp_dir="/tmp/typora"
    local download_url="https://typora.io/linux/Typora-linux-x64.tar.gz"
    local archive="$temp_dir/typora.tar.gz"

    if is_command_available "typora"; then
        local v=$(typora --version 2>/dev/null || echo "unknown")
        log_info "Typora already installed ($v)"
        return 0
    fi

    mkdir -p "$temp_dir" "$install_dir" "$HOME/.local/bin"

    log_info "Downloading Typora..."
    if curl -L -o "$archive" "$download_url"; then
        tar -xzf "$archive" -C "$temp_dir"
        rm -f "$archive"

        mv "$temp_dir"/* "$install_dir"/

        ln -sf "$install_dir/Typora" "$bin_link"
        log_info "Created symlink: $bin_link → Typora"

        mkdir -p "$(dirname "$desktop_file")"
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Typora
Exec=$bin_link %f
Icon=$install_dir/resources/app-icons/png/1024x1024.png
Terminal=false
Categories=Utility;TextEditor;
StartupNotify=true
EOF

        chmod +x "$desktop_file"
        log_success "Typora installed successfully via portable tarball"
    else
        log_failed "Failed to download Typora"
        return 1
    fi

    rm -rf "$temp_dir"
}

# Install Postman directly from the official website (non-Flatpak)
install_postman() {
    log_info "Installing Postman..."

    local install_dir="/opt/postman"
    local bin_symlink="/usr/local/bin/postman"
    local desktop_file="$HOME/.local/share/applications/postman.desktop"
    local temp_dir="/tmp/postman"
    local archive_path="$temp_dir/postman.tar.gz"
    local download_url="https://dl.pstmn.io/download/latest/linux64"

    # Check if already installed
    if [[ -d "$install_dir" && -x "$install_dir/Postman" ]]; then
        log_info "Postman already installed at $install_dir"
        return 0
    fi

    mkdir -p "$temp_dir"

    log_info "Downloading Postman..."
    if curl -L -o "$archive_path" "$download_url"; then
        # Remove previous install if exists
        superuser_do rm -rf "$install_dir"
        mkdir -p "$install_dir"

        tar -xzf "$archive_path" -C "$temp_dir"
        superuser_do mv "$temp_dir/Postman"/* "$install_dir"

        # Create symlink
        superuser_do ln -sf "$install_dir/Postman" "$bin_symlink"
        log_info "Created symlink: $bin_symlink → Postman"

        # Create .desktop launcher
        mkdir -p "$(dirname "$desktop_file")"
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Postman
Exec=$install_dir/Postman
Icon=$install_dir/app/resources/app/assets/icon.png
Terminal=false
Categories=Development;WebDevelopment;
StartupNotify=true
EOF

        chmod +x "$desktop_file"
        log_success "Postman installed successfully and launcher created"
    else
        log_failed "Failed to download Postman"
        return 1
    fi

    # Clean temp
    rm -rf "$temp_dir"
}

# Install Insomnia (latest RPM) from official repo
install_insomnia() {
    log_info "Installing Insomnia..."

    local rpm_url="https://updates.insomnia.rest/downloads/insomnia-latest.rpm"
    local rpm_file="/tmp/insomnia-latest.rpm"

    # Check if installed
    if is_command_available "insomnia"; then
        local current_version
        current_version=$(insomnia --version 2>/dev/null || echo "unknown")
        log_info "Insomnia already installed ($current_version)"
        return 0
    fi

    log_info "Downloading Insomnia RPM..."
    if curl -Lo "$rpm_file" "$rpm_url"; then
        if superuser_do dnf install -y "$rpm_file"; then
            log_success "Insomnia installed successfully ($(insomnia --version))"
            rm -f "$rpm_file"
        else
            log_failed "Failed to install Insomnia from RPM"
            return 1
        fi
    else
        log_failed "Failed to download Insomnia RPM"
        return 1
    fi
}

# Install draw.io (latest RPM)
install_drawio() {
    log_info "Installing draw.io..."

    local rpm_url="https://github.com/jgraph/drawio-desktop/releases/latest/download/draw.io-amd64.rpm"
    local rpm_file="/tmp/drawio-latest.rpm"

    # Check if installed
    if is_command_available "drawio"; then
        local current_version
        current_version=$(drawio --version 2>/dev/null || echo "unknown")
        log_info "draw.io already installed ($current_version)"
        return 0
    fi

    log_info "Downloading draw.io RPM..."
    if curl -Lo "$rpm_file" "$rpm_url"; then
        if superuser_do dnf install -y "$rpm_file"; then
            log_success "draw.io installed successfully"
            rm -f "$rpm_file"
        else
            log_failed "Failed to install draw.io from RPM"
            return 1
        fi
    else
        log_failed "Failed to download draw.io RPM"
        return 1
    fi
}

install_dbeaver() {
    log_info "Installing DBeaver Community..."

    local install_dir="/opt/dbeaver"
    local bin_symlink="/usr/local/bin/dbeaver"
    local desktop_file="$HOME/.local/share/applications/dbeaver.desktop"
    local temp_dir="/tmp/dbeaver"
    local archive_path="$temp_dir/dbeaver.tar.gz"
    local download_url="https://dbeaver.io/files/dbeaver-ce-latest-linux.gtk.x86_64.tar.gz"

    # Check if already installed
    if [[ -d "$install_dir" && -x "$install_dir/dbeaver" ]]; then
        log_info "DBeaver already installed at $install_dir"
        return 0
    fi

    mkdir -p "$temp_dir"

    log_info "Downloading DBeaver Community..."
    if curl -L -o "$archive_path" "$download_url"; then
        # Remove previous install if exists
        superuser_do rm -rf "$install_dir"
        mkdir -p "$install_dir"

        tar -xzf "$archive_path" -C "$temp_dir"
        superuser_do mv "$temp_dir"/dbeaver/* "$install_dir"

        # Create symlink
        superuser_do ln -sf "$install_dir/dbeaver" "$bin_symlink"
        log_info "Created symlink: $bin_symlink → dbeaver"

        # Create .desktop launcher
        mkdir -p "$(dirname "$desktop_file")"
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=DBeaver Community
Exec=$install_dir/dbeaver
Icon=$install_dir/icon.xpm
Terminal=false
Categories=Development;Database;
StartupNotify=true
EOF

        chmod +x "$desktop_file"
        log_success "DBeaver Community installed successfully and launcher created"
    else
        log_failed "Failed to download DBeaver"
        return 1
    fi

    # Clean temp
    rm -rf "$temp_dir"
}
