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
$IdeaVimrc = Join-Path $env:USERPROFILE '.ideavimrc'
$VundleDir = Join-Path $VimDir 'bundle\Vundle.vim'

# --- pretty logging --------------------------------------------------------
function Write-Info($m) { Write-Host "[abc-vim] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[abc-vim] $m" -ForegroundColor Yellow }
function Write-Err ($m) { Write-Host "[abc-vim] $m" -ForegroundColor Red }

function Stamp { Get-Date -Format 'yyyyMMddHHmmss' }
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# --- dependency installation -----------------------------------------------
function Update-SessionPath {
    # Refresh PATH for this session so a freshly installed tool is found.
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

# Try every package manager present on PATH in turn, not just the first one:
# if winget is installed but its install fails, fall back to choco then scoop.
function Ensure-Dep($cmd, $wingetId, $chocoId, $scoopId) {
    if (Have $cmd) { return }
    Write-Warn "'$cmd' is not installed - attempting to install it..."
    $managers = @(
        @{ Name = 'winget'; Action = { winget install --id $wingetId -e --source winget --accept-source-agreements --accept-package-agreements } },
        @{ Name = 'choco';  Action = { choco install $chocoId -y } },
        @{ Name = 'scoop';  Action = { scoop install $scoopId } }
    )
    $tried = $false
    foreach ($m in $managers) {
        if (-not (Have $m.Name)) { continue }
        $tried = $true
        Write-Info "Trying $($m.Name)..."
        try { & $m.Action } catch { Write-Warn "$($m.Name) failed: $_" }
        Update-SessionPath
        if (Have $cmd) { Write-Info "Installed '$cmd' via $($m.Name)."; return }
    }
    if (-not $tried) {
        throw "No supported package manager (winget/choco/scoop) found. Install '$cmd' manually and re-run."
    }
    throw "Could not install '$cmd' with any available package manager. Install it manually (or open a new terminal so PATH refreshes) and re-run."
}

Ensure-Dep 'git' 'Git.Git'   'git' 'git'
Ensure-Dep 'vim' 'vim.vim'   'vim' 'vim'

# git is a native exe, so its non-zero exit codes do NOT honor
# $ErrorActionPreference and a plain try/catch never fires. Check $LASTEXITCODE
# explicitly: hard-fail on the operations we depend on (clone), warn on the
# best-effort ones (pull --ff-only).
function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$GitArgs, [string]$WarnOnFail)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        if ($WarnOnFail) { Write-Warn $WarnOnFail; return $false }
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE."
    }
    return $true
}

# --- locate a local checkout -----------------------------------------------
# If this script is being run from inside an abc-vim git checkout, install from
# that working tree (picking up local/uncommitted edits) instead of cloning the
# remote. When downloaded/run standalone, fall back to the remote clone.
function Resolve-Full($p) { try { [System.IO.Path]::GetFullPath($p).TrimEnd('\', '/') } catch { $p } }

$ScriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { $null }
$LocalSrc  = $null
if ($ScriptDir) {
    $top = (& git -C $ScriptDir rev-parse --show-toplevel 2>$null)
    # Require markers specific to abc-vim, not just any repo with a root .vimrc,
    # so we never recursively copy an unrelated dotfiles/home tree into vimfiles.
    if ($LASTEXITCODE -eq 0 -and $top -and
        (Test-Path (Join-Path $top '.vimrc')) -and
        (Test-Path (Join-Path $top 'colors/hybrid.vim')) -and
        (Test-Path (Join-Path $top 'install.sh'))) {
        $LocalSrc = $top
    }
}

# --- clone, copy, or update the vim files ----------------------------------
if ($LocalSrc -and ((Resolve-Full $LocalSrc) -ieq (Resolve-Full $VimDir))) {
    Write-Info "Running from the canonical checkout at $VimDir - using it in place."
} elseif ($LocalSrc) {
    Write-Info "Installing from local checkout $LocalSrc"
    if (Test-Path $VimDir) {
        $backup = "$VimDir.bak.$(Stamp)"
        Write-Warn "$VimDir already exists - moving it to $backup"
        Move-Item -LiteralPath $VimDir -Destination $backup
    }
    # copy the working tree verbatim (including .git) so uncommitted edits are
    # preserved and future 'git pull' updates still work.
    Copy-Item -LiteralPath $LocalSrc -Destination $VimDir -Recurse -Force
} elseif (Test-Path (Join-Path $VimDir '.git')) {
    Write-Info "$VimDir already exists - updating it instead of re-cloning."
    Invoke-Git @('-C', $VimDir, 'pull', '--ff-only') -WarnOnFail "Could not fast-forward $VimDir; leaving it as-is." | Out-Null
} elseif (Test-Path $VimDir) {
    $backup = "$VimDir.bak.$(Stamp)"
    Write-Warn "$VimDir exists but is not an abc-vim git checkout - moving it to $backup"
    Move-Item -LiteralPath $VimDir -Destination $backup
    Invoke-Git @('clone', $RepoUrl, $VimDir) | Out-Null
} else {
    Invoke-Git @('clone', $RepoUrl, $VimDir) | Out-Null
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

# --- link .ideavimrc (IdeaVim support) -------------------------------------
$TargetIdeaVimrc = Join-Path $VimDir '.ideavimrc'
if (Test-Path $TargetIdeaVimrc) {
    if (Test-Path $IdeaVimrc) {
        $existing = Get-Item -LiteralPath $IdeaVimrc -Force
        if (-not $existing.LinkType) {
            $backup = "$IdeaVimrc.bak.$(Stamp)"
            Write-Warn "Existing $IdeaVimrc found - backing it up to $backup"
            Move-Item -LiteralPath $IdeaVimrc -Destination $backup
        } else {
            Remove-Item -LiteralPath $IdeaVimrc -Force
        }
    }
    try {
        New-Item -ItemType SymbolicLink -Path $IdeaVimrc -Target $TargetIdeaVimrc -ErrorAction Stop | Out-Null
        Write-Info "Linked $IdeaVimrc -> $TargetIdeaVimrc"
    } catch {
        Copy-Item -LiteralPath $TargetIdeaVimrc -Destination $IdeaVimrc -Force
        Write-Warn "Symlinks unavailable - copied .ideavimrc instead (edits in $IdeaVimrc will not track the repo)."
    }
}

# --- install or update Vundle ----------------------------------------------
if (Test-Path (Join-Path $VundleDir '.git')) {
    Write-Info 'Vundle already installed - updating it.'
    Invoke-Git @('-C', $VundleDir, 'pull', '--ff-only') -WarnOnFail 'Could not fast-forward Vundle; leaving it as-is.' | Out-Null
} elseif (Test-Path $VundleDir) {
    $backup = "$VundleDir.bak.$(Stamp)"
    Write-Warn "$VundleDir exists but is not a git checkout - moving it to $backup"
    Move-Item -LiteralPath $VundleDir -Destination $backup
    Invoke-Git @('clone', $VundleUrl, $VundleDir) | Out-Null
} else {
    Invoke-Git @('clone', $VundleUrl, $VundleDir) | Out-Null
}

# --- install the plugins ---------------------------------------------------
Write-Info 'Installing plugins via Vundle...'
vim +PluginInstall +qall | Out-Null
# $ErrorActionPreference='Stop' does not trip on native exit codes, so check it.
if ($LASTEXITCODE -ne 0) {
    throw "Vim exited with code $LASTEXITCODE during plugin installation. Re-run 'vim +PluginInstall' to retry."
}

Write-Info 'All done! Start vim to enjoy your ABC Vim setup.'
