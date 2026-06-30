# ============================================================================
# ABC Vim - Windows installer (PowerShell)
#
# Usage (from a clone):  powershell -ExecutionPolicy Bypass -File install.ps1
# Usage (download first, inspect, then run -- preferred over piping to iex):
#   iwr -useb https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.ps1 -OutFile abc-vim-install.ps1
#   notepad abc-vim-install.ps1   # optional: review before running
#   powershell -ExecutionPolicy Bypass -File abc-vim-install.ps1
#
# This script is idempotent and safe to re-run. It will:
#   1. Install missing dependencies (git, vim) via winget/choco/scoop.
#   2. Clone (or update) the abc-vim files into %USERPROFILE%\vimfiles.
#   3. Place .vimrc in %USERPROFILE% (symlink if possible, otherwise a copy).
#   4. Install (or update) Vundle.
#   5. Install the plugins listed in the .vimrc.
# ============================================================================

#Requires -Version 5
$ErrorActionPreference = 'Stop'

$RepoUrl   = if ($env:ABC_VIM_REPO) { $env:ABC_VIM_REPO } else { 'https://github.com/aaronbcarlisle/abc-vim.git' }
$VundleUrl = 'https://github.com/VundleVim/Vundle.vim.git'
$VimDir    = Join-Path $env:USERPROFILE 'vimfiles'
$Vimrc     = Join-Path $env:USERPROFILE '.vimrc'
$VundleDir = Join-Path $VimDir 'bundle\Vundle.vim'

# --- pretty logging --------------------------------------------------------
function Write-Info($m) { Write-Host "[abc-vim] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[abc-vim] $m" -ForegroundColor Yellow }
function Write-Err ($m) { Write-Host "[abc-vim] $m" -ForegroundColor Red }

function Stamp { Get-Date -Format 'yyyyMMddHHmmss' }
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# --- dependency installation -----------------------------------------------
function Install-Pkg($wingetId, $chocoId, $scoopId) {
    if (Have 'winget') {
        winget install --id $wingetId -e --source winget `
            --accept-source-agreements --accept-package-agreements
    } elseif (Have 'choco') {
        choco install $chocoId -y
    } elseif (Have 'scoop') {
        scoop install $scoopId
    } else {
        throw "No supported package manager (winget/choco/scoop) found. Install '$chocoId' manually and re-run."
    }
    # Refresh PATH for this session so the freshly installed tool is found.
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

function Ensure-Dep($cmd, $wingetId, $chocoId, $scoopId) {
    if (Have $cmd) { return }
    Write-Warn "'$cmd' is not installed - attempting to install it..."
    Install-Pkg $wingetId $chocoId $scoopId
    if (-not (Have $cmd)) {
        throw "Could not find '$cmd' after install. Open a new terminal so PATH refreshes, then re-run."
    }
    Write-Info "Installed '$cmd'."
}

Ensure-Dep 'git' 'Git.Git'   'git' 'git'
Ensure-Dep 'vim' 'vim.vim'   'vim' 'vim'

# --- clone or update the vim files -----------------------------------------
if (Test-Path (Join-Path $VimDir '.git')) {
    Write-Info "$VimDir already exists - updating it instead of re-cloning."
    try { git -C $VimDir pull --ff-only } catch { Write-Warn "Could not fast-forward $VimDir; leaving it as-is." }
} elseif (Test-Path $VimDir) {
    $backup = "$VimDir.bak.$(Stamp)"
    Write-Warn "$VimDir exists but is not an abc-vim git checkout - moving it to $backup"
    Move-Item -LiteralPath $VimDir -Destination $backup
    git clone $RepoUrl $VimDir
} else {
    git clone $RepoUrl $VimDir
}

# Make sure the runtime scratch directories used by the .vimrc exist.
foreach ($d in 'swap','backup','undo','bundle') {
    New-Item -ItemType Directory -Force -Path (Join-Path $VimDir $d) | Out-Null
}

# --- place .vimrc in %USERPROFILE% -----------------------------------------
$TargetVimrc = Join-Path $VimDir '.vimrc'
if (-not (Test-Path $TargetVimrc)) {
    throw "Expected $TargetVimrc to exist after clone but it is missing. Aborting."
}

if (Test-Path $Vimrc) {
    $existing = Get-Item -LiteralPath $Vimrc -Force
    if (-not $existing.LinkType) {
        $backup = "$Vimrc.bak.$(Stamp)"
        Write-Warn "Existing $Vimrc found - backing it up to $backup"
        Move-Item -LiteralPath $Vimrc -Destination $backup
    } else {
        Remove-Item -LiteralPath $Vimrc -Force
    }
}

# Prefer a symlink (needs Developer Mode or admin); fall back to a plain copy.
try {
    New-Item -ItemType SymbolicLink -Path $Vimrc -Target $TargetVimrc -ErrorAction Stop | Out-Null
    Write-Info "Linked $Vimrc -> $TargetVimrc"
} catch {
    Copy-Item -LiteralPath $TargetVimrc -Destination $Vimrc -Force
    Write-Warn "Symlinks unavailable - copied .vimrc instead (edits in $Vimrc will not track the repo)."
}

# --- install or update Vundle ----------------------------------------------
if (Test-Path (Join-Path $VundleDir '.git')) {
    Write-Info 'Vundle already installed - updating it.'
    try { git -C $VundleDir pull --ff-only } catch { Write-Warn 'Could not fast-forward Vundle; leaving it as-is.' }
} elseif (Test-Path $VundleDir) {
    $backup = "$VundleDir.bak.$(Stamp)"
    Write-Warn "$VundleDir exists but is not a git checkout - moving it to $backup"
    Move-Item -LiteralPath $VundleDir -Destination $backup
    git clone $VundleUrl $VundleDir
} else {
    git clone $VundleUrl $VundleDir
}

# --- install the plugins ---------------------------------------------------
Write-Info 'Installing plugins via Vundle...'
vim +PluginInstall +qall
# $ErrorActionPreference='Stop' does not trip on native exit codes, so check it.
if ($LASTEXITCODE -ne 0) {
    throw "Vim exited with code $LASTEXITCODE during plugin installation. Re-run 'vim +PluginInstall' to retry."
}

Write-Info 'All done! Start vim to enjoy your ABC Vim setup.'
