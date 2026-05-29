# ============================================================================
# PRA2 - Crear repositorio publico en GitHub y subir el codigo
# ============================================================================
# Uso (desde la raiz del proyecto):
#
#   powershell -ExecutionPolicy Bypass -File .\crear_repo_y_push.ps1
#
# El script pedira el token de forma segura (no se ve en pantalla y no queda
# en el historial). Lo unico que ves en consola es el resultado: URL del repo
# creado y resumen del push.
#
# Requisitos: git instalado y disponible en PATH; conexion a internet.
# ============================================================================

param(
    [string]$GitHubUser    = "sserrentino-uoc",
    [string]$RepoName      = "PRA2-VisualizacionDeDatos",
    [string]$RepoDesc      = "PRA2 Visualizacion de Datos UOC - App Shiny sobre crecimiento infantil, desigualdad y corresponsabilidad paterna (MICS6 Argentina 2019-2020).",
    [string]$BranchName    = "main",
    [string]$AuthorName    = "Sebastian Serrentino Mangino",
    [string]$AuthorEmail   = "sserrentino@uoc.edu"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- 0. Verificar que estamos en la raiz del proyecto -------------------------
if (-not (Test-Path ".\app.R")) {
    Write-Host "ERROR: ejecutar desde la raiz del proyecto PRA2 (no encuentro app.R)." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path ".\README.md")) {
    Write-Host "ERROR: README.md no encontrado." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path ".\LICENSE")) {
    Write-Host "ERROR: LICENSE no encontrado." -ForegroundColor Red
    exit 1
}

# --- 1. Verificar git ---------------------------------------------------------
try {
    $gitVer = git --version
    Write-Host "git detectado: $gitVer"
} catch {
    Write-Host "ERROR: git no esta instalado o no esta en PATH." -ForegroundColor Red
    exit 1
}

# --- 2. Solicitar el token de forma segura ------------------------------------
Write-Host ""
Write-Host "Pega tu Personal Access Token de GitHub (no se muestra en pantalla):" -ForegroundColor Cyan
$secureToken = Read-Host -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "ERROR: token vacio." -ForegroundColor Red
    exit 1
}

# --- 3. Validar el token (GET /user) ------------------------------------------
$headers = @{
    "Authorization"        = "Bearer $token"
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "PRA2-Setup-Script"
}

Write-Host ""
Write-Host "Validando token con GitHub..."
try {
    $me = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method GET
    Write-Host "  -> Autenticado como: $($me.login)" -ForegroundColor Green
    if ($me.login -ne $GitHubUser) {
        Write-Host "  AVISO: el token pertenece a '$($me.login)', pero el script asume usuario '$GitHubUser'." -ForegroundColor Yellow
        Write-Host "  Si tu usuario real es '$($me.login)', cancela y ejecuta de nuevo con -GitHubUser $($me.login)." -ForegroundColor Yellow
        $confirm = Read-Host "Continuar con '$GitHubUser' igual? (s/N)"
        if ($confirm -ne "s" -and $confirm -ne "S") { exit 1 }
    }
} catch {
    Write-Host "ERROR: el token no es valido o no tiene permiso para leer el usuario." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# --- 4. Crear el repositorio (si no existe) -----------------------------------
Write-Host ""
Write-Host "Verificando si el repositorio existe..."
$repoUrl = "https://github.com/$GitHubUser/$RepoName"
$apiUrl = "https://api.github.com/repos/$GitHubUser/$RepoName"

try {
    $existing = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET
    Write-Host "  -> El repositorio YA EXISTE: $($existing.html_url)" -ForegroundColor Yellow
    $reuse = Read-Host "Sobreescribir contenido y hacer push igualmente? (s/N)"
    if ($reuse -ne "s" -and $reuse -ne "S") { exit 1 }
} catch {
    Write-Host "  -> No existe. Creandolo..."
    $body = @{
        name        = $RepoName
        description = $RepoDesc
        private     = $false
        auto_init   = $false
        has_issues  = $true
        has_wiki    = $false
        license_template = $null
    } | ConvertTo-Json -Depth 5

    try {
        $created = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers -Method POST -Body $body -ContentType "application/json"
        Write-Host "  -> Repositorio creado: $($created.html_url)" -ForegroundColor Green
    } catch {
        Write-Host "ERROR al crear el repositorio:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        if ($_.ErrorDetails) { Write-Host $_.ErrorDetails.Message }
        exit 1
    }
}

# --- 5. Inicializar git local (si hace falta) ---------------------------------
Write-Host ""
if (-not (Test-Path ".git")) {
    Write-Host "Inicializando repositorio git local..."
    git init | Out-Null
    git branch -M $BranchName
} else {
    Write-Host "Repositorio git local ya existe."
}

# Configurar autoria local (no global) si no esta seteada
$currentName  = git config user.name  2>$null
$currentEmail = git config user.email 2>$null
if ([string]::IsNullOrWhiteSpace($currentName))  { git config user.name  $AuthorName  | Out-Null }
if ([string]::IsNullOrWhiteSpace($currentEmail)) { git config user.email $AuthorEmail | Out-Null }

# --- 6. Add + commit ----------------------------------------------------------
Write-Host ""
Write-Host "Agregando archivos (respetando .gitignore)..."
git add -A

$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "  -> Nada que commitear (working tree limpio)."
} else {
    $msg = "PRA2 v1.0 final: app Shiny, pipeline R, validacion Python, capturas, documentacion academica"
    git commit -m $msg | Out-Null
    Write-Host "  -> Commit creado: $msg" -ForegroundColor Green
}

# --- 7. Configurar remoto y push ----------------------------------------------
Write-Host ""
Write-Host "Configurando remoto..."
$remoteUrlWithToken = "https://x-access-token:$token@github.com/$GitHubUser/$RepoName.git"

$hasRemote = (git remote 2>$null) -contains "origin"
if ($hasRemote) {
    git remote set-url origin $remoteUrlWithToken
} else {
    git remote add origin $remoteUrlWithToken
}

Write-Host "Haciendo push a '$BranchName'..."
try {
    git push -u origin $BranchName 2>&1 | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "  PUSH COMPLETADO" -ForegroundColor Green
    Write-Host "  Repositorio publico: $repoUrl" -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green
} catch {
    Write-Host "ERROR durante el push:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
} finally {
    # Eliminar el token del remoto para que no quede guardado en .git/config
    git remote set-url origin "https://github.com/$GitHubUser/$RepoName.git" | Out-Null
    Write-Host "Token removido del remoto local (queda como HTTPS sin credenciales)."
}

# --- 8. Limpiar el token de memoria -------------------------------------------
$token = $null
$remoteUrlWithToken = $null
[System.GC]::Collect()

Write-Host ""
Write-Host "Listo. Recuerda ROTAR el token en GitHub: Settings > Developer settings > Personal access tokens > Revoke." -ForegroundColor Yellow
