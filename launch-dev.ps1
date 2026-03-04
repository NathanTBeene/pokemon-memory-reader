# Dev launcher + hot-restart for BizHawk/EmuHawk using --lua with repo-relative paths.

# Resolve repo root (works when run as a script from VSCode)
$repoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Split-Path -Parent $MyInvocation.MyCommand.Path) }
$emuExe       = Join-Path $repoRoot 'Bizhawk\EmuHawk.exe'
$projectScript = Join-Path $repoRoot 'main.lua'

function Start-Emu {
    if (-not (Test-Path $emuExe)) { Write-Error "EmuHawk not found: $emuExe"; return $null }
    if (-not (Test-Path $projectScript)) { Write-Error "Script not found: $projectScript"; return $null }
    $args = @("--lua", $projectScript)
    Start-Process -FilePath $emuExe -ArgumentList $args -WorkingDirectory (Split-Path $emuExe -Parent) | Out-Null
    Write-Host "Started EmuHawk -> --lua $projectScript"
}

function Kill-Emu {
    try { $exeFull = (Get-Item $emuExe).FullName } catch { return }
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and ($_.Path -ieq $exeFull) }
    if ($procs) {
        Write-Host "Killing existing EmuHawk instances..."
        $procs | Stop-Process -Force
        Start-Sleep -Milliseconds 300
    }
}

# Initial start
Kill-Emu
Start-Emu

# Watcher: restart on changes to main.lua
$watchPath = Split-Path $projectScript -Parent
$watchFilter = Split-Path $projectScript -Leaf
$fsw = New-Object System.IO.FileSystemWatcher $watchPath, $watchFilter
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

$global:DevWatcherLast = Get-Date 0
$action = {
    $now = Get-Date
    if (($now - $global:DevWatcherLast).TotalMilliseconds -lt 400) { return }
    $global:DevWatcherLast = $now
    Start-Sleep -Milliseconds 150
    Write-Host "Change detected. Restarting EmuHawk with --lua $using:projectScript ..."
    Kill-Emu
    Start-Emu
}

Register-ObjectEvent -InputObject $fsw -EventName Changed -Action $action -SourceIdentifier "DevWatcher.Changed" | Out-Null
Register-ObjectEvent -InputObject $fsw -EventName Created -Action $action -SourceIdentifier "DevWatcher.Created" | Out-Null
Register-ObjectEvent -InputObject $fsw -EventName Renamed -Action $action -SourceIdentifier "DevWatcher.Renamed" | Out-Null

Write-Host "Watching $projectScript for changes. Press ENTER to stop. Press 'r' to hot-reload now."

$stop = $false
while (-not $stop) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::R) {
            Write-Host "Manual reload requested. Restarting EmuHawk..."
            Kill-Emu
            Start-Emu
            # reset the debounce timer so the watcher doesn't immediately re-trigger
            $global:DevWatcherLast = Get-Date
        }
        elseif ($key.Key -eq [ConsoleKey]::Enter) {
            $stop = $true
        }
    }
    Start-Sleep -Milliseconds 100
}

# Cleanup
Unregister-Event -SourceIdentifier "DevWatcher.Changed" -ErrorAction SilentlyContinue
Unregister-Event -SourceIdentifier "DevWatcher.Created" -ErrorAction SilentlyContinue
Unregister-Event -SourceIdentifier "DevWatcher.Renamed" -ErrorAction SilentlyContinue
$fsw.EnableRaisingEvents = $false
$fsw.Dispose()
Write-Host "Watcher stopped."

# Kill EmuHawk instances on exit
Kill-Emu
Write-Host "EmuHawk instances closed."