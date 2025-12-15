# ============================================================
# PowerShell 7 — Fish-like | macOS/Linux | CTF | DevOps | Art
# ============================================================
# Disable Telemetry of Powershell about your profile
$global:PSProfileLoadTime = $null
$env:POWERSHELL_TELEMETRY_OPTOUT = "1"
# --- Silence PowerShell startup noise ---
$Host.UI.RawUI.FlushInputBuffer()

# ---------- Environment ----------
$env:EDITOR = "nvim"
$env:PAGER  = "less"
$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ---------- Oh My Posh ----------
if (Get-Command oh-my-posh -ErrorAction Ignore) {
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/tokyo.omp.json" | Invoke-Expression
}

# ---------- PSReadLine (Fish-like) ----------
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -BellStyle None

Set-PSReadLineKeyHandler Ctrl+A BeginningOfLine
Set-PSReadLineKeyHandler Ctrl+E EndOfLine
Set-PSReadLineKeyHandler Ctrl+W BackwardKillWord
Set-PSReadLineKeyHandler Ctrl+U BackwardDeleteLine
Set-PSReadLineKeyHandler Ctrl+K DeleteLine
Set-PSReadLineKeyHandler Alt+B BackwardWord
Set-PSReadLineKeyHandler Alt+F ForwardWord

# ---------- FZF ----------
if (Get-Command fzf -ErrorAction Ignore) {
    Set-PSReadLineKeyHandler Ctrl+R {
        Get-Content (Get-PSReadLineOption).HistorySavePath |
        fzf --tac --no-sort |
        ForEach-Object { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($_) }
    }
    function ff { fzf --preview 'bat --style=numbers --color=always {}' }
}

# ---------- Auto-cd ----------
Set-PSReadLineOption -CommandValidationHandler {
    param($cmd)
    if (Test-Path $cmd -PathType Container) {
        Set-Location $cmd
        return $false
    }
    return $true
}

# ---------- Z Jump ----------
Import-Module z

# ---------- Aliases ----------
Set-Alias grep Select-String
Set-Alias cat bat
Set-Alias vim nvim
Set-Alias ls lsd
Set-Alias ll "lsd -l"
Set-Alias la "lsd -la"
Set-Alias l "lsd -lA"
Set-Alias laa "lsd -laa"
Set-Alias laaa "lsd -laaa"
Set-Alias lll "lsd -lll"
Set-Alias llll "lsd -llll"

function ..  { cd .. }
function ... { cd ../.. }
function ....{ cd ../../.. }

function ls {
    Get-ChildItem -Force |
    Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
}

# ---------- Git ----------
function gs { git status }
function ga { git add . }
function gc { git commit }
function gp { git push }
function gl { git log --oneline --graph --decorate }

# ---------- CTF Helpers ----------
function httpserve { python -m http.server 8000 }
function ports { netstat -ano | Select-String LISTEN }
function myip  { ipconfig | Select-String IPv4 }

function extract ($f) {
    if ($f -match '\.zip$') { unzip $f }
    elseif ($f -match '\.tar.gz$') { tar -xvzf $f }
    elseif ($f -match '\.tar$') { tar -xvf $f }
}

# ---------- Language Awareness ----------
function Get-VirtualEnv {
    if ($env:VIRTUAL_ENV) { "🐍 $(Split-Path $env:VIRTUAL_ENV -Leaf)" }
    elseif (Test-Path ".venv") { "🐍 .venv" }
}

function Get-NodeVersion {
    if (Get-Command node -ErrorAction Ignore) { " $(node -v)" }
}

function Get-RustVersion {
    if (Get-Command rustc -ErrorAction Ignore) {
        "🦀 $(rustc --version | Select-Object -First 1)"
    }
}

# ============================================================
# Your Custom functions
# ============================================================

function profile {
    Set-Location $PROFILE
}


# ============================================================
# Fortune + Cowsay + fastfetch + Figlet (FINAL)
# ============================================================

# ============================================================
# Fastfetch + Fortune + Cowsay Integration
# ============================================================

# Fastfetch config path
$global:FASTFETCH_CONFIG = "C:\Users\haris\OneDrive\Documents\PowerShell\fastfetch config\config.json"

# Fortune file
$global:FORTUNE_FILE = Join-Path (Split-Path $PROFILE) "fortunes.txt"

