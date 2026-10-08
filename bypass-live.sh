#!/bin/bash

# ============================================================
# Bypass MDM - Versão para rodar DENTRO do sistema macOS
# Personalizado para Rosenilza
# ============================================================

RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

error_exit() { echo -e "${RED}ERRO: $1${NC}" >&2; exit 1; }
warn()       { echo -e "${YEL}AVISO: $1${NC}"; }
success()    { echo -e "${GRN}✓ $1${NC}"; }
info()       { echo -e "${BLU}ℹ $1${NC}"; }

# ============================================================
# DADOS FIXOS
# ============================================================
realName="Rosenilza"
username="roseleiras"
passw="1720"

# ============================================================
# Verificar se está rodando como root
# ============================================================
if [ "$(id -u)" -ne 0 ]; then
	error_exit "Este script precisa ser executado com sudo. Use: sudo $0"
fi

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Bypass MDM - Sistema em execução           ║${NC}"
echo -e "${CYAN}║  (Rosenilza / roseleiras / 1720)            ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# 1. Criar usuário admin (usando sysadminctl)
# ============================================================
info "Criando usuário administrador: $username"

if dscl . -read "/Users/$username" >/dev/null 2>&1; then
	warn "O usuário '$username' já existe no sistema"
	warn "Pulando criação. Se quiser recriar, apague-o antes:"
	warn "  sudo sysadminctl -deleteUser $username"
else
	if sysadminctl -addUser "$username" \
		-fullName "$realName" \
		-password "$passw" \
		-admin \
		-home "/Users/$username" 2>&1; then
		success "Usuário '$username' criado com sucesso"
	else
		error_exit "Falha ao criar o usuário '$username'"
	fi
fi

echo ""

# ============================================================
# 2. Bloquear domínios MDM no /etc/hosts
# ============================================================
info "Bloqueando domínios de inscrição MDM em /etc/hosts..."

HOSTS_FILE="/etc/hosts"

# Backup
cp "$HOSTS_FILE" "${HOSTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
success "Backup criado: ${HOSTS_FILE}.bak.*"

# Adiciona se não existir
grep -q "deviceenrollment.apple.com" "$HOSTS_FILE" 2>/dev/null || echo "0.0.0.0 deviceenrollment.apple.com" >>"$HOSTS_FILE"
grep -q "mdmenrollment.apple.com" "$HOSTS_FILE" 2>/dev/null || echo "0.0.0.0 mdmenrollment.apple.com" >>"$HOSTS_FILE"
grep -q "iprofiles.apple.com" "$HOSTS_FILE" 2>/dev/null || echo "0.0.0.0 iprofiles.apple.com" >>"$HOSTS_FILE"
grep -q "gdmf.apple.com" "$HOSTS_FILE" 2>/dev/null || echo "0.0.0.0 gdmf.apple.com" >>"$HOSTS_FILE"

success "Domínios MDM bloqueados em $HOSTS_FILE"
echo ""

# ============================================================
# 3. Limpar marcadores de configuração de nuvem
# ============================================================
info "Limpando marcadores de MDM..."

CONFIG_PATH="/var/db/ConfigurationProfiles/Settings"

if [ ! -d "$CONFIG_PATH" ]; then
	mkdir -p "$CONFIG_PATH" 2>/dev/null || warn "Não foi possível criar $CONFIG_PATH"
fi

rm -rf "$CONFIG_PATH/.cloudConfigHasActivationRecord" 2>/dev/null && success "Registro de ativação removido" || info "Sem registro de ativação"
rm -rf "$CONFIG_PATH/.cloudConfigRecordFound" 2>/dev/null && success "Registro de cloud config removido" || info "Sem registro de cloud config"

touch "$CONFIG_PATH/.cloudConfigProfileInstalled" 2>/dev/null && success "Marcador de perfil instalado criado" || warn "Não foi possível criar marcador"
touch "$CONFIG_PATH/.cloudConfigRecordNotFound" 2>/dev/null && success "Marcador de registro não encontrado criado" || warn "Não foi possível criar marcador"

echo ""

# ============================================================
# 4. Marcar setup como concluído (opcional)
# ============================================================
info "Marcando configuração como concluída..."
touch "/private/var/db/.AppleSetupDone" 2>/dev/null && success ".AppleSetupDone criado" || warn "Não foi possível criar .AppleSetupDone"

echo ""
echo -e "${GRN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GRN}║       Bypass MDM Concluído com Sucesso!      ║${NC}"
echo -e "${GRN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Próximos passos:${NC}"
echo -e "  1. Reinicie o Mac"
echo -e "  2. Faça login com:"
echo -e "     Usuário: ${YEL}$username${NC}"
echo -e "     Senha:   ${YEL}$passw${NC}"
echo ""