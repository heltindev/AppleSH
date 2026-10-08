#!/bin/bash

# Cores
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Tratamento de erro
error_exit() {
	echo -e "${RED}ERRO: $1${NC}" >&2
	exit 1
}

# Aviso
warn() {
	echo -e "${YEL}AVISO: $1${NC}"
}

# Sucesso
success() {
	echo -e "${GRN}✓ $1${NC}"
}

# Informação
info() {
	echo -e "${BLU}ℹ $1${NC}"
}

# Validação de nome de usuário
validate_username() {
	local username="$1"

	if [ -z "$username" ]; then
		echo "O nome de usuário não pode estar vazio"
		return 1
	fi

	if [ ${#username} -gt 31 ]; then
		echo "Nome de usuário muito longo (máximo 31 caracteres)"
		return 1
	fi

	if ! [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		echo "O nome de usuário só pode conter letras, números, underline e hífen"
		return 1
	fi

	if ! [[ "$username" =~ ^[a-zA-Z_] ]]; then
		echo "O nome de usuário deve começar com uma letra ou underline"
		return 1
	fi

	return 0
}

# Validação de senha
validate_password() {
	local password="$1"

	if [ -z "$password" ]; then
		echo "A senha não pode estar vazia"
		return 1
	fi

	if [ ${#password} -lt 4 ]; then
		echo "Senha muito curta (mínimo 4 caracteres recomendado)"
		return 1
	fi

	return 0
}

# Verifica se o usuário já existe
check_user_exists() {
	local dscl_path="$1"
	local username="$2"

	if dscl -f "$dscl_path" localhost -read "/Local/Default/Users/$username" 2>/dev/null; then
		return 0
	else
		return 1
	fi
}

# Encontra UID disponível
find_available_uid() {
	local dscl_path="$1"
	local uid=501

	while [ $uid -lt 600 ]; do
		if ! dscl -f "$dscl_path" localhost -search /Local/Default/Users UniqueID $uid 2>/dev/null | grep -q "UniqueID"; then
			echo $uid
			return 0
		fi
		uid=$((uid + 1))
	done

	echo "501"
	return 1
}

# ============================================================
# VOLUMES FIXOS PARA macOS EM PORTUGUÊS
# ============================================================
system_volume="MacBook Air"
data_volume="MacBook Air - Dados"

# Cabeçalho
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Bypass MDM por Assaf Dori (assafdori.com)  ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
success "Volume do Sistema: $system_volume"
success "Volume de Dados: $data_volume"
echo ""

# Menu
PS3='Escolha uma opção: '
options=("Bypass MDM a partir do Recovery" "Reiniciar e Sair")
select opt in "${options[@]}"; do
	case $opt in
	"Bypass MDM a partir do Recovery")
		echo ""
		echo -e "${YEL}═══════════════════════════════════════${NC}"
		echo -e "${YEL}  Iniciando Processo de Bypass MDM${NC}"
		echo -e "${YEL}═══════════════════════════════════════${NC}"
		echo ""

		# Validação de caminhos
		info "Validando caminhos do sistema..."

		system_path="/Volumes/$system_volume"
		data_path="/Volumes/$data_volume"

		if [ ! -d "$system_path" ]; then
			error_exit "Caminho do volume do sistema não existe: $system_path"
		fi

		if [ ! -d "$data_path" ]; then
			error_exit "Caminho do volume de dados não existe: $data_path"
		fi

		dscl_path="$data_path/private/var/db/dslocal/nodes/Default"
		if [ ! -d "$dscl_path" ]; then
			error_exit "Diretório do Directory Services não existe: $dscl_path"
		fi

		success "Todos os caminhos do sistema foram validados"
		echo ""

		# Criar usuário temporário
		echo -e "${CYAN}Criando Usuário Administrador Temporário${NC}"
		echo -e "${NC}Pressione Enter para usar os padrões (recomendado)${NC}"

		read -p "Digite o Nome Completo Temporário (Padrão: 'Apple'): " realName
		realName="${realName:=Apple}"

		while true; do
			read -p "Digite o Nome de Usuário Temporário (Padrão: 'Apple'): " username
			username="${username:=Apple}"

			if validation_msg=$(validate_username "$username"); then
				break
			else
				warn "$validation_msg"
				echo -e "${YEL}Tente novamente ou pressione Ctrl+C para sair${NC}"
			fi
		done

		if check_user_exists "$dscl_path" "$username"; then
			warn "O usuário '$username' já existe no sistema"
			read -p "Deseja usar um nome de usuário diferente? (s/n): " response
			if [[ "$response" =~ ^[SsYy]$ ]]; then
				while true; do
					read -p "Digite um nome de usuário diferente: " username
					if [ -z "$username" ]; then
						warn "O nome de usuário não pode estar vazio"
						continue
					fi
					if validation_msg=$(validate_username "$username"); then
						if ! check_user_exists "$dscl_path" "$username"; then
							break
						else
							warn "O usuário '$username' também existe. Tente outro nome."
						fi
					else
						warn "$validation_msg"
					fi
				done
			else
				warn "Continuando com o usuário existente '$username' (pode causar conflitos)"
			fi
		fi

		while true; do
			read -p "Digite a Senha Temporária (Padrão: '1234'): " passw
			passw="${passw:=1234}"

			if validation_msg=$(validate_password "$passw"); then
				break
			else
				warn "$validation_msg"
				echo -e "${YEL}Tente novamente ou pressione Ctrl+C para sair${NC}"
			fi
		done

		echo ""

		info "Verificando UID disponível..."
		available_uid=$(find_available_uid "$dscl_path")
		if [ $? -eq 0 ] && [ "$available_uid" != "501" ]; then
			info "UID 501 está em uso, usando UID $available_uid"
		else
			available_uid="501"
		fi
		success "Usando UID: $available_uid"
		echo ""

		info "Criando conta de usuário: $username"

		if ! dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" 2>/dev/null; then
			error_exit "Falha ao criar a conta de usuário"
		fi

		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh" || warn "Falha ao definir o shell do usuário"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName" || warn "Falha ao definir o nome real"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "$available_uid" || warn "Falha ao definir o UID"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20" || warn "Falha ao definir o GID"

		user_home="$data_path/Users/$username"
		if [ ! -d "$user_home" ]; then
			if mkdir -p "$user_home" 2>/dev/null; then
				success "Diretório home do usuário criado"
			else
				error_exit "Falha ao criar o diretório home: $user_home"
			fi
		else
			warn "O diretório home do usuário já existe: $user_home"
		fi

		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username" || warn "Falha ao definir o diretório home"

		if ! dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw" 2>/dev/null; then
			error_exit "Falha ao definir a senha do usuário"
		fi

		if ! dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username" 2>/dev/null; then
			error_exit "Falha ao adicionar o usuário ao grupo de administradores"
		fi

		success "Conta de usuário criada com sucesso"
		echo ""

		# Bloquear domínios MDM
		info "Bloqueando domínios de inscrição MDM..."

		hosts_file="$system_path/etc/hosts"
		if [ ! -f "$hosts_file" ]; then
			warn "O arquivo hosts não existe, criando..."
			touch "$hosts_file" || error_exit "Falha ao criar o arquivo hosts"
		fi

		grep -q "deviceenrollment.apple.com" "$hosts_file" 2>/dev/null || echo "0.0.0.0 deviceenrollment.apple.com" >>"$hosts_file"
		grep -q "mdmenrollment.apple.com" "$hosts_file" 2>/dev/null || echo "0.0.0.0 mdmenrollment.apple.com" >>"$hosts_file"
		grep -q "iprofiles.apple.com" "$hosts_file" 2>/dev/null || echo "0.0.0.0 iprofiles.apple.com" >>"$hosts_file"

		success "Domínios MDM bloqueados no arquivo hosts"
		echo ""

		# Configurar bypass
		info "Configurando ajustes de bypass MDM..."

		config_path="$system_path/var/db/ConfigurationProfiles/Settings"

		if [ ! -d "$config_path" ]; then
			if mkdir -p "$config_path" 2>/dev/null; then
				success "Diretório de configuração criado"
			else
				warn "Não foi possível criar o diretório de configuração"
			fi
		fi

		touch "$data_path/private/var/db/.AppleSetupDone" 2>/dev/null && success "Configuração marcada como concluída" || warn "Não foi possível marcar a configuração como concluída"

		rm -rf "$config_path/.cloudConfigHasActivationRecord" 2>/dev/null && success "Registro de ativação removido" || info "Nenhum registro de ativação para remover"
		rm -rf "$config_path/.cloudConfigRecordFound" 2>/dev/null && success "Registro de cloud config removido" || info "Nenhum registro de cloud config para remover"

		touch "$config_path/.cloudConfigProfileInstalled" 2>/dev/null && success "Marcador de perfil instalado criado" || warn "Não foi possível criar o marcador de perfil"
		touch "$config_path/.cloudConfigRecordNotFound" 2>/dev/null && success "Marcador de registro não encontrado criado" || warn "Não foi possível criar o marcador de não encontrado"

		echo ""
		echo -e "${GRN}╔═══════════════════════════════════════════════╗${NC}"
		echo -e "${GRN}║       Bypass MDM Concluído com Sucesso!      ║${NC}"
		echo -e "${GRN}╚═══════════════════════════════════════════════╝${NC}"
		echo ""
		echo -e "${CYAN}Próximos passos:${NC}"
		echo -e "  1. Feche esta janela do terminal"
		echo -e "  2. Reinicie o seu Mac"
		echo -e "  3. Faça login com usuário: ${YEL}$username${NC} e senha: ${YEL}$passw${NC}"
		echo ""
		break
		;;
	"Reiniciar e Sair")
		echo ""
		info "Reiniciando o sistema..."
		reboot
		break
		;;
	*)
		echo -e "${RED}Opção inválida $REPLY${NC}"
		;;
	esac
done