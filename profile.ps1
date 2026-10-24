# All-hosts profile (every PowerShell host).
# Startup critical path only: nothing here may block for more than a few ms.

# ─── Oh-My-Posh — only for hosts whose current-host profile does not init it ──
# (ConsoleHost / Otty / Windows Terminal load the current-host profile, which
# initializes the same Half-Life theme; skip the duplicate work.)
if ($Host.Name -ne 'ConsoleHost') {
    $ompTheme = Join-Path $env:USERPROFILE '.config\oh-my-posh\half-life.omp.json'
    if ((Test-Path $ompTheme) -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    }
}

# Fast existence probes: Get-Command walks every PATH directory (~30-80 ms each).
# Known install locations are checked first; Get-Command stays as fallback.
function Test-FastCommand {
    param([string]$Name)
    foreach ($dir in @((Join-Path $HOME 'scoop\shims'), (Join-Path $HOME '.local\bin'), (Join-Path $env:LOCALAPPDATA 'Programs'))) {
        foreach ($ext in '.exe', '.cmd', '.bat', '.ps1') {
            if (Test-Path -LiteralPath (Join-Path $dir ($Name + $ext))) { return $true }
        }
    }
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ─── zoxide cd replacement (alias only — the binary is queried on demand) ─────
if (Test-FastCommand zoxide) {
    Set-Alias -Name z -Value zoxide
    function cdz { param([string]$arg) if ($arg) { zoxide query $arg | Set-Location } else { zoxide query -i | Set-Location } }
    Set-Alias -Name zi -Value cdz
}

# ─── Bat man-pages ────────────────────────────────────────────────────────────
if (Test-FastCommand bat) {
    $env:MANPAGER = "sh -c 'col -bx | bat -l man -p'"
}

# ─── fzf + PSFzf — lazily imported ────────────────────────────────────────────
# PSFzf's Import-Module + Set-PsFzfOption cost >1s at startup. It is now loaded
# the first time Ctrl+R / Ctrl+T is pressed (or by running Enable-PSFzf).
if (Test-FastCommand fzf) {
    $script:PSFzfLoaded = $false

    function Enable-PSFzf {
        if ($script:PSFzfLoaded) { return }
        $script:PSFzfLoaded = $true
        Import-Module PSFzf -ErrorAction SilentlyContinue
        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            Set-PsFzfOption -EnableCtrlT -EnableCtrlR -EnableAltC
        }
    }

    if ($Host.Name -eq 'ConsoleHost' -and (Get-Module -Name PSReadLine)) {
        # First press loads PSFzf (which rebinds these); built-in search is used
        # for the very first press so the key is never dead.
        Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
            Enable-PSFzf
            [Microsoft.PowerShell.PSConsoleReadLine]::ReverseSearchHistory()
        }
        Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
            Enable-PSFzf
        }
    }
}
