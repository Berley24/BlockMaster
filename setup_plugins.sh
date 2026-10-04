#!/bin/bash
# setup_plugins.sh - Baixa e instala plugins Godot necessários
# Requer: git, curl

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDONS_DIR="$PROJECT_DIR/addons"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[PLUGIN]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }

mkdir -p "$ADDONS_DIR"

# Função para clonar ou atualizar repo
clone_or_update() {
    local url=$1
    local dir=$2
    local branch=${3:-master}
    
    if [ -d "$dir/.git" ]; then
        log "Atualizando $(basename $dir)..."
        cd "$dir" && git fetch origin && git reset --hard origin/$branch
    else
        log "Clonando $(basename $dir)..."
        git clone --depth 1 --branch "$branch" "$url" "$dir"
    fi
}

log "Instalando plugins Godot para Block Master..."

# 1. GodotPayment (Google Play Billing)
log "1/4 - GodotPayment (IAP/Compras)"
clone_or_update "https://github.com/godotengine/godot-payment-plugin.git" "$ADDONS_DIR/godotpayment" "4.x"
success "GodotPayment instalado"

# 2. GodotAdMob (Anúncios)
log "2/4 - GodotAdMob (Ads)"
clone_or_update "https://github.com/godotengine/godot-admob-plugin.git" "$ADDONS_DIR/godotadmob" "4.x"
success "GodotAdMob instalado"

# 3. GodotPlayGamesServices (Leaderboards/Achievements)
log "3/4 - GodotPlayGamesServices (Leaderboards)"
clone_or_update "https://github.com/godotengine/godot-play-games-services.git" "$ADDONS_DIR/godotplaygamesservices" "4.x"
success "GodotPlayGamesServices instalado"

# 4. GodotNotifications (Push notifications)
log "4/4 - GodotNotifications (Push)"
clone_or_update "https://github.com/godotengine/godot-notifications.git" "$ADDONS_DIR/godotnotifications" "4.x"
success "GodotNotifications instalado"

# Verificar estrutura
log "Verificando estrutura dos plugins..."
for plugin in godotpayment godotadmob godotplaygamesservices godotnotifications; do
    if [ -f "$ADDONS_DIR/$plugin/plugin.cfg" ] || [ -f "$ADDONS_DIR/$plugin/$plugin.gdextension" ] || [ -d "$ADDONS_DIR/$plugin/android" ]; then
        success "$plugin: OK"
    else
        warn "$plugin: estrutura não padrão, verifique manualmente"
    fi
done

log ""
log "========================================"
log "PRÓXIMOS PASSOS NO GODOT EDITOR:"
log "1. Abra o projeto no Godot 4"
log "2. Vá em Projeto > Plugins"
log "4. Ative TODOS os 4 plugins:"
log "   ☑ GodotPayment"
log "   ☑ GodotAdMob"
log "   ☑ GodotPlayGamesServices"
log "   ☑ GodotNotifications"
log "5. Reinicie o Godot"
log "6. Configure os IDs em:"
log "   - scripts/autoload/MonetizationManager.gd (AdMob)"
log "   - scripts/autoload/LeaderboardManager.gd (Play Games)"
log "========================================"

success "Setup de plugins concluído!"