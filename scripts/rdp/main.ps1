# Download and import registry file for BetterRDP
$regFileUrl = "https://raw.githubusercontent.com/Upinel/BetterRDP/main/UpinelBetterRDP.reg"
$regFilePath = "$env:TEMP\UpinelBetterRDP.reg"
Invoke-WebRequest -Uri $regFileUrl -OutFile $regFilePath


# Download CentBrowser
$chromeInstallerUrl = "https://static.centbrowser.com/win_stable/5.2.1168.74/centbrowser_5.2.1168.74_x64_portable.exe"
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

# Enable Remote Desktop and configure settings
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
Set-LocalUser -Name "runneradmin" -Password (ConvertTo-SecureString -AsPlainText "12345Ab@" -Force)
Set-ItemProperty -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LimitBlankPasswordUse' -Value 0 -force
