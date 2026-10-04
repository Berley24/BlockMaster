<# 
.SYNOPSIS
    Build automatizado para Android (APK + AAB) - PowerShell 5.1 compativel
.DESCRIPTION
    Script para build do Block Master no Windows
.EXAMPLE
    .\build_android.ps1 debug
    .\build_android.ps1 release 2 "1.0.1"
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug",
    
    [Parameter(Mandatory=$false)]
    [int]$VersionCode = 1,
    
    [Parameter(Mandatory=$false)]
    [string]$VersionName = "1.0.0"
)

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
$BuildDir = Join-Path $ProjectDir "builds"
$AndroidDir = Join-Path $BuildDir "android"
$PackageName = "com.seunome.blockmaster"
$KeystorePath = Join-Path $ProjectDir "release.keystore"
$KeystoreProps = Join-Path $ProjectDir "user.properties"

function Log { Write-Host "[BUILD] $args" -ForegroundColor Cyan }
function Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Warn { Write-Host "[AVISO] $args" -ForegroundColor Yellow }
function ErrorMsg { Write-Host "[ERRO] $args" -ForegroundColor Red; exit 1 }

Log "Iniciando build Android ($Mode)"
Log "Projeto: $ProjectDir"
Log "Versao: $VersionName ($VersionCode)"

# Verificar Godot
if (-not (Get-Command $Godot -ErrorAction SilentlyContinue)) {
    ErrorMsg "Godot nao encontrado. Instale Godot 4.2+ ou defina `$env:GODOT='C:\caminho\godot.exe'"
}
$GodotVersion = & $Godot --version | Select-Object -First 1
Log "Godot: $GodotVersion"

# Verificar projeto
if (-not (Test-Path (Join-Path $ProjectDir "project.godot"))) {
    ErrorMsg "project.godot nao encontrado em $ProjectDir"
}

# Criar diretorios
New-Item -ItemType Directory -Force -Path $AndroidDir | Out-Null

# ========== DEBUG BUILD ==========
if ($Mode -eq "debug") {
    Log "Gerando APK DEBUG..."
    
    $apkPath = Join-Path $AndroidDir "BlockMaster-debug.apk"
    $logPath = Join-Path $AndroidDir "build-debug.log"
    
    & $Godot --headless --export-debug "Android" $apkPath `
        --export-package-name $PackageName `
        --export-version-code $VersionCode `
        --export-version-name $VersionName 2>&1 | Tee-Object -FilePath $logPath
    
    if (Test-Path $apkPath) {
        $size = (Get-Item $apkPath).Length / 1MB
        Success "APK Debug gerado: $apkPath ($([math]::Round($size, 1)) MB)"
        Log "Instale no dispositivo: adb install -r $apkPath"
    } else {
        ErrorMsg "Falha ao gerar APK debug. Verifique $logPath"
    }
    exit 0
}

# ========== RELEASE BUILD ==========
Log "Gerando AAB RELEASE para Play Store..."

# Verificar keystore
if (-not (Test-Path $KeystorePath)) {
    Warn "Keystore nao encontrado: $KeystorePath"
    Log "Gerando novo keystore..."
    
    $storePass = Read-Host -AsSecureString "Senha do keystore"
    $storePass2 = Read-Host -AsSecureString "Confirme a senha"
    $storePassText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass))
    $storePassText2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass2))
    
    if ($storePassText -ne $storePassText2) { ErrorMsg "Senhas nao conferem" }
    
    $keyAlias = Read-Host "Alias da chave (ex: blockmaster)"
    $keyPass = Read-Host -AsSecureString "Senha da chave (pode ser mesma do keystore)"
    $keyPassText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass))
    
    $dname = "CN=Block Master, OU=Games, O=SeuNome, L=Cidade, ST=Estado, C=BR"
    & keytool -genkey -v `
        -keystore $KeystorePath `
        -alias $keyAlias `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -storepass $storePassText `
        -keypass $keyPassText `
        -dname $dname
    
    # Atualizar user.properties
    @"
storeFile=release.keystore
storePassword=$storePassText
keyAlias=$keyAlias
keyPassword=$keyPassText
"@ | Set-Content $KeystoreProps -Encoding UTF8
    
    Success "Keystore criado e configurado"
} else {
    Log "Keystore encontrado: $KeystorePath"
    if (-not (Test-Path $KeystoreProps)) {
        ErrorMsg "user.properties nao encontrado. Crie com as senhas do keystore."
    }
    $props = @{}
    Get-Content $KeystoreProps | ForEach-Object {
        if ($_ -match '^(.+)=(.+)$') { $props[$matches[1]] = $matches[2] }
    }
    $storePassword = $props["storePassword"]
    $keyAlias = $props["keyAlias"]
    $keyPassword = $props["keyPassword"]
}

# Exportar AAB (App Bundle - obrigatorio para Play Store)
Log "Exportando App Bundle (AAB)..."
$aabPath = Join-Path $AndroidDir "BlockMaster.aab"
$logPath = Join-Path $AndroidDir "build-release.log"

& $Godot --headless --export-release "Android" $aabPath `
    --export-package-name $PackageName `
    --export-version-code $VersionCode `
    --export-version-name $VersionName `
    --export-keystore $KeystorePath `
    --export-keystore-pass $storePassword `
    --export-key-alias $keyAlias `
    --export-key-pass $keyPassword 2>&1 | Tee-Object -FilePath $logPath

if (Test-Path $aabPath) {
    $size = (Get-Item $aabPath).Length / 1MB
    Success "AAB Release gerado: $aabPath ($([math]::Round($size, 1)) MB)"
    
    # Verificar assinatura
    Log "Verificando assinatura..."
    & jarsigner -verify -verbose -certs $aabPath 2>&1 | Select-String -Pattern "verified|X.509" | Select-Object -First 5
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "PROXIMOS PASSOS PARA PLAY STORE:" -ForegroundColor Cyan
    Write-Host "1. Acesse: https://play.google.com/console" -ForegroundColor White
    Write-Host "2. Crie/edite o app 'Block Master'" -ForegroundColor White
    Write-Host "3. Va em 'Versoes do app' > 'Producao' > 'Criar nova versao'" -ForegroundColor White
    Write-Host "4. Faca upload de: $aabPath" -ForegroundColor White
    Write-Host "5. Preencha fichas tecnicas, screenshots, politica de privacidade" -ForegroundColor White
    Write-Host "6. Envie para analise" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    ErrorMsg "Falha ao gerar AAB. Verifique $logPath"
}