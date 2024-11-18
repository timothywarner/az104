# Set the time zone
Set-TimeZone -Name "Central Standard Time"

# Disable Firewall
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

#Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Download SQL Server ISO
# Invoke-WebRequest -Uri https://timstorage001.blob.core.windows.net/chocolatey/sql.iso -OutFile 'c:\sql.iso'

# Install SQL Server
# choco install sql-server-2019 --params="'/IsoPath:c:\sql.iso'" -y

#Install Software
choco install git microsoft-edge powershell-core azurepowershell azure-cli bicep vscode sysinternals microsoftazurestorageexplorer nodejs-install sql-server-management-studio -y
# npm install --global --production windows-build-tools

# Disable IE Enhanced Security Config
function Disable-IEESC {
  $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
  $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
  Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
  Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
  Stop-Process -Name Explorer
}
Disable-IEESC

# Hide clock
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies' -Name 'Explorer'
New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies' -Name 'Explorer'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideClock' -Value 1
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideClock' -Value 1
Stop-Process -Name 'explorer'
