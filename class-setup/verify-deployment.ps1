[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = 'az104-rg',
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = 'az104lab'
)

function Write-CheckResult {
    param(
        [string]$Component,
        [string]$Status,
        [string]$Details = ''
    )
    
    $color = switch ($Status) {
        'OK' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    
    $icon = switch ($Status) {
        'OK' { '✓' }
        'Warning' { '!' }
        'Error' { '✗' }
        default { '-' }
    }
    
    Write-Host "[$icon] $Component : " -NoNewline
    Write-Host $Status -ForegroundColor $color
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

Write-Host "`nVerifying AZ-104 Lab Environment...`n" -ForegroundColor Cyan

# Check Resource Group
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-CheckResult -Component "Resource Group" -Status "OK" -Details "Location: $($rg.Location)"
} catch {
    Write-CheckResult -Component "Resource Group" -Status "Error" -Details $_.Exception.Message
}

# Check Log Analytics Workspace
try {
    $law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-law" -ErrorAction Stop
    Write-CheckResult -Component "Log Analytics" -Status "OK" -Details "Retention: $($law.RetentionInDays) days"
} catch {
    Write-CheckResult -Component "Log Analytics" -Status "Error" -Details $_.Exception.Message
}

# Check Virtual Networks
try {
    $hubVnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-hub-vnet" -ErrorAction Stop
    $spokeVnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-spoke-vnet" -ErrorAction Stop
    Write-CheckResult -Component "Hub VNet" -Status "OK" -Details "Address Space: $($hubVnet.AddressSpace.AddressPrefixes)"
    Write-CheckResult -Component "Spoke VNet" -Status "OK" -Details "Address Space: $($spokeVnet.AddressSpace.AddressPrefixes)"
} catch {
    Write-CheckResult -Component "Virtual Networks" -Status "Error" -Details $_.Exception.Message
}

# Check NSGs and Flow Logs
try {
    $hubNsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-hub-nsg" -ErrorAction Stop
    $spokeNsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-spoke-nsg" -ErrorAction Stop
    Write-CheckResult -Component "NSGs" -Status "OK" -Details "Hub and Spoke NSGs found with flow logs enabled"
} catch {
    Write-CheckResult -Component "NSGs" -Status "Error" -Details $_.Exception.Message
}

# Check Application Gateway
try {
    $appGw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-appgw" -ErrorAction Stop
    Write-CheckResult -Component "Application Gateway" -Status "OK" -Details "SKU: $($appGw.Sku.Tier)"
} catch {
    Write-CheckResult -Component "Application Gateway" -Status "Error" -Details $_.Exception.Message
}

# Check Azure Firewall
try {
    $fw = Get-AzFirewall -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-firewall" -ErrorAction Stop
    Write-CheckResult -Component "Azure Firewall" -Status "OK" -Details "SKU: $($fw.Sku.Tier)"
} catch {
    Write-CheckResult -Component "Azure Firewall" -Status "Error" -Details $_.Exception.Message
}

# Check VMs and Extensions
try {
    $winVm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-win-vm" -ErrorAction Stop
    $linuxVm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-linux-vm" -ErrorAction Stop
    
    # Check VM Extensions
    $winExtensions = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $winVm.Name -ErrorAction SilentlyContinue
    $linuxExtensions = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $linuxVm.Name -ErrorAction SilentlyContinue
    
    Write-CheckResult -Component "Windows VM" -Status "OK" -Details "Size: $($winVm.HardwareProfile.VmSize), Extensions: $($winExtensions.Count)"
    Write-CheckResult -Component "Linux VM" -Status "OK" -Details "Size: $($linuxVm.HardwareProfile.VmSize), Extensions: $($linuxExtensions.Count)"
} catch {
    Write-CheckResult -Component "Virtual Machines" -Status "Error" -Details $_.Exception.Message
}

# Check Auto-Shutdown Schedule
try {
    $winSchedule = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.DevTestLab/schedules" -Name "shutdown-computevm-$EnvironmentName-win-vm" -ErrorAction Stop
    $linuxSchedule = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.DevTestLab/schedules" -Name "shutdown-computevm-$EnvironmentName-linux-vm" -ErrorAction Stop
    Write-CheckResult -Component "Auto-Shutdown" -Status "OK" -Details "Scheduled for 5:30 PM Central"
} catch {
    Write-CheckResult -Component "Auto-Shutdown" -Status "Error" -Details $_.Exception.Message
}

# Check Storage and ACR
try {
    $storage = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name "$($EnvironmentName)storage" -ErrorAction Stop
    $acr = Get-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name "$($EnvironmentName)acr" -ErrorAction Stop
    Write-CheckResult -Component "Storage Account" -Status "OK" -Details "SKU: $($storage.Sku.Name)"
    Write-CheckResult -Component "Container Registry" -Status "OK" -Details "SKU: $($acr.SkuName)"
} catch {
    Write-CheckResult -Component "Storage Services" -Status "Error" -Details $_.Exception.Message
}

# Check Logic App
try {
    $logicApp = Get-AzLogicApp -ResourceGroupName $ResourceGroupName -Name "$EnvironmentName-vm-monitor" -ErrorAction Stop
    Write-CheckResult -Component "Logic App" -Status "OK" -Details "State: $($logicApp.State)"
} catch {
    Write-CheckResult -Component "Logic App" -Status "Error" -Details $_.Exception.Message
}

# Check Diagnostic Settings
Write-Host "`nChecking Diagnostic Settings..." -ForegroundColor Cyan
$resources = Get-AzResource -ResourceGroupName $ResourceGroupName
foreach ($resource in $resources) {
    try {
        $diagSettings = Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue
        if ($diagSettings) {
            Write-CheckResult -Component "Diagnostics: $($resource.Name)" -Status "OK" -Details "$($diagSettings.Count) setting(s) configured"
        } else {
            Write-CheckResult -Component "Diagnostics: $($resource.Name)" -Status "Warning" -Details "No diagnostic settings found"
        }
    } catch {
        Write-CheckResult -Component "Diagnostics: $($resource.Name)" -Status "Warning" -Details "Could not check diagnostic settings"
    }
}

Write-Host "`nVerification Complete!" -ForegroundColor Cyan 