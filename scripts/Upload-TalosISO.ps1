# Talos ISO Upload Script for Proxmox (PowerShell)
# This script downloads the latest Talos OS ISO and uploads it to your Proxmox servers
# 
# Usage: .\scripts\Upload-TalosISO.ps1 [version]
# Example: .\scripts\Upload-TalosISO.ps1 v1.6.1
#          .\scripts\Upload-TalosISO.ps1 latest

param(
    [string]$Version = "latest",
    [switch]$Help,
    [switch]$CacheInfo,
    [switch]$ClearCache
)

# Configuration - Update these with your Proxmox details
$ProxmoxHosts = @("192.168.100.10", "192.168.100.20")  # Your Proxmox server IPs
$ProxmoxUser = "root"                                    # SSH user for Proxmox
$ProxmoxStoragePath = "/var/lib/vz/template/iso"        # ISO storage path on Proxmox
$SSHKeyPath = "$env:USERPROFILE\.ssh\id_rsa"           # Your SSH private key

# Functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Dependencies {
    Write-Log "Checking dependencies..."
    
    $missing = @()
    
    # Check for SSH/SCP (usually comes with Git for Windows)
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        $missing += "ssh"
    }
    if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
        $missing += "scp"
    }
    
    if ($missing.Count -gt 0) {
        Write-Log "Missing required dependencies: $($missing -join ', ')" "ERROR"
        Write-Log "Please install Git for Windows or OpenSSH" "INFO"
        Write-Log "Git for Windows: https://git-scm.com/download/win" "INFO"
        return $false
    }
    
    Write-Log "All dependencies found" "SUCCESS"
    return $true
}

function Get-LatestTalosVersion {
    Write-Log "Fetching latest Talos OS version from GitHub..."
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/siderolabs/talos/releases/latest"
        $latestVersion = $response.tag_name
        
        if ([string]::IsNullOrEmpty($latestVersion)) {
            throw "No version found in API response"
        }
        
        Write-Log "Latest version: $latestVersion" "SUCCESS"
        return $latestVersion
    }
    catch {
        Write-Log "Failed to fetch latest version: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-LocalISOCache {
    param([string]$Version)
    
    $isoFilename = "metal-$Version-amd64.iso"
    
    # Check multiple potential locations
    $cacheLocations = @(
        (Join-Path $env:TEMP "talos-iso-cache\$isoFilename"),
        (Join-Path $env:USERPROFILE "Downloads\$isoFilename"),
        (Join-Path (Get-Location) $isoFilename),
        (Join-Path $env:TEMP $isoFilename)
    )
    
    foreach ($location in $cacheLocations) {
        if (Test-Path $location) {
            $fileSize = (Get-Item $location).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            
            Write-Log "Found existing ISO: $location" "SUCCESS"
            Write-Log "File size: $fileSizeMB MB"
            
            # Verify file is not corrupted (minimum expected size ~100MB)
            if ($fileSize -gt 100MB) {
                Write-Log "Using existing ISO file (skipping download)" "SUCCESS"
                return $location
            }
            else {
                Write-Log "File appears corrupted (too small), will re-download..." "WARNING"
            }
        }
    }
    
    return $null
}

