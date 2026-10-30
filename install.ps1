# ThatCoding Windows Installer (PowerShell)
$ErrorActionPreference = 'Stop'

$Repo = "MOINtwentysix/ThatCoding"
$InstallDir = "$HOME\.thatcoding\bin"
$CommandName = "tac"

Write-Host "Installing ThatCoding ($CommandName)..." -ForegroundColor Cyan

$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -match 'ARM64') { 'arm64' } else { 'x64' }
} else {
    Write-Error "Unsupported architecture (32-bit is not supported)."
}

# Determine release tag (supports regular releases AND pre-releases)
$Tag = $env:VERSION
if (-not $Tag) {
    try {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -ErrorAction SilentlyContinue
        if ($releases -and $releases.Count -gt 0) {
            $Tag = $releases[0].tag_name
        }
    } catch {}
}

$BaseUrl = if ($Tag) {
    "https://github.com/$Repo/releases/download/$Tag"
} else {
    "https://github.com/$Repo/releases/latest/download"
}

$ArchiveFile = "thatcoding-windows-$Arch.zip"
$Url = "$BaseUrl/$ArchiveFile"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$TempZip = Join-Path $env:TEMP $ArchiveFile

Write-Host "Downloading $Url..." -ForegroundColor DarkGray
try {
    Invoke-WebRequest -Uri $Url -OutFile $TempZip
} catch {
    $FallbackUrl = "https://github.com/$Repo/releases/latest/download/$ArchiveFile"
    Write-Host "Direct download failed, trying $FallbackUrl..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $FallbackUrl -OutFile $TempZip
}

Write-Host "Extracting to $InstallDir..." -ForegroundColor DarkGray
Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force
Remove-Item $TempZip -Force

# Create tac.cmd and thatcoding.cmd
@"
@echo off
"%~dp0thatcoding.exe" %*
exit /b %errorlevel%
"@ | Set-Content -Path (Join-Path $InstallDir "tac.cmd") -Encoding ASCII

@"
@echo off
"%~dp0thatcoding.exe" %*
exit /b %errorlevel%
"@ | Set-Content -Path (Join-Path $InstallDir "thatcoding.cmd") -Encoding ASCII

# Add to User PATH if not present
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$UserPath", "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Host "Added $InstallDir to User PATH." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "ThatCoding has been installed successfully!" -ForegroundColor Green
Write-Host "You can now run: $CommandName" -ForegroundColor Yellow
Write-Host ""
