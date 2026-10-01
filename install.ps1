# ============================================================================
# ABC Vim - Windows installer (PowerShell)
#
# Usage (from a clone):  powershell -ExecutionPolicy Bypass -File install.ps1
# Usage (download first, inspect, then run -- preferred over piping to iex):
#   iwr -useb https://raw.githubusercontent.com/aaronbcarlisle/abc-vim/master/install.ps1 -OutFile abc-vim-install.ps1
#   notepad abc-vim-install.ps1   # optional: review before running
#   powershell -ExecutionPolicy Bypass -File abc-vim-install.ps1
#
# Options:
#   -Force   Replace an existing abc-vim (or Vundle) checkout that has local
#            changes or cannot fast-forward, instead of leaving it as-is. The
#            old checkout is moved (or, when running from it, copied) to a
#            timestamped .bak.<stamp> backup first. Example:
#              powershell -ExecutionPolicy Bypass -File abc-vim-install.ps1 -Force
#   -Help    Show this help and exit.
#
# This script is idempotent and safe to re-run. It will:
#   1. Install missing dependencies (git, vim) via winget/choco/scoop.
#   2. Clone (or update) the abc-vim files into %USERPROFILE%\vimfiles
#      (or update an existing checkout in %USERPROFILE%\.vim).
#   3. Place .vimrc in %USERPROFILE% (symlink if possible, otherwise a copy).
#   4. Install (or update) Vundle.
#   5. Install (and update) the plugins listed in the .vimrc.
# Anything it replaces (.vimrc, .ideavimrc, a vimfiles that is not an abc-vim
# checkout, or with -Force a checkout with local changes) is moved to a
# timestamped .bak.<stamp> backup first; nothing is deleted.
# ============================================================================

#Requires -Version 5
# CmdletBinding makes PowerShell reject unknown parameters instead of ignoring
# them.
[CmdletBinding()]
param(
    [switch]$Force,
    [Alias('h')][switch]$Help
)
$ErrorActionPreference = 'Stop'

if ($Help) {
    Write-Host @'
Usage: powershell -ExecutionPolicy Bypass -File install.ps1 [-Force] [-Help]

Install or update ABC Vim in %USERPROFILE%\vimfiles.

  -Force   Replace an abc-vim or Vundle checkout that has local changes or
           cannot fast-forward (it is backed up to <dir>.bak.<stamp> first)
           instead of leaving it as-is.
  -Help    Show this help and exit.
'@
    exit 0
}

$RepoUrl   = if ($env:ABC_VIM_REPO) { $env:ABC_VIM_REPO } else { 'https://github.com/aaronbcarlisle/abc-vim.git' }
$VundleUrl = 'https://github.com/VundleVim/Vundle.vim.git'
$VimDir    = Join-Path $env:USERPROFILE 'vimfiles'
$Vimrc     = Join-Path $env:USERPROFILE '.vimrc'
$IdeaVimrc = Join-Path $env:USERPROFILE '.ideavimrc'

# install.sh under Git Bash installs to ~/.vim instead, and the .vimrc finds
# either. If that is where the existing abc-vim checkout lives, update it
# rather than creating a second copy in vimfiles (gvim and Git Bash's vim would
# then each use a different one).
$AltVimDir = Join-Path $env:USERPROFILE '.vim'
if (-not (Test-Path (Join-Path $VimDir '.git')) -and
    (Test-Path (Join-Path $AltVimDir '.git')) -and
    (Test-Path (Join-Path $AltVimDir 'colors/hybrid.vim'))) {
    $VimDir = $AltVimDir
}
$VundleDir = Join-Path $VimDir 'bundle\Vundle.vim'

# --- pretty logging --------------------------------------------------------
function Write-Info($m) { Write-Host "[abc-vim] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[abc-vim] $m" -ForegroundColor Yellow }
function Write-Err ($m) { Write-Host "[abc-vim] $m" -ForegroundColor Red }

function Stamp { Get-Date -Format 'yyyyMMddHHmmss' }

# Symlink $Link -> $Target (needs Developer Mode or admin); fall back to a copy.
# New-Item needs admin on Windows PowerShell 5.1 even with Developer Mode on,
# while mklink honors Developer Mode, so try that before copying.
function Link-File($Target, $Link) {
    $ErrorActionPreference = 'Continue'
    try {
        New-Item -ItemType SymbolicLink -Path $Link -Target $Target -ErrorAction Stop | Out-Null
    } catch {
        & cmd /c mklink $Link $Target *> $null
        if ($LASTEXITCODE -ne 0) {
            Copy-Item -LiteralPath $Target -Destination $Link -Force
            Write-Warn "Symlinks unavailable - copied $Target to $Link instead (edits in $Link will not track the repo; enable Developer Mode and re-run to link)."
            return
        }
    }
    Write-Info "Linked $Link -> $Target"
}
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

