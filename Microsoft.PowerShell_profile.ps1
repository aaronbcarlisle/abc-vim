# ===========================
# Color Definitions (matching .bashrc)
# ===========================

# ANSI Color Codes
$script:Color_Off = "`e[0m"

# Regular Colors
$script:Black = "`e[0;30m"
$script:Red = "`e[0;31m"
$script:Green = "`e[0;32m"
$script:Yellow = "`e[0;33m"
$script:Blue = "`e[0;34m"
$script:Purple = "`e[0;35m"
$script:Cyan = "`e[0;36m"
$script:White = "`e[0;37m"

# Bold
$script:BBlack = "`e[1;30m"
$script:BRed = "`e[1;31m"
$script:BGreen = "`e[1;32m"
$script:BYellow = "`e[1;33m"
$script:BBlue = "`e[1;34m"
$script:BPurple = "`e[1;35m"
$script:BCyan = "`e[1;36m"
$script:BWhite = "`e[1;37m"

# High Intensity
$script:IBlack = "`e[0;90m"
$script:IRed = "`e[0;91m"
$script:IGreen = "`e[0;92m"
$script:IYellow = "`e[0;93m"
$script:IBlue = "`e[0;94m"
$script:IPurple = "`e[0;95m"
$script:ICyan = "`e[0;96m"
$script:IWhite = "`e[0;97m"

# Bold High Intensity
$script:BIBlack = "`e[1;90m"
$script:BIRed = "`e[1;91m"
$script:BIGreen = "`e[1;92m"
$script:BIYellow = "`e[1;93m"
$script:BIBlue = "`e[1;94m"
$script:BIPurple = "`e[1;95m"
$script:BICyan = "`e[1;96m"
$script:BIWhite = "`e[1;97m"

# ===========================
# PSReadLine Configuration
# ===========================

# Configure PSReadLine prediction settings (only in interactive sessions)
# HistoryAndPlugin combines command/alias predictions with command history
# This ensures pre-seeded aliases and your actual command history both appear in suggestions
if (Get-Module -Name PSReadLine) {
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -HistoryNoDuplicates
    } catch {
        # Silently ignore if not supported in this console
    }
}

# PSReadLine color customization (matching bash theme)
if (Get-Module -Name PSReadLine) {
    try {
        Set-PSReadLineOption -Colors @{
            Command            = 'Green'
            Parameter          = 'Gray'
            Operator           = 'Magenta'
            Variable           = 'Yellow'
            String             = 'Cyan'
            Number             = 'Cyan'
            Type               = 'DarkGray'
            Comment            = 'DarkGray'
            Keyword            = 'Green'
            Error              = 'Red'
            Selection          = "$($PSStyle.Background.BrightBlack)"
            InlinePrediction   = 'DarkGray'
        }
    } catch {
        # Silently ignore if not supported in this console
    }
}

# Pre-seed aliases into PSReadLine history for auto-suggestions
# This ensures aliases appear in suggestions even after clearing history or reloading shell
# Only runs in interactive sessions where PSReadLine is available
if ($Host.UI.SupportsVirtualTerminal -and (Get-Module -Name PSReadLine)) {
    $aliasesToPreload = @(
        # Helper commands
        'reload',
        'mkdirpop',
        'open',
        'profilehelp',

        # Editor
        'vim',

        # Grep utilities
        'cgrep',
        'hgrep',
        'fgrep',

        # Applications
        'claude',

        # Config file editors
        'vimrc',
        'claudemd',
        'pwsprofile',

        # Navigation shortcuts
        'cddev',
        'cdfn',
        'cdprojects',
        'cddevsandbox',
        'cdpycharmtools',
        'cddevcache',
        'cdappdata',

        # Directory stack
        'pushd',
        'popd'
    )

    foreach ($alias in $aliasesToPreload) {
        try {
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($alias)
        } catch {
            # Silently ignore errors (e.g., in non-interactive sessions)
        }
    }
}

# Custom argument completer to prioritize: 1) Aliases, 2) Commands, 3) History last
Register-ArgumentCompleter -CommandName * -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    # Get all matching aliases first (Priority 1)
    $aliases = Get-Alias -Name "$wordToComplete*" -ErrorAction SilentlyContinue |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.Name,
                $_.Name,
                'ParameterValue',
                "Alias -> $($_.Definition)"
            )
        }

    # Get matching commands second (Priority 2)
    # Includes cmdlets, functions, applications in $PATH
    $commands = Get-Command -Name "$wordToComplete*" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -ne 'Alias' } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_.Name,
                $_.Name,
                'Command',
                "$($_.CommandType)"
            )
        }

    # Return: Aliases first, Commands second
    # History will be suggested last automatically by PSReadLine
    $aliases + $commands
}

