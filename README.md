# Dotfiles

Este repositório contém os meus arquivos de configuração pessoais (dotfiles) para o ambiente de desenvolvimento, bem como o script de instalação automatizada. Ele foi projetado para configurar a máquina (ou contêiner) com as ferramentas essenciais de que preciso, sendo ideal para uso local ou integrado com containers do **DevPod**.

## 🎯 Propósito do Projeto

O objetivo principal deste repositório é padronizar e automatizar a criação do meu ambiente de desenvolvimento. Através de um único script (`install`), eu consigo configurar rapidamente todos os pacotes, temas, extensões e configurações de terminal necessários para trabalhar de forma produtiva, independentemente de criar um novo ambiente localmente ou via DevPod.

### Principais Ferramentas Incluídas:

- **Zsh** (com Oh My Zsh, Powerlevel10k e zsh-artisan)
- **Tmux** e **Tmuxinator**
- **Neovim** (Configurações customizadas)
- **Lazygit** & **Lazydocker**
- **Opencode** (com plugin Gemini OAuth)
- Utilitários e Compiladores: `ripgrep`, `fd`, `jq`, `curl`, `ruby`, `rustc`, `gcc`, `make`

## 🚀 Como Instalar e Utilizar

### 1. Utilizando com o DevPod (Recomendado)

O [DevPod](https://devpod.sh/) pode utilizar este repositório automaticamente ao inicializar um novo workspace em qualquer infraestrutura.

Para que isso funcione, você deve ter o DevPod instalado no seu sistema hospedeiro (host):

- **Windows / macOS**: Baixe e instale via [site oficial do DevPod](https://devpod.sh/) ou através do seu gerenciador de pacotes de preferência (ex: `brew install devpod` no macOS ou `winget install sh.devpod` no Windows).
- **Linux**: Pode ser instalado através do script fornecido na documentação do DevPod.

**Configuração do Dotfiles no DevPod:**

1. Abra a interface do DevPod.
2. Vá nas configurações globais (Settings) -> **Dotfiles**.
3. Adicione a URL Git deste repositório no campo apropriado.
   O DevPod clonará automaticamente este repositório durante a criação do workspace e executará o script `install` para provisionar todo o ambiente.

### 2. Instalação Manual

Se você quiser instalar as configurações diretamente em um SO baseado em Linux (são suportadas distribuições que utilizam `apt`, `dnf`, `pacman` ou `zypper`):

```bash
# 1. Clone o repositório
git clone https://github.com/owrasor/dotfiles.git ~/.dotfiles

# 2. Acesse a pasta
cd ~/.dotfiles

# 3. Execute o script de instalação
./install
```

O script detectará automaticamente o seu gerenciador de pacotes e providenciará a instalação limpa de todas as dependências, criação de atalhos (symlinks) e fará a troca para que o Zsh atue como terminal padrão.

## 🔑 Configuração do Intelephense

A licença do Intelephense (usada para funcionalidades avançadas em projetos PHP no Neovim) pode ser configurada de forma automática pelo script de instalação.

Para configurar a sua chave de usuário, você tem duas opções:

### Opção 1: Antes da Instalação (Automático)

1. Crie um arquivo chamado `intelephense.txt` na raiz deste repositório de dotfiles.
2. Cole a sua chave de licença dentro deste arquivo.
3. Execute o script de instalação (`./install`). O arquivo será copiado automaticamente para o local correto no seu sistema (`~/intelephense/license.txt`).

### Opção 2: Após a Instalação (Manual)

Caso você já tenha rodado a instalação, insira sua chave criando (ou editando) o arquivo `license.txt` diretamente no diretório do seu usuário:

```bash
mkdir -p ~/intelephense
echo "SUA_CHAVE_AQUI" > ~/intelephense/license.txt
```

## 📂 Estrutura do Repositório

- `/install` - O script principal que analisa o SO, realiza instalações cross-distro e cria symlinks.
- `/zsh` - Configurações detalhadas do Zsh (`zshrc`).
- `/tmux` - Configurações do Tmux (`tmux.conf`).
- `/tmuxinator` - Modelos e automações de sessões para o Tmuxinator.
- `/nvim` - Configurações e plugins para a IDE baseada no Neovim.
- `/scripts` - Scripts auxiliares diversos.
- `/ghostty`, `/alacritty`, `/wezterm` - Configurações para diferentes emuladores de terminal.
