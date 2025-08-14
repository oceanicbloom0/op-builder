# Download and import registry file for BetterRDP
$regFileUrl = "https://raw.githubusercontent.com/Upinel/BetterRDP/main/UpinelBetterRDP.reg"
$regFilePath = "$env:TEMP\UpinelBetterRDP.reg"
Invoke-WebRequest -Uri $regFileUrl -OutFile $regFilePath


# Download CentBrowser
$chromeInstallerUrl = "https://static.centbrowser.com/win_stable/5.2.1168.74/centbrowser_5.2.1168.74_x64_portable.exe"
$installerPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "centbrowser_installer.exe")
Invoke-WebRequest -Uri $chromeInstallerUrl -OutFile $installerPath
# Install CentBrowser silently
Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait



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

# Enable Remote Desktop and configure settings
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
Set-LocalUser -Name "runneradmin" -Password (ConvertTo-SecureString -AsPlainText "12345Ab@" -Force)
Set-ItemProperty -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LimitBlankPasswordUse' -Value 0 -force