function Download-TalosISO {
    param([string]$Version)
    
    $isoFilename = "metal-$Version-amd64.iso"
    $downloadUrl = "https://github.com/siderolabs/talos/releases/download/$Version/metal-amd64.iso"
    
    # First check if ISO already exists locally
    $existingIso = Test-LocalISOCache -Version $Version
    if ($existingIso) {
        return $existingIso
    }
    
    # Create cache directory for ISOs
    $cacheDir = Join-Path $env:TEMP "talos-iso-cache"
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    $isoPath = Join-Path $cacheDir $isoFilename
    
    Write-Log "No valid local ISO found, downloading Talos OS $Version..." "INFO"
    Write-Log "URL: $downloadUrl"
    
    try {
        # Check if we have internet connectivity
        Write-Log "Testing internet connectivity..."
        try {
            $testConnection = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing
            Write-Log "Internet connectivity confirmed" "SUCCESS"
        }
        catch {
            Write-Log "No internet connection available" "ERROR"
            throw "Cannot download ISO: No internet connection"
        }
        
        # Download with progress
        Write-Log "Downloading to: $isoPath"
        Write-Log "This may take several minutes depending on your connection speed..."
        
        # Use simpler download method for better compatibility
        Write-Progress -Activity "Downloading Talos ISO" -Status "Starting download..." -PercentComplete 0
        
        try {
            # Use Invoke-WebRequest for better compatibility
            Invoke-WebRequest -Uri $downloadUrl -OutFile $isoPath -UseBasicParsing
            Write-Progress -Activity "Downloading Talos ISO" -Completed
        }
        catch {
            Write-Progress -Activity "Downloading Talos ISO" -Completed
            throw "Download failed: $($_.Exception.Message)"
        }
        
        # Verify download
        if (Test-Path $isoPath) {
            $fileSize = (Get-Item $isoPath).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            
            if ($fileSize -gt 100MB) {
                Write-Log "Downloaded Talos ISO successfully" "SUCCESS"
                Write-Log "File size: $fileSizeMB MB"
                Write-Log "ISO cached at: $isoPath"
                return $isoPath
            }
            else {
                throw "Downloaded file appears corrupted (size: $fileSizeMB MB)"
            }
        }
        else {
            throw "Download completed but file not found"
        }
    }
    catch {
        Write-Log "Failed to download Talos ISO: $($_.Exception.Message)" "ERROR"
        Remove-Item -Path $isoPath -Force -ErrorAction SilentlyContinue
        throw
    }
}

function Test-SSHConnection {
    param([string]$ProxmoxHost)
    
    Write-Log "Testing SSH connection to $ProxmoxHost..."
    
    $sshArgs = @(
        "-i", $SSHKeyPath,
        "-o", "ConnectTimeout=10",
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=no",
        "$ProxmoxUser@$ProxmoxHost",
        "echo 'SSH connection successful'"
    )
    
    try {
        $result = & ssh @sshArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "SSH connection to $ProxmoxHost successful" "SUCCESS"
            return $true
        }
        else {
            Write-Log "SSH connection to $ProxmoxHost failed" "ERROR"
            Write-Log "Please ensure:" "INFO"
            Write-Log "  - SSH key is correct: $SSHKeyPath" "INFO"
            Write-Log "  - Proxmox host is reachable: $ProxmoxHost" "INFO"
            Write-Log "  - SSH user has access: $ProxmoxUser" "INFO"
            return $false
        }
    }
    catch {
        Write-Log "SSH test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-RemoteFileExists {
    param([string]$ProxmoxHost, [string]$RemoteFilePath)
    
    try {
        $checkArgs = @(
            "-i", $SSHKeyPath,
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            "$ProxmoxUser@$ProxmoxHost",
            "test -f '$RemoteFilePath' && echo 'EXISTS' || echo 'NOT_FOUND'"
        )
        
        $result = & ssh @checkArgs 2>&1
        return ($result -eq "EXISTS")
    }
    catch {
        return $false
    }
}

function Get-RemoteFileSize {
    param([string]$ProxmoxHost, [string]$RemoteFilePath)
    
    try {
        $sizeArgs = @(
            "-i", $SSHKeyPath,
            "-o", "StrictHostKeyChecking=no",
            "$ProxmoxUser@$ProxmoxHost",
            "stat -c %s '$RemoteFilePath' 2>/dev/null || echo '0'"
        )
        
        $sizeBytes = & ssh @sizeArgs 2>&1
        return [long]($sizeBytes -replace '\D', '')
    }
    catch {
        return 0
    }
}

