# Bootora - Fedora Post-Install System

Um sistema completo e modular para automatizar a instalação e configuração pós-instalação do Fedora Linux. O Bootora configura seu sistema com todas as ferramentas essenciais para desenvolvimento, multimídia e produtividade.

## 🚀 Instalação Rápida

Execute este comando para instalar o Bootora:

```bash
curl -fsSL https://raw.githubusercontent.com/lucasbt/bootora/main/boot.sh | bash
```

Após a instalação, execute:

```bash
bootora install
```

## O que o Bootora instala...

### Sistema Base
- Atualização completa do sistema
- Repositórios RPM Fusion e Flathub
- Configurações otimizadas do DNF
- Ferramentas essenciais de sistema

### Pacotes Essenciais
- **Editores**: vim, neovim, Visual Studio Code
- **Ferramentas de Sistema**: htop, btop, tree, fzf, bat, ripgrep
- **Compressão**: zip, unzip, 7zip, rar
- **Rede**: curl, wget, nmap, telnet
- **Fontes**: Fira Code, Roboto, Noto

### Multimídia
- **Players**: VLC, Rhythmbox
- **Codecs**: FFmpeg, GStreamer plugins, codecs proprietários

### Desenvolvimento
- **Linguagens**:
  - Java (via SDKMAN) - versões 17 e 21 LTS
  - Node.js (LTS) + npm, yarn, pnpm
  - Python 3 + pip, poetry, pipx
  - Go (última versão)
  - Rust (via rustup)
- **Ferramentas**: Docker, Podman, kubectl, Git
- **Build Tools**: gcc, make, cmake, Maven, Gradle
- **IDEs**: VS Code, IntelliJ

### Aplicativos Flatpak
- **Comunicação**: Discord, Telegram
- **Navegadores**: Chrome, Firefox
- **Produtividade**: LibreOffice, Obsidian
- **Música**: Spotify

### Configurações
- **Git**: Configuração com aliases úteis
- **Shell**: Bash/Zsh aprimorados com Starship
- **Aliases**: Mais de 100 aliases úteis para desenvolvimento
- **SSH**: Configuração otimizada do cliente

## 🎯 Uso

### Comandos Principais

```bash
# Instalação completa
bootora install

# Atualizar componentes instalados
bootora update

# Instalar módulo específico
bootora module development

# Ver status da instalação
bootora status

# Listar módulos disponíveis
bootora list

# Limpar cache
bootora clean

# Atualizar o próprio Bootora
bootora self-update

# Ajuda
bootora --help
```

### Módulos Disponíveis

| Módulo | Descrição |
|--------|-----------|
| `system` | Atualização do sistema e repositórios |
| `packages` | Pacotes base essenciais |
| `multimedia` | Ferramentas multimídia e codecs |
| `development` | Ferramentas de desenvolvimento |
| `flatpak` | Aplicações Flatpak |
| `configuration` | Configurações e tweaks do sistema |


## ✨ Características

### Modular e Reutilizável
- Execute módulos individuais conforme necessário
- Sistema de estado para tracking de instalações
- Atualizações incrementais

### Seguro e Confiável
- Verificações de sistema antes da instalação
- Backup automático de configurações
- Tratamento robusto de erros
- Sistema de lock para evitar execuções simultâneas

### Interface Amigável
- Output colorido e informativo
- Barra de progresso para operações longas
- Logs detalhados de todas as operações
- Prompts interativos quando necessário

### Configurável
- Listas de pacotes em arquivos separados
- Fácil adição de novos pacotes
- Configurações personalizáveis

## 🔧 Personalização

### Adicionando Pacotes

Para adicionar novos pacotes, edite os arquivos em `packages/`:

```bash
# Pacotes DNF
echo "nome-do-pacote" >> packages/packages.list

# Aplicações Flatpak
echo "com.exemplo.App" >> packages/flatpak.list
```

### Criando Módulos Personalizados

Crie um novo arquivo em `modules/` seguindo o padrão:

```bash
#!/bin/bash
# Novo módulo personalizado

execute_meumodulo_module() {
    log_subheader "Meu Módulo Personalizado"

    # Sua lógica aqui
    install_dnf_package "meu-pacote" "Meu Pacote"

    log_success "Módulo personalizado concluído"
    return 0
}
```

## 🐛 Solução de Problemas

### Problemas Comuns

**Erro de permissão**: Certifique-se de ter privilégios sudo
```bash
sudo usermod -aG wheel $USER
```

**Repositórios não encontrados**: Execute o módulo system primeiro
```bash
bootora module system
```

**Flatpak não funciona**: Verifique se o Flathub está configurado
```bash
flatpak remotes
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

### Diretrizes

- Mantenha a compatibilidade com Bash e Zsh
- Use as funções utilitárias em `lib/utils.sh`
- Adicione logs informativos
- Teste em diferentes versões do Fedora
- Documente novas funcionalidades

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- Comunidade Fedora pelo excelente sistema operacional
- Desenvolvedores de todas as ferramentas incluídas
- Contribuidores do projeto

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/lucasbt/bootora/issues)
- **Email**: [lucasbt@gmail.com](mailto:lucasbt@gmail.com)

---

**Bootora** - Transforme seu Fedora em uma estação de trabalho completa em minutos! 🚀