# True when the checkout's branch tracks a remote branch. '@{u}' is quoted:
# bare @{...} is a PowerShell hashtable.
function Test-Upstream($Dir) {
    $ErrorActionPreference = 'Continue'
    & git -C $Dir rev-parse --verify -q '@{u}' 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

# True when the checkout has uncommitted changes to tracked files, or commits
# its upstream does not have. Untracked files are ignored: vim itself writes
# some (netrw history, help tags).
function Test-LocalChanges($Dir) {
    $ErrorActionPreference = 'Continue'
    $status = & git -C $Dir status --porcelain --untracked-files=no 2>$null
    if ($LASTEXITCODE -eq 0 -and $status) { return $true }
    if (-not (Test-Upstream $Dir)) { return $false }
    $ahead = & git -C $Dir rev-list '@{u}..HEAD' 2>$null
    return ($LASTEXITCODE -eq 0 -and [bool]$ahead)
}

# Fast-forward the git checkout at $Dir. With -Force, a checkout that has local
# changes or cannot fast-forward is moved to $Dir.bak.<stamp> and re-cloned
# from $Url; without it, it is left as-is.
function Update-Checkout($Dir, $Url, $Name) {
    if ($Force -and (Test-LocalChanges $Dir)) {
        Write-Warn "$Dir has local changes - replacing it (-Force)."
    } else {
        & git -C $Dir pull --ff-only | Out-Host
        if ($LASTEXITCODE -eq 0) { return }
        if (-not $Force) {
            Write-Warn "Could not fast-forward $Name; leaving it as-is (re-run with -Force to replace it)."
            return
        }
        Write-Warn "Could not fast-forward $Name - replacing it (-Force)."
    }
    $backup = "$Dir.bak.$(Stamp)"
    Write-Warn "Moving $Dir to $backup"
    Move-Item -LiteralPath $Dir -Destination $backup
    Invoke-Git @('clone', $Url, $Dir) | Out-Null
}

# -Force for the checkout this script is running from, which cannot be moved:
# copy it to $Dir.bak.<stamp>, then hard-reset it to its upstream branch.
function Reset-InPlace($Dir) {
    if (-not (Test-Upstream $Dir)) {
        Write-Warn "$Dir has no upstream branch to reset to; leaving it as-is."
        return
    }
    $backup = "$Dir.bak.$(Stamp)"
    Write-Warn "Copying $Dir to $backup, then resetting it to its upstream (-Force)."
    Copy-Item -LiteralPath $Dir -Destination $backup -Recurse -Force -ErrorAction Stop
    Invoke-Git @('-C', $Dir, 'fetch') -WarnOnFail "git fetch failed in $Dir; leaving it as-is (backup at $backup)." | Out-Null
    if ($LASTEXITCODE -ne 0) { return }
    Invoke-Git @('-C', $Dir, 'reset', '--hard', '@{u}') | Out-Null
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
    Write-Info "Running from the canonical checkout at $VimDir - updating it in place."
    if ($Force -and (Test-LocalChanges $VimDir)) {
        Write-Warn "$VimDir has local changes."
        Reset-InPlace $VimDir
    } else {
        & git -C $VimDir pull --ff-only | Out-Host
        if ($LASTEXITCODE -ne 0) {
            if ($Force) {
                Write-Warn "Could not fast-forward $VimDir."
                Reset-InPlace $VimDir
            } else {
                Write-Warn "Could not fast-forward $VimDir; leaving it as-is (re-run with -Force to reset it)."
            }
        }
    }
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
    Update-Checkout $VimDir $RepoUrl $VimDir
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

Link-File $TargetVimrc $Vimrc

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
    Link-File $TargetIdeaVimrc $IdeaVimrc
}

# --- install or update Vundle ----------------------------------------------
if (Test-Path (Join-Path $VundleDir '.git')) {
    Write-Info 'Vundle already installed - updating it.'
    Update-Checkout $VundleDir $VundleUrl 'Vundle'
} elseif (Test-Path $VundleDir) {
    $backup = "$VundleDir.bak.$(Stamp)"
    Write-Warn "$VundleDir exists but is not a git checkout - moving it to $backup"
    Move-Item -LiteralPath $VundleDir -Destination $backup
    Invoke-Git @('clone', $VundleUrl, $VundleDir) | Out-Null
} else {
    Invoke-Git @('clone', $VundleUrl, $VundleDir) | Out-Null
}

# --- install the plugins ---------------------------------------------------
Write-Info 'Installing and updating plugins via Vundle...'
# With output redirected vim warns "Output is not to a terminal" on stderr,
# which Windows PowerShell 5.1 turns into a terminating error under
# $ErrorActionPreference='Stop'. Relax it for this call only, and check the
# exit code instead.
& {
    $ErrorActionPreference = 'Continue'
    vim +PluginUpdate +qall *> $null
}
if ($LASTEXITCODE -ne 0) {
    throw "Vim exited with code $LASTEXITCODE during plugin installation. Re-run 'vim +PluginUpdate' to retry."
}

Write-Info 'All done! Start vim to enjoy your ABC Vim setup.'