function Upload-ToProxmox {
    param([string]$IsoPath, [string]$ProxmoxHost)
    
    $isoFilename = Split-Path $IsoPath -Leaf
    $remotePath = "$ProxmoxStoragePath/$isoFilename"
    
    Write-Log "Processing Proxmox host: $ProxmoxHost"
    
    # Check SSH connection
    if (-not (Test-SSHConnection -ProxmoxHost $ProxmoxHost)) {
        return $false
    }
    
    # Check if file already exists on remote server
    if (Test-RemoteFileExists -ProxmoxHost $ProxmoxHost -RemoteFilePath $remotePath) {
        $remoteSize = Get-RemoteFileSize -ProxmoxHost $ProxmoxHost -RemoteFilePath $remotePath
        $localSize = (Get-Item $IsoPath).Length
        $remoteSizeMB = [math]::Round($remoteSize / 1MB, 2)
        
        Write-Log "ISO already exists on $ProxmoxHost" "SUCCESS"
        Write-Log "Remote file size: $remoteSizeMB MB"
        
        # Compare file sizes to verify integrity
        if ($remoteSize -eq $localSize -and $remoteSize -gt 100MB) {
            Write-Log "File sizes match - skipping upload to $ProxmoxHost" "SUCCESS"
            return $true
        }
        else {
            Write-Log "File size mismatch or corrupted file - re-uploading..." "WARNING"
            Write-Log "Local: $([math]::Round($localSize / 1MB, 2)) MB, Remote: $remoteSizeMB MB"
        }
    }
    
    try {
        # Create storage directory if it doesn't exist
        $sshArgs = @(
            "-i", $SSHKeyPath,
            "-o", "StrictHostKeyChecking=no",
            "$ProxmoxUser@$ProxmoxHost",
            "mkdir -p $ProxmoxStoragePath"
        )
        & ssh @sshArgs
        
        # Upload the ISO file
        Write-Log "Uploading $isoFilename to $ProxmoxHost`:$ProxmoxStoragePath/"
        
        $scpArgs = @(
            "-i", $SSHKeyPath,
            "-o", "StrictHostKeyChecking=no",
            $IsoPath,
            "$ProxmoxUser@$ProxmoxHost`:$ProxmoxStoragePath/"
        )
        
        & scp @scpArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully uploaded ISO to $ProxmoxHost" "SUCCESS"
            
            # Verify the file exists and get size
            $remoteSize = Get-RemoteFileSize -ProxmoxHost $ProxmoxHost -RemoteFilePath $remotePath
            $remoteSizeMB = [math]::Round($remoteSize / 1MB, 2)
            Write-Log "Remote file size: $remoteSizeMB MB"
            
            return $true
        }
        else {
            Write-Log "Failed to upload ISO to $ProxmoxHost" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Upload failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-CacheInfo {
    $cacheDir = Join-Path $env:TEMP "talos-iso-cache"
    $downloadsDir = Join-Path $env:USERPROFILE "Downloads"
    
    Write-Host "`nLocal ISO Cache Information:" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    
    $totalSize = 0
    $fileCount = 0
    
    # Check cache directory
    if (Test-Path $cacheDir) {
        $cacheFiles = Get-ChildItem -Path $cacheDir -Filter "metal-*-amd64.iso" -ErrorAction SilentlyContinue
        foreach ($file in $cacheFiles) {
            $sizeMB = [math]::Round($file.Length / 1MB, 2)
            $totalSize += $sizeMB
            $fileCount++
            Write-Host "Cache: $($file.Name) ($sizeMB MB)" -ForegroundColor Green
        }
    }
    
    # Check downloads directory
    $downloadFiles = Get-ChildItem -Path $downloadsDir -Filter "metal-*-amd64.iso" -ErrorAction SilentlyContinue
    foreach ($file in $downloadFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        $totalSize += $sizeMB
        $fileCount++
        Write-Host "Downloads: $($file.Name) ($sizeMB MB)" -ForegroundColor Yellow
    }
    
    # Check current directory
    $currentFiles = Get-ChildItem -Path (Get-Location) -Filter "metal-*-amd64.iso" -ErrorAction SilentlyContinue
    foreach ($file in $currentFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        $totalSize += $sizeMB
        $fileCount++
        Write-Host "Current: $($file.Name) ($sizeMB MB)" -ForegroundColor Magenta
    }
    
    if ($fileCount -eq 0) {
        Write-Host "No Talos ISO files found in cache" -ForegroundColor Gray
    }
    else {
        Write-Host "`nTotal: $fileCount files, $totalSize MB" -ForegroundColor White
        Write-Host "Cache directory: $cacheDir" -ForegroundColor Gray
    }
}

function Clear-ISOCache {
    $cacheDir = Join-Path $env:TEMP "talos-iso-cache"
    
    if (Test-Path $cacheDir) {
        try {
            $files = Get-ChildItem -Path $cacheDir -Filter "metal-*-amd64.iso"
            $totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
            
            if ($files.Count -gt 0) {
                Write-Log "Found $($files.Count) cached ISO files ($([math]::Round($totalSize, 2)) MB)" "INFO"
                $response = Read-Host "Clear ISO cache? (y/N)"
                
                if ($response -eq 'y' -or $response -eq 'Y') {
                    Remove-Item -Path "$cacheDir\metal-*-amd64.iso" -Force
                    Write-Log "ISO cache cleared" "SUCCESS"
                }
                else {
                    Write-Log "Cache clearing cancelled" "INFO"
                }
            }
            else {
                Write-Log "No ISO files found in cache" "INFO"
            }
        }
        catch {
            Write-Log "Failed to clear cache: $($_.Exception.Message)" "ERROR"
        }
    }
    else {
        Write-Log "No cache directory found" "INFO"
    }
}

function Show-Help {
    Write-Host @"
Talos ISO Upload Script for Proxmox (PowerShell)

Usage: .\scripts\Upload-TalosISO.ps1 [options] [version]

Examples:
  .\scripts\Upload-TalosISO.ps1                 # Download and upload latest version
  .\scripts\Upload-TalosISO.ps1 latest          # Download and upload latest version
  .\scripts\Upload-TalosISO.ps1 v1.6.1          # Download and upload specific version
  .\scripts\Upload-TalosISO.ps1 -CacheInfo      # Show cached ISO information
  .\scripts\Upload-TalosISO.ps1 -ClearCache     # Clear cached ISO files

Smart Features:
  - Automatically detects existing local ISOs (cache, downloads, current directory)
  - Skips download if valid ISO already exists locally
  - Skips upload if ISO already exists on Proxmox server with correct size
  - Verifies file integrity by comparing file sizes
  - Shows progress during download and upload operations

Configuration:
  Edit the script to update ProxmoxHosts, ProxmoxUser, and SSHKeyPath

Requirements:
  - SSH and SCP commands (Git for Windows includes these)
  - SSH key access to Proxmox hosts
  - Internet connection to download ISO (only if not cached)
  - PowerShell 5.0 or later
"@
}

# Main execution
function Main {
    param([string]$RequestedVersion)
    
    Write-Log "Starting Talos ISO upload process..."
    Write-Log "Target Proxmox hosts: $($ProxmoxHosts -join ', ')"
    
    # Check dependencies
    if (-not (Test-Dependencies)) {
        exit 1
    }
    
    # Check if SSH key exists
    if (-not (Test-Path $SSHKeyPath)) {
        Write-Log "SSH key not found at: $SSHKeyPath" "ERROR"
        Write-Log "Please ensure your SSH key exists or update SSHKeyPath in the script" "INFO"
        exit 1
    }
    
    try {
        # Get version
        if ($RequestedVersion -eq "latest") {
            $RequestedVersion = Get-LatestTalosVersion
        }
        
        # Download ISO
        $isoPath = Download-TalosISO -Version $RequestedVersion
        
        # Upload to each Proxmox host
        $uploadCount = 0
        $failedHosts = @()
        
        foreach ($proxmoxHost in $ProxmoxHosts) {
            Write-Log "Processing Proxmox host: $proxmoxHost"
            
            if (Upload-ToProxmox -IsoPath $isoPath -ProxmoxHost $proxmoxHost) {
                $uploadCount++
            }
            else {
                $failedHosts += $proxmoxHost
            }
            
            Write-Host "----------------------------------------"
        }
        
        # Keep ISO in cache for future use (don't delete)
        Write-Log "ISO cached for future use: $isoPath" "INFO"
        Write-Log "Run with -CacheInfo to see all cached ISOs" "INFO"
        
        # Summary
        Write-Host ""
        Write-Log "Upload Summary:"
        Write-Log "Successfully uploaded to $uploadCount/$($ProxmoxHosts.Count) hosts" "SUCCESS"
        
        if ($failedHosts.Count -gt 0) {
            Write-Log "Failed uploads: $($failedHosts -join ', ')" "WARNING"
        }
        
        Write-Host ""
        Write-Log "Talos ISO location on Proxmox: $ProxmoxStoragePath/metal-$RequestedVersion-amd64.iso"
        Write-Log "Use in Terraform as: local:iso/metal-$RequestedVersion-amd64.iso"
        
        Write-Host ""
        Write-Log "Talos ISO upload process completed!" "SUCCESS"
        
        if ($failedHosts.Count -gt 0) {
            exit 1
        }
    }
    catch {
        Write-Log "Script failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Script entry point
if ($Help) {
    Show-Help
    exit 0
}

if ($CacheInfo) {
    Show-CacheInfo
    exit 0
}

if ($ClearCache) {
    Clear-ISOCache
    exit 0
}

Main -RequestedVersion $Version 