#!/bin/bash

# ============================================================
# Remove o usuário Apple do macOS
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

# Nome do usuário a remover
TARGET_USER="Apple"

# ============================================================
# Verificações iniciais
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
	error_exit "Este script precisa ser executado com sudo. Use: sudo $0"
fi

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Remover usuário Apple do macOS            ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Não permite remover o usuário logado no momento
CURRENT_USER=$(stat -f "%Su" /dev/console)
if [ "$CURRENT_USER" = "$TARGET_USER" ]; then
	error_exit "Você está logado como '$TARGET_USER'. Faça login com outro admin antes de rodar este script."
fi

# Confirma que o usuário existe
if ! dscl . -read "/Users/$TARGET_USER" >/dev/null 2>&1; then
	warn "O usuário '$TARGET_USER' não existe no sistema. Nada a fazer."
	exit 0
fi

success "Usuário '$TARGET_USER' encontrado"

# Mostra os admins atuais para conferência
echo ""
info "Administradores atuais do sistema:"
dscl . -read /Groups/admin GroupMembership 2>/dev/null | sed 's/^/    /'
echo ""

# Confirma que há pelo menos outro admin além do Apple
ADMIN_COUNT=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | tr ' ' '\n' | grep -v "^GroupMembership:" | grep -v "^$" | grep -v "^$TARGET_USER$" | wc -l | tr -d ' ')

if [ "$ADMIN_COUNT" -lt 1 ]; then
	error_exit "Não há outro administrador além do '$TARGET_USER'. Crie um admin antes de remover, ou você perderá o acesso ao sudo."
fi

success "Existem $ADMIN_COUNT outro(s) admin(s). Seguro para continuar."
echo ""

# ============================================================
# Confirmação
# ============================================================
echo -e "${YEL}Você está prestes a REMOVER o usuário '$TARGET_USER' e sua pasta home.${NC}"
read -p "Digite 'SIM' para confirmar: " resposta

if [ "$resposta" != "SIM" ]; then
	warn "Cancelado pelo usuário."
	exit 0
fi

echo ""

# ============================================================
# Remover o usuário
# ============================================================
info "Removendo conta '$TARGET_USER'..."

if sysadminctl -deleteUser "$TARGET_USER" 2>&1; then
	success "Conta '$TARGET_USER' removida"
else
	warn "sysadminctl falhou, tentando dscl..."

	dscl . -delete "/Users/$TARGET_USER" 2>/dev/null \
		&& success "Conta removida via dscl" \
		|| error_exit "Falha ao remover a conta '$TARGET_USER'"
fi

# ============================================================
# Remover pasta home
# ============================================================
HOME_DIR="/Users/$TARGET_USER"

if [ -d "$HOME_DIR" ]; then
	info "Removendo pasta home: $HOME_DIR"
	rm -rf "$HOME_DIR" 2>/dev/null \
		&& success "Pasta home removida" \
		|| warn "Não foi possível remover a pasta home (talvez ela não exista ou esteja em uso)"
else
	info "Pasta home não encontrada: $HOME_DIR (nada a remover)"
fi

# ============================================================
# Verificação final
# ============================================================
echo ""
info "Verificando se o usuário ainda existe..."

if dscl . -read "/Users/$TARGET_USER" >/dev/null 2>&1; then
	error_exit "O usuário '$TARGET_USER' ainda existe. Remova manualmente."
else
	success "Usuário '$TARGET_USER' foi removido com sucesso"
fi

echo ""
echo -e "${GRN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GRN}║       Remoção concluída com sucesso!         ║${NC}"
echo -e "${GRN}╚═══════════════════════════════════════════════╝${NC}"
echo ""