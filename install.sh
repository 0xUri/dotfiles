#!/bin/bash
cp zsh/.zsh_aliases ~/.zsh_aliases
cp kitty/kitty.conf ~/.config/kitty/
cp theme/mon-theme.zsh-theme ~/.config/zsh/themes/

source ~/.zshrc
echo "✓ Dotfiles installed!"
