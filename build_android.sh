#!/bin/bash
# build_android.sh - Build automatizado para Android (APK + AAB)
# Uso: ./build_android.sh [debug|release] [version_code] [version_name]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT="${GODOT:-godot}"
BUILD_DIR="$PROJECT_DIR/builds"
ANDROID_DIR="$BUILD_DIR/android"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[BUILD]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }

MODE="${1:-debug}"
VERSION_CODE="${2:-1}"
VERSION_NAME="${3:-1.0.0}"
PACKAGE_NAME="com.seunome.blockmaster"
KEYSTORE_PATH="$PROJECT_DIR/release.keystore"
KEYSTORE_PROPS="$PROJECT_DIR/user.properties"

log "Iniciando build Android ($MODE)"
log "Projeto: $PROJECT_DIR"
log "Versão: $VERSION_NAME ($VERSION_CODE)"

# Verificar Godot
if ! command -v "$GODOT" &> /dev/null; then
    error "Godot não encontrado. Instale Godot 4.2+ ou defina variável GODOT=/caminho/godot"
fi
GODOT_VERSION=$("$GODOT" --version | head -1)
log "Godot: $GODOT_VERSION"

# Verificar projeto
if [ ! -f "$PROJECT_DIR/project.godot" ]; then
    error "project.godot não encontrado em $PROJECT_DIR"
fi

# Criar diretórios
mkdir -p "$ANDROID_DIR"

# ========== DEBUG BUILD ==========
if [ "$MODE" = "debug" ]; then
    log "Gerando APK DEBUG..."
    
    "$GODOT" --headless --export-debug "Android" "$ANDROID_DIR/BlockMaster-debug.apk" \
        --export-package-name "$PACKAGE_NAME" \
        --export-version-code "$VERSION_CODE" \
        --export-version-name "$VERSION_NAME" \
        2>&1 | tee "$ANDROID_DIR/build-debug.log"
    
    if [ -f "$ANDROID_DIR/BlockMaster-debug.apk" ]; then
        SIZE=$(du -h "$ANDROID_DIR/BlockMaster-debug.apk" | cut -f1)
        success "APK Debug gerado: $ANDROID_DIR/BlockMaster-debug.apk ($SIZE)"
        log "Instale no dispositivo: adb install -r $ANDROID_DIR/BlockMaster-debug.apk"
    else
        error "Falha ao gerar APK debug. Verifique $ANDROID_DIR/build-debug.log"
    fi
    
    exit 0
fi

# ========== RELEASE BUILD ==========
log "Gerando AAB RELEASE para Play Store..."

# Verificar keystore
if [ ! -f "$KEYSTORE_PATH" ]; then
    warn "Keystore não encontrado: $KEYSTORE_PATH"
    log "Gerando novo keystore..."
    read -p "Senha do keystore: " -s STORE_PASS
    echo
    read -p "Confirme a senha: " -s STORE_PASS2
    echo
    [ "$STORE_PASS" = "$STORE_PASS2" ] || error "Senhas não conferem"
    
    read -p "Alias da chave (ex: blockmaster): " KEY_ALIAS
    read -p "Senha da chave (pode ser mesma do keystore): " -s KEY_PASS
    echo
    
    keytool -genkey -v \
        -keystore "$KEYSTORE_PATH" \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass "$STORE_PASS" \
        -keypass "$KEY_PASS" \
        -dname "CN=Block Master, OU=Games, O=SeuNome, L=Cidade, ST=Estado, C=BR"
    
    # Atualizar user.properties
    cat > "$KEYSTORE_PROPS" <<EOF
storeFile=release.keystore
storePassword=$STORE_PASS
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASS
EOF
    success "Keystore criado e configurado"
else
    log "Keystore encontrado: $KEYSTORE_PATH"
    if [ ! -f "$KEYSTORE_PROPS" ]; then
        error "user.properties não encontrado. Crie com as senhas do keystore."
    fi
    source "$KEYSTORE_PROPS"
fi

# Exportar AAB (App Bundle - obrigatório para Play Store)
log "Exportando App Bundle (AAB)..."
"$GODOT" --headless --export-release "Android" "$ANDROID_DIR/BlockMaster.aab" \
    --export-package-name "$PACKAGE_NAME" \
    --export-version-code "$VERSION_CODE" \
    --export-version-name "$VERSION_NAME" \
    --export-keystore "$KEYSTORE_PATH" \
    --export-keystore-pass "$storePassword" \
    --export-key-alias "$keyAlias" \
    --export-key-pass "$keyPassword" \
    2>&1 | tee "$ANDROID_DIR/build-release.log"

if [ -f "$ANDROID_DIR/BlockMaster.aab" ]; then
    SIZE=$(du -h "$ANDROID_DIR/BlockMaster.aab" | cut -f1)
    success "AAB Release gerado: $ANDROID_DIR/BlockMaster.aab ($SIZE)"
    
    # Verificar assinatura
    log "Verificando assinatura..."
    jarsigner -verify -verbose -certs "$ANDROID_DIR/BlockMaster.aab" 2>&1 | grep -E "(verified|X.509)" | head -5
    
    log ""
    log "========================================"
    log "PRÓXIMOS PASSOS PARA PLAY STORE:"
    log "1. Acesse: https://play.google.com/console"
    log "2. Crie/edite o app 'Block Master'"
    log "3. Vá em 'Versões do app' > 'Produção' > 'Criar nova versão'"
    log "4. Faça upload de: $ANDROID_DIR/BlockMaster.aab"
    log "5. Preencha fichas técnicas, screenshots, política de privacidade"
    log "6. Envie para análise"
    log "========================================"
else
    error "Falha ao gerar AAB. Verifique $ANDROID_DIR/build-release.log"
fi