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
    git config --global diff.tool vimdiff
    git config --global merge.tool vimdiff

    # Set up Git aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.visual '!gitk'
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

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
# Zsh Configuration

# History settings
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt AUTO_CD
setopt CORRECT

# Load aliases and functions
[ -f ~/.bash_aliases ] && source ~/.bash_aliases
[ -f ~/.bash_functions ] && source ~/.bash_functions

# Enable plugins
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fpath+=(~/.zsh/plugins/zsh-completions/src)
autoload -Uz compinit && compinit

# Starship prompt
eval "$(starship init zsh)"
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

    # Function to write ssh-agent startup logic
    write_ssh_agent_bootstrap() {
        cat <<'EOF'

# SSH agent setup (compatible with tmux and multiple shells)
SSH_ENV="$HOME/.ssh/agent.env"

start_agent() {
    echo "Initializing new SSH agent..."
    /usr/bin/ssh-agent -s | sed 's/^echo/#echo/' > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" > /dev/null
    ssh-add ~/.ssh/*_rsa ~/.ssh/id_ed25519 ~/.ssh/*.key 2>/dev/null
}

load_agent() {
    if [ -f "$SSH_ENV" ]; then
        source "$SSH_ENV" > /dev/null
        if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            start_agent
        fi
    else
        start_agent
    fi
}

# Only run once per real session (not every tmux pane)
if [ -z "$TMUX" ] || [ -z "$SSH_AUTH_SOCK" ]; then
    load_agent
fi
export SSH_AUTH_SOCK
EOF
    }

    # Add SSH agent to bash and zsh config
    for shell_file in "$bashrc_file" "$zshrc_file"; do
        if [[ -f "$shell_file" && ! $(grep "SSH agent setup" "$shell_file") ]]; then
            write_ssh_agent_bootstrap >> "$shell_file"
            log_success "Added ssh-agent bootstrap to $shell_file"
        fi
    done

    # Load agent into current session
    if [ -f "$ssh_env_file" ]; then
        source "$ssh_env_file" > /dev/null
        if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            eval "$(ssh-agent -s)" >/dev/null
            ssh-add ~/.ssh/*_rsa ~/.ssh/id_ed25519 ~/.ssh/*.key 2>/dev/null
        fi
    else
        eval "$(ssh-agent -s)" >/dev/null
        ssh-add ~/.ssh/*_rsa ~/.ssh/id_ed25519 ~/.ssh/*.key 2>/dev/null
    fi

    log_success "SSH agent configured with support for bash, zsh, and tmux"
}

# Configure automatic updates
configure_automatic_updates() {
    if ask_yes_no "Enable automatic security updates?" "y"; then
        install_dnf_package "dnf-automatic" "DNF Automatic"

        # Configure dnf-automatic
        local auto_config="/etc/dnf/automatic.conf"
        if [ -f "$auto_config" ]; then
            superuser_do sed -i 's/apply_updates = no/apply_updates = yes/' "$auto_config"
            superuser_do sed -i 's/upgrade_type = default/upgrade_type = security/' "$auto_config"

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

    cp -r "$HOME/Pictures/"* "$HOME/Documents/resources/pictures/"
    rm -rf "$HOME/Pictures" && ln -s "$HOME/Documents/resources/pictures" "$HOME/Pictures"

    # Configure development tools
    configure_vim
    configure_development_aliases

    log_success "Development and folders environment configured"
}

# Configure Vim
configure_vim() {
    log_info "Configuring Vim..."

    local vimrc="$HOME/.vimrc"

    if [ ! -f "$vimrc" ]; then
        cat > "$vimrc" << 'EOF'
" Bootora Vim configuration
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
set ruler
set wildmenu
set wildmode=longest,list,full
set backspace=indent,eol,start
set encoding=utf-8
set fileencoding=utf-8
set laststatus=2
set cursorline
set mouse=a

" Enable syntax highlighting
syntax on
filetype on
filetype plugin on
filetype indent on

" Color scheme
colorscheme desert

" Key mappings
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
nnoremap <F3> :set invnumber<CR>
nnoremap <F4> :set invrelativenumber<CR>

" Save with Ctrl+S
nnoremap <C-s> :write<CR>
inoremap <C-s> <Esc>:write<CR>a

" Auto-save when focus is lost
au FocusLost * :wa

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
EOF
        log_success "Vim configured"
    else
        log_info "Vim already configured"
    fi
}

# Configure development aliases
configure_development_aliases() {
    log_info "Setting up development aliases..."

    local dev_aliases="$HOME/.dev_aliases"

    if [ ! -f "$dev_aliases" ]; then
        cat > "$dev_aliases" << 'EOF'
# General
alias h="history"
alias open='xdg-open'
alias :q=exit

# Development aliases
alias py='python3'
alias pip='pip3'
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
alias urldecode='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'

# Git aliases
alias g="git"
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git rebase'
alias gf='git fetch'
alias gpl='git pull'

# Docker aliases
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dclogs='docker-compose logs -f'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# System aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'
alias mkdir='mkdir -pv'
alias rmdir='rmdir -v'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias ln='ln -iv'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias chgrp='chgrp --preserve-root'

# Package management
alias dnfi='sudo dnf install'
alias dnfs='dnf search'
alias dnfu='sudo dnf update'
alias dnfr='sudo dnf remove'
alias dnfh='dnf history'
alias dnfc='sudo dnf clean all'

# Flatpak aliases
alias fpi='flatpak install'
alias fps='flatpak search'
alias fpu='flatpak update'
alias fpr='flatpak uninstall'
alias fpl='flatpak list'

# Development servers
alias nodeserver='npx http-server -p 8000'
alias reactdev='npm start'
alias vuedev='npm run serve'

# Text processing
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# System monitoring
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
alias cpuinfo='lscpu'
alias gpumeminfo='grep -Ei --color "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" /proc/meminfo'

# Disk usage
alias du='du -kh'
alias df='df -h'
alias dus='du -sh * | sort -hr'

# Archive operations
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Date and time
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'
alias nowtime='date +"%d-%m-%Y %T"'

# Network aliases
alias ports='ss -tulanp'
alias listening='ss -tln'
alias ping='ping -c 5'
alias wget='wget -c'
alias curl='curl -L'
alias flush="dscacheutil -flushcache"
alias ips="ip -o addr show | awk '{if (\$3 == \"inet\") {print \$2 \": \" \$4 \" (IPv4)\"} else {print \$2 \": \" \$4 \" (IPv6)\"}}' | sed 's/\/[0-9]*//'"
alias weather='curl wttr.in'
alias pubip="curl -s https://checkip.amazonaws.com"
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

# Quick edits
alias bashrc='$EDITOR ~/.bashrc'
alias zshrc='$EDITOR ~/.zshrc'
alias vimrc='$EDITOR ~/.vimrc'
alias hosts='sudo $EDITOR /etc/hosts'

# copy working directory
alias cwd='pwd | tr -d "\r\n" | xclip -selection clipboard'

# Pipe my public key to my clipboard.
alias pubkey="more ~/.ssh/id_ed25519.pub | xclip -selection clipboard | echo '=> Public key copied to pasteboard.'"
EOF

        # Source dev aliases in shell profiles
        if [ -f "$HOME/.bashrc" ] && ! grep -q "dev_aliases" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Load development aliases" >> "$HOME/.bashrc"
            echo "[ -f ~/.dev_aliases ] && source ~/.dev_aliases" >> "$HOME/.bashrc"
        fi

        if [ -f "$HOME/.zshrc" ] && ! grep -q "dev_aliases" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Load development aliases" >> "$HOME/.zshrc"
            echo "[ -f ~/.dev_aliases ] && source ~/.dev_aliases" >> "$HOME/.zshrc"
        fi

        log_success "Development aliases configured"
    else
        log_info "Development aliases already configured"
    fi
}

# Setup shell enhancements
setup_shell_enhancements() {
    log_info "Setting up shell enhancements..."

    enable_nano_syntax_highlighting

    # Create useful functions
    create_shell_functions

    # Configure shell completion
    configure_shell_completion

    # Set up directory bookmarks
    setup_directory_bookmarks

    log_success "Shell enhancements configured"
}

# Create shell functions
create_shell_functions() {
    local functions_file="$HOME/.bash_functions"

    if [ ! -f "$functions_file" ]; then
        cat > "$functions_file" << 'EOF'
#!/bin/bash
# Bootora shell functions

# Extract function for various archive formats
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        unxz "$1"        ;;
            *.exe)       cabextract "$1"  ;;
            *)           echo "'$1': unrecognized file compression" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create directory and cd into it
