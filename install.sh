#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== 0xUri3l's Dotfiles Installation ===${NC}\n"

# Check if running on a Debian-based system
if ! command -v apt &> /dev/null; then
    echo -e "${RED}✗ This script is designed for Debian-based systems (Ubuntu, Debian, etc.)${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Update system
echo -e "${YELLOW}→ Updating system...${NC}"
sudo apt update

# Install prerequisites
echo -e "\n${YELLOW}→ Installing prerequisites...${NC}"

# Install lsd (better ls)
if ! command_exists lsd; then
    echo "  Installing lsd..."
    sudo apt install -y lsd
else
    echo "  ✓ lsd already installed"
fi

# Install batcat (better cat)
if ! command_exists batcat; then
    echo "  Installing bat..."
    sudo apt install -y bat
else
    echo "  ✓ bat already installed"
fi

# Install fastfetch (system info)
if ! command_exists fastfetch; then
    echo "  Installing fastfetch..."
    sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y
    sudo apt update
    sudo apt install -y fastfetch
else
    echo "  ✓ fastfetch already installed"
fi

# Install Iosevka Nerd Font
echo -e "\n${YELLOW}→ Installing Iosevka Nerd Font...${NC}"
if [ ! -d "$HOME/.local/share/fonts/Iosevka" ]; then
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts
    wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip
    unzip -q Iosevka.zip -d Iosevka
    rm Iosevka.zip
    fc-cache -fv > /dev/null 2>&1
    cd - > /dev/null
    echo "  ✓ Iosevka Nerd Font installed"
else
    echo "  ✓ Iosevka Nerd Font already installed"
fi

# Install Oh My ZSH if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "\n${YELLOW}→ Installing Oh My ZSH...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "\n${GREEN}✓ Oh My ZSH already installed${NC}"
fi

# Copy dotfiles
echo -e "\n${YELLOW}→ Installing dotfiles...${NC}"

# Kitty config
echo "  Copying Kitty configuration..."
mkdir -p ~/.config/kitty
cp Kitty/kitty.conf ~/.config/kitty/
echo "  ✓ Kitty config installed"

# ZSH theme
echo "  Copying ZSH theme..."
cp theme/0xUri3l.zsh-theme ~/.oh-my-zsh/custom/themes/
echo "  ✓ ZSH theme installed (set ZSH_THEME=\"0xUri3l\" in ~/.zshrc)"

# ZSH aliases
echo "  Copying ZSH aliases..."
cp zshrc/.zsh_aliases ~/
echo "  ✓ Aliases installed"

# Add aliases to .zshrc if not already present
if ! grep -q "source ~/.zsh_aliases" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# Load custom aliases" >> ~/.zshrc
    echo "if [ -f ~/.zsh_aliases ]; then" >> ~/.zshrc
    echo "    source ~/.zsh_aliases" >> ~/.zshrc
    echo "fi" >> ~/.zshrc
fi

# Fastfetch config
echo "  Configuring fastfetch..."
mkdir -p ~/.config/fastfetch
cp /usr/share/fastfetch/presets/examples/13.jsonc ~/.config/fastfetch/config.jsonc 2>/dev/null || echo "  ! Fastfetch example config not found, using default"
echo "  ✓ Fastfetch configured (using examples/13.jsonc theme)"

# Wallpaper
echo "  Copying wallpaper..."
mkdir -p ~/Pictures/Walls
cp Wallpapers/wallhaven-e76pew.png ~/Pictures/Walls/
echo "  ✓ Wallpaper copied to ~/Pictures/Walls/"

# SDDM Theme (requires sudo)
echo -e "\n${YELLOW}→ SDDM Theme (SilentSDDM)${NC}"
read -p "Do you want to install SilentSDDM theme? (requires sudo) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ ! -d "/tmp/SilentSDDM" ]; then
        cd /tmp
        git clone https://github.com/uiriansan/SilentSDDM.git
        sudo cp -r SilentSDDM /usr/share/sddm/themes/
        rm -rf SilentSDDM
        cd - > /dev/null
        echo -e "${GREEN}✓ SilentSDDM installed to /usr/share/sddm/themes/${NC}"
        echo -e "${YELLOW}  Don't forget to set Current=SilentSDDM in /etc/sddm.conf under [Theme]${NC}"
    else
        echo "  ✓ SilentSDDM already exists"
    fi
fi

echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "  1. Set ZSH_THEME=\"0xUri3l\" in your ~/.zshrc"
echo "  2. Reload your shell: source ~/.zshrc"
echo "  3. Configure SDDM theme in /etc/sddm.conf (if installed)"
echo "  4. Set the wallpaper from ~/Pictures/Walls/wallhaven-e76pew.png"
echo -e "\n${GREEN}Enjoy your new setup! 🚀${NC}"