# cowsay animals
$global:COWS = @(
    "default","tux","dragon","vader","ghostbusters",
    "moose","sheep","daemon","beavis","cheese"
)

function Get-RandomCow {
    Get-Random $global:COWS
}

# ---------------- Fortune ----------------
function fortune {
    if (!(Test-Path $global:FORTUNE_FILE)) {
        throw "fortune file not found: $global:FORTUNE_FILE"
    }

    [System.IO.File]::ReadAllText($global:FORTUNE_FILE) `
        -replace "`r`n","`n" `
        -split "`n%`n" |
    Get-Random
}

# ---------------- Fortune | Cowsay -------
function Show-FortuneCow {
    if (Get-Command cowsay -ErrorAction Ignore) {
        fortune | cowsay -f (Get-RandomCow)
    }
}

# ---------------- Startup (ONCE) ----------
if (-not $global:HKDEVS_STARTUP_DONE) {
    $global:HKDEVS_STARTUP_DONE = $true

    Microsoft.PowerShell.Utility\Clear-Host

    if (Get-Command fastfetch -ErrorAction Ignore) {
        fastfetch --config $global:FASTFETCH_CONFIG
    }

    Show-FortuneCow
}
Set-Alias cowfortune Show-FortuneCow
# ---------------- clear / cls -------------

function global:clear {
    Microsoft.PowerShell.Utility\Clear-Host
    Show-FortuneCow
}

function global:cls {
    Microsoft.PowerShell.Utility\Clear-Host
    Show-FortuneCow
}
# ============================================================
# FZF Power Functions + Keybindings (Fish-like)
# ============================================================

if (-not (Get-Command fzf -ErrorAction Ignore)) { return }

# ---------- Shared Preview ----------
$env:FZF_DEFAULT_OPTS = @"
--height=40%
--layout=reverse
--border
--ansi
--preview-window=right:60%
"@

# ---------- Ctrl+R : Command History ----------
Set-PSReadLineKeyHandler -Key Ctrl+R -ScriptBlock {
    Get-Content (Get-PSReadLineOption).HistorySavePath |
        fzf --tac --no-sort --preview 'echo {}' |
        ForEach-Object {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($_)
        }
}

# ---------- Ctrl+T : File Finder ----------
function fzf-file {
    fd --type f |
        fzf --preview 'bat --style=numbers --color=always {}'
}
Set-PSReadLineKeyHandler -Key Ctrl+Alt+T -ScriptBlock {
    $file = fzf-file
    if ($file) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($file)
    }
}

# ---------- Alt+C : Directory Jump ----------
function fzf-cd {
    fd --type d |
        fzf --preview 'ls {}'

Set-PSReadLineKeyHandler -Key Alt+C -ScriptBlock {
    $dir = fzf-cd
    if ($dir) { Set-Location $dir }
}
}
# ---------- fkill : Kill Process ----------
function fkill {
    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object Id,ProcessName,CPU |
        fzf |
        ForEach-Object {
            ($_ -split '\s+')[0] | Stop-Process -Force
        }
}

# ---------- fg : Git File Picker ----------
function fg {
    git ls-files |
        fzf --preview 'bat --style=numbers --color=always {}'
}

# ---------- fbr : Git Branch Switch ----------
function fbr {
    git branch --all |
        ForEach-Object { $_.Trim() } |
        fzf |
        ForEach-Object {
            git checkout ($_ -replace 'remotes/origin/','')
        }
}

# ---------- fshow : Git Commit Browser ----------
function fshow {
    git log --oneline --graph --color=always |
        fzf --ansi --preview 'git show {1}'
}

# ---------- fport : Kill Process by Port ----------
function fport {
    netstat -ano |
        Select-String LISTEN |
        fzf |
        ForEach-Object {
            ($_ -split '\s+')[-1] | Stop-Process -Force
        }
}

# ---------- frg : ripgrep + fzf ----------
function frg {
    rg --line-number --no-heading . |
        fzf --delimiter : --preview 'bat --style=numbers --color=always {1} --line-range {2}:'
}

# ---------- fenv : Environment Variables ----------
function fenv {
    Get-ChildItem Env: |
        Sort-Object Name |
        fzf
}

# ---------- fssh : SSH Host Picker ----------
function fssh {
    Get-Content ~/.ssh/config |
        Select-String '^Host ' |
        ForEach-Object { $_.Line -replace 'Host ','' } |
        fzf |
        ForEach-Object { ssh $_ }
}