mkd() {
    mkdir -p "$1" && cd "$1"
}

# Make a temporary directory and enter it
function td() {
	local dir
	if [ $# -eq 0 ]; then
		dir=$(mktemp -d)
	else
		dir=$(mktemp -d -t "${1}.XXXXXXXXXX")
	fi
	cd "$dir" || exit
}

# Create a data URL from a file
function dataurl() {
	local mimeType=$(file -b --mime-type "$1");
	if [[ $mimeType == text/* ]]; then
		mimeType="${mimeType};charset=utf-8";
	fi
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')";
}

function shorturl() {
    if [ -z "$1" ]; then
        echo "Use: shorturl <URL>"
        return 1
    fi

    local shortened_url=$(curl -s "https://tinyurl.com/api-create.php?url=${1}")

    if [ $? -eq 0 ]; then
        echo "URL Shortened: $shortened_url"

        # Copia para o clipboard
        if command -v xclip &> /dev/null; then
            echo -n "$shortened_url" | xclip -selection clipboard
            echo "Shortened URL copied to clipboard."
        elif command -v pbcopy &> /dev/null; then
            echo -n "$shortened_url" | pbcopy
            echo "Shortened URL copied to clipboard."
        else
            echo "Shortened URL, but could not copy to clipboard. Install xclip or pbcopy."
        fi
    else
        echo "Error shortening the URL on the https://tinyurl.com service."
        return 1
    fi
}

# Find and kill process by name
kp() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Quick backup function
bkp() {
    cp "$1" "${1}.backup.$(date +%Y%m%d_%H%M%S)"
}

# Find large files
fl() {
    find . -type f -size +${1:-100M} -exec ls -lh {} \; | awk '{ print $9 ": " $5 }'
}

# Git functions
gitignore() {
    curl -sLw "\n" "https://www.gitignore.io/api/$1"
}

# Docker functions
dockerclean() {
    docker system prune -af
    docker volume prune -f
}

dockerstop() {
    docker stop $(docker ps -aq)
}

dockerrm() {
    docker rm $(docker ps -aq)
}

# Network functions
port() {
    ss -tulpn | grep ":$1"
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified.";
		return 1;
	fi;

	local domain="${1}";
	echo "Testing ${domain}…";
	echo ""; # newline

	local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
			no_serial, no_sigdump, no_signame, no_validity, no_version");
		echo "Common Name:";
		echo ""; # newline
		echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
		echo ""; # newline
		echo "Subject Alternative Name(s):";
		echo ""; # newline
		echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
			| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
		return 0;
	else
		echo "ERROR: Certificate not found.";
		return 1;
	fi;
}

# UTF-8-encode a string of Unicode symbols
function uniencode() {
	local args
	mapfile -t args < <(printf "%s" "$*" | xxd -p -c1 -u)
	printf "\\\\x%s" "${args[@]}"
	# print a newline unless we’re piping the output to another program
	if [ -t 1 ]; then
		echo ""; # newline
	fi
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
	perl -e "binmode(STDOUT, ':utf8'); print \"$*\""
	# print a newline unless we’re piping the output to another program
	if [ -t 1 ]; then
		echo ""; # newline
	fi
}

# `treel` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function treel() {
	tree -aC -I '.git|node_modules' --dirsfirst "$@" | less -FRNX;
}

# Check if uri is up
function isup() {
	local uri=$1

	if curl -s --head --request GET "$uri" | grep "200 OK" > /dev/null; then
		notify-send --urgency=low "All Ok! $uri is up"
	else
		notify-send --urgency=critical "Critical! $uri is down"
	fi
}

# Copy w/ progress
function cpr () {
  rsync -WavP --human-readable --progress $1 $2
}

# take this repo and copy it to somewhere else minus the .git stuff.
function gitexport(){
	local branch="${2:-main}";
	mkdir -p "$1"
	git archive "$branch" | tar -x -C "$1"
}

# System info function
sysinfo() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
    echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
}

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		xdg-open . > /dev/null 2>&1;
	else
		xdg-open "$@" > /dev/null 2>&1;
	fi;
}

# Development functions

# Start an HTTP server from a directory, optionally specifying the port
function server() {
	local port="${1:-8000}";
    local directory_publish="."
    if [ ! -z "${2}" ]; then
        directory_publish=${2}
    fi
	python3 -m http.server ${port} --bind 0.0.0.0 --directory ${directory_publish}
}

jsonformat() {
    if [ -n "$1" ] && [ -f "$1" ]; then
        python3 -m json.tool "$1"
    else
        echo "$@" | python3 -m json.tool
    fi
}

# Quick note function
note() {
    echo "$(date): $*" >> "$HOME/Documents/notes.txt"
}

viewnotes() {
    cat "$HOME/Documents/notes.txt"
}

# Project initialization
# Initialize a project in ~/Develop/personal or ~/Develop/work
initproject() {
    local type="personal"
    local name=""

    case "$1" in
        --p) type="personal"; name="$2" ;;
        --w) type="work"; name="$2" ;;
        *)   name="$1" ;;  # Default to personal
    esac

    if [ -z "$name" ]; then
        echo "Usage: initproject [--p|--w] <project-name>"
        return 1
    fi

    local base_dir="$HOME/Develop/$type"
    local project_dir="$base_dir/$name"

    mkdir -p "$project_dir"
    cd "$project_dir" || return 1

    git init
    echo "# $name" > README.md
    echo "Project '$name' initialized in '$project_dir' (type: $type)"
}

######## AWS

# Get currently logged in aws account name
function awsaccount() {
  aws iam list-account-aliases | jq ".AccountAliases[0]" -r
}

# List all clusters for the current role
function awslistclusters() {
  aws ecs list-clusters | jq -r '.clusterArns|map((./"/")[1])|.[]'
}

# List all services for the specified cluster
function awslistservices() {
  aws ecs list-services --cluster $1 | jq -r '.serviceArns|map((./"/")[1])|.[]'
}

# List all services by cluster for the current role
function awslistservicesbycluster() {
  local clusters services
  clusters=($(awslistclusters))
  for c in "${clusters[@]}"; do
    services=($(awslistservices $c))
    for s in "${services[@]}"; do
      echo "$c $s"
    done
    [[ ${#services[@]} > 0 ]] && echo
  done
}

# List all aws tasks for the given cluster and service
function awslisttasks() {
  aws ecs list-tasks --cluster $1 --service-name $2 \
    | jq -r '.taskArns|map((./"/")[1])|.[]'
}

# List task definitions for all running tasks for the given cluster and service
function awslisttaskdefinitions() {
  local t=$(aws ecs describe-tasks --cluster $1 --tasks $(awslisttasks $1 $2))
  echo $t | jq -r '.tasks|map((.taskDefinitionArn/"/")[1])|.[]'
}

# Return the current task definition for the given cluster and service
function awstaskdefinition() {
  local tds
  if [[ "$1" =~ : ]]; then
    tds=($1)
  else
    tds=($(awslisttaskdefinitions $1 $2 | uniq))
    shift
  fi
  shift
  for td in "${tds[@]}"; do
    aws ecs describe-task-definition --task-definition $td | jq "$@"
  done
}

# List all diffs over time for a given task definition env vars
function awstaskdefinitionenvhistory() {
  local cur=$2 max=$3 next diff a b
  [[ ! "$cur" ]] && cur=0
  [[ ! "$max" ]] && max=9999
  if [[ $(($cur+1-1)) != "$cur" || $(($max+1-1)) != "$max" ]]; then
    echo "Usage: aws-task-definition-env-history td-name [start-rev] [end-rev]"
    return 1
  fi
  while [[ $cur != $max ]]; do
    next=$((cur+1))
    b=$(awstaskdefinitionenv $1:$next 2>/dev/null | sort)
    if [[ ! "$b" ]]; then
      echo "No more revisions."
      return
    fi
    a=
    if [[ $cur != 0 ]]; then
      echo -ne "\rComparing revisions $cur and $next..." 1>&2
      a=$(awstaskdefinitionenv $1:$cur 2>/dev/null | sort)
    fi
    diff=$(diff <(echo "$a") <(echo "$b"))
    if [[ "$diff" ]]; then
      echo -ne '\r' 1>&2
      if [[ $cur == 0 ]]; then
        echo "Initial values"
      else
        echo "Differences between revisions $cur and $next"
      fi
      echo "-------------------------------------------"
      echo "$diff"
      echo "==========================================="
    fi
    cur=$((cur+1))
  done
}

# Print out VAR=VALUE lines for env of the current task definition for the given
# cluster and service
function awstaskdefinitionenv() {
  awstaskdefinition "$@" \
    -r '.taskDefinition.containerDefinitions[0].environment|map(.name+"="+.value)|.[]'
}

# Stop all aws tasks for the given cluster and service
function awsstoptasks() {
  local tasks count cluster pad s t
  cluster=$1; shift
  for s in "$@"; do
    [[ "$pad" ]] && echo; pad=1
    echo "Finding tasks for service <$s> on cluster <$cluster>"
    tasks=($(awslisttasks $cluster $s))
    count=${#tasks[@]}
    if [[ $count == 0 ]]; then
      echo "No tasks found, skipping"
      continue
    fi
    echo "${#tasks[@]} task(s) found"
    for t in "${tasks[@]}"; do
      echo "Stopping task $t"
      aws ecs stop-task --cluster $cluster --task $t --query 'task.stoppedReason' --output=text
    done
  done
}
EOF

        # Source functions in shell profiles
        if [ -f "$HOME/.bashrc" ] && ! grep -q "bash_functions" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Load custom functions" >> "$HOME/.bashrc"
            echo "[ -f ~/.bash_functions ] && source ~/.bash_functions" >> "$HOME/.bashrc"
        fi

        if [ -f "$HOME/.zshrc" ] && ! grep -q "bash_functions" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Load custom functions" >> "$HOME/.zshrc"
            echo "[ -f ~/.bash_functions ] && source ~/.bash_functions" >> "$HOME/.zshrc"
        fi

        log_success "Shell functions created"
    else
        log_info "Shell functions already exist"
    fi
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