# Custom Tab handler with state tracking
$global:__lastTabWasAccept = $false

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # If we just accepted a suggestion, now do tab completion
    if ($global:__lastTabWasAccept) {
        $global:__lastTabWasAccept = $false
        [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
        return
    }

    # Try to accept suggestion if cursor is at end
    if ($cursor -eq $line.Length) {
        $beforeLine = $line
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion()

        # Check if anything changed
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($line -ne $beforeLine) {
            # Suggestion was accepted
            $global:__lastTabWasAccept = $true
            return
        }
    }

    # No suggestion to accept, do normal tab completion
    [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
}

# Reset flag on any other key
Set-PSReadLineKeyHandler -Key Spacebar -ScriptBlock {
    $global:__lastTabWasAccept = $false
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(' ')
}

# ===========================
# Helper Functions
# ===========================

function Reload-Console {
    Clear-Host
    Write-Host "Reloading Console..."
    # Get the path of the current PowerShell executable
    $powershellPath = Get-Process -Id $PID | Select-Object -ExpandProperty Path

    # Start a new PowerShell process using the same executable path
    Start-Process -FilePath $powershellPath -NoNewWindow

    # Exit the current session
    exit
}

# Create directory and cd into it (like bash mkdirpop)
function New-DirectoryAndEnter {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Push-Location $Path
}

# Open current directory in File Explorer
function Open-CurrentDirectory {
    Start-Process explorer.exe -ArgumentList (Get-Location).Path
}

# Display all aliases and functions defined in this profile
function Show-ProfileHelp {
    Write-Host "`n${script:BCyan}PowerShell Profile - Available Aliases & Functions${script:Color_Off}`n" -ForegroundColor Cyan

    Write-Host "${script:BYellow}Helper Commands:${script:Color_Off}"
    Write-Host "  reload           - Reload PowerShell console"
    Write-Host "  mkdirpop <path>  - Create directory and cd into it"
    Write-Host "  open             - Open current directory in File Explorer"

    Write-Host "`n${script:BYellow}Editor:${script:Color_Off}"
    Write-Host "  vim              - Launch console Vim"
    Write-Host "  gvim             - Launch GUI Vim"

    Write-Host "`n${script:BYellow}Grep Utilities:${script:Color_Off}"
    Write-Host "  cgrep <pattern>  - Color grep (search in files)"
    Write-Host "  hgrep <pattern>  - History grep (search command history)"
    Write-Host "  fgrep <pattern>  - Find grep (search file names)"

    Write-Host "`n${script:BYellow}Applications:${script:Color_Off}"
    Write-Host "  claude           - Start Claude Code gateway"

    Write-Host "`n${script:BYellow}Config File Editors:${script:Color_Off}"
    Write-Host "  vimrc            - Edit .vimrc"
    Write-Host "  claudemd         - Edit CLAUDE.md"
    Write-Host "  pwsprofile       - Edit PowerShell profile"

    Write-Host "`n${script:BYellow}Navigation Shortcuts:${script:Color_Off}"
    Write-Host "  cddev            - Go to D:/Dev"
    Write-Host "  cdfn             - Go to D:/Fortnite"
    Write-Host "  cdprojects       - Go to D:/Projects"
    Write-Host "  cddevsandbox     - Go to Desktop/dev-sandbox"
    Write-Host "  cdpycharmtools   - Go to PyCharm tools directory"
    Write-Host "  cddevcache       - Go to UnPipe dev-cache"
    Write-Host "  cdappdata        - Go to AppData/Roaming"

    Write-Host "`n${script:BYellow}Directory Stack:${script:Color_Off}"
    Write-Host "  pushd <path>     - Push location onto stack and cd"
    Write-Host "  popd             - Pop location from stack and cd back"

    Write-Host "`n${script:BYellow}Profile Info:${script:Color_Off}"
    Write-Host "  profilehelp      - Show this help message"
    Write-Host ""
}

# Grep aliases (matching .bashrc)
function Invoke-ColorGrep {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$AdditionalArgs
    )
    Select-String -Pattern $Pattern -Path $AdditionalArgs -Recurse -CaseSensitive -Context 0,0 |
        ForEach-Object {
            Write-Host "$($_.Path):$($_.LineNumber):" -NoNewline -ForegroundColor Cyan
            Write-Host $_.Line
        }
}

function Invoke-HistoryGrep {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )
    Get-History | Where-Object { $_.CommandLine -match $Pattern } |
        ForEach-Object {
            Write-Host "$($_.Id):" -NoNewline -ForegroundColor Cyan
            Write-Host $_.CommandLine
        }
}

function Invoke-FindGrep {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Pattern
    )
    Get-ChildItem -Recurse -File | Where-Object { $_.FullName -match $Pattern } |
        ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Cyan
        }
}

