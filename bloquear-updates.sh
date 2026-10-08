#!/bin/bash

# Cores para o output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando o bloqueio de atualizações automáticas do macOS...${NC}"

# 1. Desativa a verificação automática de atualizações
echo -e "Desativando a verificação automática de atualizações..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false

# 2. Desativa o download automático de atualizações em segundo plano
echo -e "Desativando o download automático de atualizações..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false

# 3. Desativa a instalação automática de atualizações do macOS
echo -e "Desativando a instalação automática de atualizações do macOS..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false

# 4. Desativa a instalação automática de atualizações críticas e de arquivos de configuração
echo -e "Desativando a instalação de atualizações críticas e de configuração..."
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false

# 5. Desativa o agendamento do softwareupdate (comando legado, mas ainda útil)
echo -e "Desativando o agendamento do softwareupdate..."
sudo softwareupdate --schedule off

# 6. Remove o selo de notificação (badge) do ícone de Ajustes do Sistema
echo -e "Removendo o selo de notificação do ícone de Ajustes..."
defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
killall Dock

echo -e "${GREEN}✓ Bloqueio de atualizações automáticas concluído com sucesso!${NC}"
echo -e "${YELLOW}Você ainda poderá verificar manualmente por atualizações em Ajustes > Geral > Atualização de Software.${NC}"