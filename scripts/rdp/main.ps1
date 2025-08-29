# Download and import registry file for BetterRDP
$regFileUrl = "https://raw.githubusercontent.com/Upinel/BetterRDP/main/UpinelBetterRDP.reg"
$regFilePath = "$env:TEMP\UpinelBetterRDP.reg"
Invoke-WebRequest -Uri $regFileUrl -OutFile $regFilePath


# Download CentBrowser
$chromeInstallerUrl = "https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83_x64_portable.exe"
$installerPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "centbrowser_installer.exe")

# Multi-threaded download function using BITS
function Download-FileWithBITS {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        Write-Output "开始下载: $Url"
        Start-BitsTransfer -Source $Url -Destination $OutputPath -Priority High
        Write-Output "下载完成: $OutputPath"
        return $true
    }
    catch {
        Write-Warning "BITS 下载失败，尝试使用 WebClient: $_"
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $OutputPath)
            $webClient.Dispose()
            Write-Output "WebClient 下载完成: $OutputPath"
            return $true
        }
        catch {
            Write-Error "所有下载方法都失败: $_"
            return $false
        }
    }
}

# Download CentBrowser using multi-threaded approach
if (Download-FileWithBITS -Url $chromeInstallerUrl -OutputPath $installerPath) {
    Write-Output "CentBrowser 下载成功"
    
    # Extract CentBrowser to subdirectory
    $extractDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "centbrowser")
    
    try {
        # Create extraction directory
        if (-not (Test-Path $extractDir)) {
            New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        }
        
        # Extract using 7-Zip if available, otherwise use built-in methods
        Write-Output "正在解压 CentBrowser 到: $extractDir"
        
        # Method 1: Try using 7-Zip (if installed)
        $7zipPath = "C:\Program Files\7-Zip\7z.exe"
        if (Test-Path $7zipPath) {
            & $7zipPath x "$installerPath" "-o$extractDir" -y | Out-Null
            Write-Output "使用 7-Zip 解压完成"
        }
        # Method 2: Try using Expand-Archive (for newer Windows)
        elseif (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
            Expand-Archive -Path $installerPath -DestinationPath $extractDir -Force
            Write-Output "使用 Expand-Archive 解压完成"
        }
        # Method 3: Fallback to manual extraction (self-extracting EXE)
        else {
            Write-Warning "未找到解压工具，尝试运行自解压程序"
            Start-Process -FilePath $installerPath -ArgumentList @("/S", "/D=$extractDir") -Wait
            Write-Output "自解压程序执行完成"
        }
        
        # Clean up installer if extraction was successful
        if (Test-Path $extractDir) {
            Remove-Item $installerPath -Force
            Write-Output "安装程序已清理，CentBrowser 已解压到: $extractDir"
            
            # Create User Data directory structure for caching
            $userDataDir = Join-Path $extractDir "User Data"
            if (-not (Test-Path $userDataDir)) {
                New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
                Write-Output "已创建 User Data 目录用于缓存: $userDataDir"
            }
        }
        
    }
    catch {
        Write-Warning "解压过程中出现错误: $_"
        Write-Output "CentBrowser 安装程序保留在: $installerPath"
    }
    
} else {
    Write-Error "CentBrowser 下载失败"
}



# Import registry
if (Test-Path $regFilePath) {
    & cmd /c "reg import `"$regFilePath`""
    if ($LASTEXITCODE -eq 0) {
        Write-Output "注册表文件导入成功"
    }
    else {
        Write-Error "注册表导入失败，退出码：$LASTEXITCODE"
        exit 1
    }
}
else {
    Write-Error "未找到注册表文件：$regFilePath"
    exit 1
}

# uninstall specified software from the system
$softwareList = @(
    "Epic Games Launcher",
    "Mozilla Firefox",
    "Google Chrome",
    "Unity Hub"
)

foreach ($name in $softwareList) {
    $keys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($key in $keys) {
        Get-ItemProperty $key 2>$null | Where-Object {
            $_.DisplayName -like "*$name*"
        } | ForEach-Object {
            $uninstall = $_.UninstallString
            if ($uninstall) {
                Write-Host "Uninstalling: $($_.DisplayName)"
                
                # 自动处理 MSI 和 EXE 路径加静默参数
                if ($uninstall -match "msiexec\.exe") {
                    $silent = "$uninstall /qn /norestart"
                }
                elseif ($uninstall -match "\.exe") {
                    $silent = "$uninstall /S"
                }
                else {
                    $silent = $uninstall
                }
                
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $silent -Wait
            }
        }
    }
}

# Disable taskbar grouping
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarGlomLevel' -Value 2 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarGlomLevel' -Value 2 -Type DWord -Force

# Show file extensions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Type DWord -Force

# Enable Remote Desktop and configure settings
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
Set-LocalUser -Name "runneradmin" -Password (ConvertTo-SecureString -AsPlainText "12345Ab@" -Force)
Set-ItemProperty -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LimitBlankPasswordUse' -Value 0 -force
