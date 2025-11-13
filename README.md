<div align="center">
   <img align="center" width="256" height="256" src="assets/bootora.png" />
	<h1 align="center"><b>Bootora</b></h1>
	<p align="center">
		<b>Opinionated Fedora Workstation Setup</b>
    <br />
  </p>
</div>

<br/>

A complete, modular system for automating the installation and post-installation configuration of Fedora Linux. Bootora configures your system with all the essential tools for development, multimedia, and productivity.

## 🚀 Quick Installation

Run this command to install Bootora:

```bash
curl -fsSL https://raw.githubusercontent.com/lucasbt/bootora/main/boot.sh | bash
```

After installation, run:

```bash
bootora install
```

## What Bootora installs...

### System
- Full system update
- Fusion and Flathub RPM repositories
- Optimized DNF settings
- Essential system tools

### Essential Packages
- **Editors**: vim, neovim, Visual Studio Code
- **System Tools**: htop, btop, tree, fzf, bat, ripgrep
- **Compression**: zip, unzip, 7zip, rar
- **Network**: curl, wget, nmap, telnet
- **Fonts**: Fira Code, Roboto, Noto

### Multimedia
- **Players**: VLC, Rhythmbox
- **Codecs**: FFmpeg, GStreamer plugins, proprietary codecs

### Development
- **Languages**:
- Java (via SDKMAN) - versions 17 and 21 LTS
- Node.js (LTS) + npm, yarn, pnpm
- Python 3 + pip, poetry, pipx
- Go (latest version)
- Rust (via rustup)
- **Tools**: Docker, Podman, kubectl, Git
- **Build Tools**: gcc, make, cmake, Maven, Gradle
- **IDEs**: VS Code, IntelliJ

### Flatpak Apps
- **Communication**: Discord, Telegram
- **Browsers**: Chrome, Firefox
- **Productivity**: LibreOffice, Obsidian
- **Music**: Spotify

### Settings
- **Git**: Configuration with useful aliases
- **Shell**: Enhanced Bash/Zsh with Starship
- **Aliases**: Over 100 useful aliases for development
- **SSH**: Optimized client configuration

## 🎯 Using

### Main Commands

```bash
# Complete installation
bootora install

# Update installed components
bootora update

# Install a specific module
bootora module development

# View installation status
bootora status

# List available modules
bootora list

# Clear cache
bootora clean

# Update Bootora itself
bootora self-update

# Help
bootora --help
```

### Available Modules

| Module | Description |
|--------|-----|
| `system` | System and repositories update |
| `packages` | Essential base packages |
| `multimedia` | Multimedia tools and codecs |
| `development` | Development tools |
| `flatpak` | Flatpak applications |
| `configuration` | System settings and tweaks |
| `fancy` | Some aesthetic elements |


## ✨ Features

### Modular and Reusable
- Run individual modules as needed
- Status system for tracking installations
- Incremental updates

### Secure and Reliable
- System checks before installation
- Automatic configuration backup
- Robust error handling
- Locking system to prevent concurrent executions

### User-Friendly Interface
- Colorful and informative output
- Progress bar for long operations
- Detailed logs of all operations
- Interactive prompts when needed

### Configurable
- Package lists in separate files
- Easy addition of new packages
- Customizable configurations

## 🔧 Customization

### Adding Packages

To add new packages, edit the files in `packages/`:

```bash
# DNF Packages
echo "package-name" >> packages/packages.list

# Flatpak Applications
echo "com.example.App" >> packages/flatpak.list
```

### Creating Custom Modules

Create a new file in `modules/` following the pattern:


```bash
#!/bin/bash
# New custom module

execute_mymodule_module() {
log_subheader "My Custom Module"

# Your logic here
install_dnf_package "my-package" "My Package"

log_success "Custom module completed"
return 0
}
```

## 🐛 Troubleshooting

### Common Problems

**Permission Error**: Make sure you have sudo privileges.
```bash
sudo usermod -aG wheel $USER
```

**Repositories not found**: Run the system module first.
```bash
bootora module system
```

**Flatpak not working**: Make sure Flathub is configured.
```bash
flatpak remotes
```

## 🤝 Contributing

1. Fork the project
2. Create a branch for your feature (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

### Guidelines

- Maintain compatibility with Bash and Zsh
- Use the utility functions in `lib/utils.sh`
- Add informative logs
- Test on different Fedora versions
- Document new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Fedora Community for the excellent operating system
- Developers of all included tools
- Project contributors

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/lucasbt/bootora/issues)
- **Email**: [lucasbt@gmail.com](mailto:lucasbt@gmail.com)

---

**Bootora** - Turn your Fedora into a complete workstation in minutes! 🚀