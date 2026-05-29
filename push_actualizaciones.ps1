# ============================================================================
# PRA2 - Push de actualizaciones al repo (commit + push)
# ============================================================================
# Uso (desde la raiz del proyecto):
#
#   powershell -ExecutionPolicy Bypass -File .\push_actualizaciones.ps1
#
# Pide el token (no se ve en pantalla), hace git add -A, commit y push.
# No falla por mensajes informativos de git en stderr.
# ============================================================================

param(
    [string]$GitHubUser = "sserrentino-uoc",
    [string]$RepoName   = "PRA2-VisualizacionDeDatos",
    [string]$BranchName = "main",
    [string]$CommitMsg  = "Limpieza: README sin Python validation, codigo sin comentarios de auditoria, hallazgos en app, .gitignore para Entrega/ y teorico/"
)

# Verificacion previa
if (-not (Test-Path ".\app.R")) {
    Write-Host "ERROR: ejecutar desde la raiz del proyecto PRA2." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: este directorio no es un repo git. Ejecuta primero crear_repo_y_push.ps1." -ForegroundColor Red
    exit 1
}

# Token seguro
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

# Add + commit
Write-Host ""
Write-Host "Agregando cambios..."
git add -A

$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "  -> Sin cambios para commitear (working tree limpio)." -ForegroundColor Yellow
} else {
    git commit -m $CommitMsg
    Write-Host "  -> Commit creado." -ForegroundColor Green
}

# Push con token en URL temporal
$remoteUrlWithToken = "https://x-access-token:$token@github.com/$GitHubUser/$RepoName.git"
$hasRemote = (git remote 2>$null) -contains "origin"
if ($hasRemote) {
    git remote set-url origin $remoteUrlWithToken
} else {
    git remote add origin $remoteUrlWithToken
}

Write-Host ""
Write-Host "Haciendo push a '$BranchName'..."
$pushOutput = git push -u origin $BranchName 2>&1
$pushOutput | ForEach-Object { Write-Host $_ }
$pushExit = $LASTEXITCODE

# Limpiar token del remoto pase lo que pase
git remote set-url origin "https://github.com/$GitHubUser/$RepoName.git" | Out-Null

if ($pushExit -eq 0) {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "  PUSH COMPLETADO" -ForegroundColor Green
    Write-Host "  https://github.com/$GitHubUser/$RepoName" -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "ERROR REAL durante el push (exit code $pushExit)." -ForegroundColor Red
    exit 1
}

# Limpiar token
$token = $null
$remoteUrlWithToken = $null
[System.GC]::Collect()

Write-Host ""
Write-Host "Recuerda ROTAR el token en GitHub: Settings > Developer settings > Personal access tokens > Revoke." -ForegroundColor Yellow