# ===========================
# Application Launchers
# ===========================

function Start-Claude {
    Clear-Host
    Write-Host "Running claude-gateway..."
    claude-gateway
}

# ===========================
# Config File Editors
# ===========================

function Edit-Claude-MD {
    Clear-Host
    Write-Host "Opening CLAUDE.md in Vim..."
    vim ~/.claude/CLAUDE.md
}

function Edit-Vimrc {
    Clear-Host
    Write-Host "Opening .vimrc in Vim..."
    vim ~/.vimrc
}

function Edit-PowerShell-Profile {
    Clear-Host
    Write-Host "Opening PowerShell Profile in Vim..."
    vim "$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
}

# ===========================
# Navigation Functions
# ===========================
# All navigation functions use Push-Location so you can always use popd to go back

function Set-LocationDev {
    Push-Location D:/Dev
}

function Set-LocationFortnite {
    Push-Location D:/Fortnite
}

function Set-LocationProjects {
    Push-Location D:/Projects
}

function Set-LocationDevSandbox {
    Push-Location C:/Users/aaron.carlisle/Desktop/dev-sandbox
}

function Set-LocationPyCharmTools {
    Push-Location "$env:APPDATA/JetBrains/PyCharm2025.2/tools"
}

function Set-LocationDevCache {
    Push-Location "$env:APPDATA/UnPipe/dev-cache"
}

function Set-LocationAppData {
    Push-Location $env:APPDATA
}

# ===========================
# Aliases
# ===========================

# Helper commands
Set-Alias -Name reload -Value Reload-Console
Set-Alias -Name mkdirpop -Value New-DirectoryAndEnter
Set-Alias -Name open -Value Open-CurrentDirectory
Set-Alias -Name profilehelp -Value Show-ProfileHelp

# Vim - using console vim (no alias needed, vim is available in PATH)

# Grep aliases (matching .bashrc)
Set-Alias -Name cgrep -Value Invoke-ColorGrep
Set-Alias -Name hgrep -Value Invoke-HistoryGrep
Set-Alias -Name fgrep -Value Invoke-FindGrep

# Applications
Set-Alias -Name claude -Value Start-Claude

# Config file editors
Set-Alias -Name vimrc -Value Edit-Vimrc
Set-Alias -Name claudemd -Value Edit-Claude-MD
Set-Alias -Name pwsprofile -Value Edit-PowerShell-Profile

# Navigation shortcuts
Set-Alias -Name cddev -Value Set-LocationDev
Set-Alias -Name cdfn -Value Set-LocationFortnite
Set-Alias -Name cdprojects -Value Set-LocationProjects
Set-Alias -Name cddevsandbox -Value Set-LocationDevSandbox
Set-Alias -Name cdpycharmtools -Value Set-LocationPyCharmTools
Set-Alias -Name cddevcache -Value Set-LocationDevCache
Set-Alias -Name cdappdata -Value Set-LocationAppData

# Directory stack navigation (bash-like)
# Note: popd and pushd are built-in PowerShell aliases with AllScope option
# They already map to Pop-Location and Push-Location, so no need to set them

# ===========================
# Custom Prompt (matching .bashrc git-aware prompt)
# ===========================

function prompt {
    # Get current time (12-hour format)
    $time = Get-Date -Format "hh:mm:ss tt"

    # Get current path (use ~ for home directory)
    $path = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    $homePath = [Environment]::GetFolderPath('UserProfile')
    if ($path -eq $homePath) {
        $path = "~"
    } elseif ($path.StartsWith($homePath)) {
        $path = "~" + $path.Substring($homePath.Length)
    }

    # Check if we're in a git repository
    $gitBranch = $null
    $isClean = $false

    try {
        $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($gitBranch) {
            $gitStatus = git status --porcelain 2>$null
            $isClean = [string]::IsNullOrWhiteSpace($gitStatus)
        }
    } catch {
        $gitBranch = $null
    }

    # Build prompt string
    $promptString = ""

    # Add time in dark gray
    $promptString += "${script:IBlack}${time}${script:Color_Off}"

    if ($gitBranch) {
        # In git repo - show branch with color based on status
        if ($isClean) {
            # Clean repo - green branch
            $promptString += "${script:Green} ${gitBranch}${script:Color_Off} "
        } else {
            # Dirty repo - red branch
            $promptString += "${script:IRed} ${gitBranch}${script:Color_Off} "
        }
        # Path in bold cyan
        $promptString += "${script:BCyan}${path}${script:Color_Off}`$ "
    } else {
        # Not in git repo
        $promptString += " ${script:Cyan}${path}${script:Color_Off}`$ "
    }

    return $promptString
}
