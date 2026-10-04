<# 
.SYNOPSIS
    Baixa e instala plugins Godot necessários - PowerShell
.DESCRIPTION
    Script para instalar GodotPayment, GodotAdMob, GodotPlayGamesServices, GodotNotifications
#>

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$AddonsDir = Join-Path $ProjectDir "addons"

function Log { Write-Host "[PLUGIN] $args" -ForegroundColor Cyan }
function Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Warn { Write-Host "[AVISO] $args" -ForegroundColor Yellow }

New-Item -ItemType Directory -Force -Path $AddonsDir | Out-Null

function CloneOrUpdate {
    param($Url, $Dir, $Branch = "4.x")
    
    if (Test-Path (Join-Path $Dir ".git")) {
        Log "Atualizando $(Split-Path $Dir -Leaf)..."
        Set-Location $Dir
        git fetch origin
        git reset --hard "origin/$Branch"
        Set-Location $ProjectDir
    } else {
        Log "Clonando $(Split-Path $Dir -Leaf)..."
        git clone --depth 1 --branch $Branch $Url $Dir
    }
}

Log "Instalando plugins Godot para Block Master..."

# 1. GodotPayment (Google Play Billing)
Log "1/4 - GodotPayment (IAP/Compras)"
CloneOrUpdate "https://github.com/godotengine/godot-payment-plugin.git" (Join-Path $AddonsDir "godotpayment")
Success "GodotPayment instalado"

# 2. GodotAdMob (Anúncios)
Log "2/4 - GodotAdMob (Ads)"
CloneOrUpdate "https://github.com/godotengine/godot-admob-plugin.git" (Join-Path $AddonsDir "godotadmob")
Success "GodotAdMob instalado"

# 3. GodotPlayGamesServices (Leaderboards/Achievements)
Log "3/4 - GodotPlayGamesServices (Leaderboards)"
CloneOrUpdate "https://github.com/godotengine/godot-play-games-services.git" (Join-Path $AddonsDir "godotplaygamesservices")
Success "GodotPlayGamesServices instalado"

# 4. GodotNotifications (Push notifications)
Log "4/4 - GodotNotifications (Push)"
CloneOrUpdate "https://github.com/godotengine/godot-notifications.git" (Join-Path $AddonsDir "godotnotifications")
Success "GodotNotifications instalado"

# Verificar estrutura
Log "Verificando estrutura dos plugins..."
foreach ($plugin in "godotpayment", "godotadmob", "godotplaygamesservices", "godotnotifications") {
    $path = Join-Path $AddonsDir $plugin
    if (Test-Path (Join-Path $path "plugin.cfg") -or Test-Path (Join-Path $path "$plugin.gdextension") -or Test-Path (Join-Path $path "android")) {
        Success "$plugin: OK"
    } else {
        Warn "$plugin: estrutura não padrão, verifique manualmente"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRÓXIMOS PASSOS NO GODOT EDITOR:" -ForegroundColor Cyan
Write-Host "1. Abra o projeto no Godot 4" -ForegroundColor White
Write-Host "2. Vá em Projeto > Plugins" -ForegroundColor White
Write-Host "3. Ative TODOS os 4 plugins:" -ForegroundColor White
Write-Host "   ☑ GodotPayment" -ForegroundColor White
Write-Host "   ☑ GodotAdMob" -ForegroundColor White
Write-Host "   ☑ GodotPlayGamesServices" -ForegroundColor White
Write-Host "   ☑ GodotNotifications" -ForegroundColor White
Write-Host "4. Reinicie o Godot" -ForegroundColor White
Write-Host "5. Configure os IDs em:" -ForegroundColor White
Write-Host "   - scripts/autoload/MonetizationManager.gd (AdMob)" -ForegroundColor White
Write-Host "   - scripts/autoload/LeaderboardManager.gd (Play Games)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

Success "Setup de plugins concluído!"