# Deploy AZ-104 Lab Environment
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Location = "southcentralus",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "az104-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "az104"
)

# Function to validate Azure context
function Test-AzureContext {
    $context = Get-AzContext
    if (-not $context) {
        Write-Error "Not logged into Azure. Please run Connect-AzAccount first."
        return $false
    }

    Write-Host "`nCurrent Azure Context:"
    Write-Host "----------------------------------------"
    Write-Host "Subscription: $($context.Subscription.Name)"
    Write-Host "Tenant: $($context.Tenant.Id)"
    Write-Host "Account: $($context.Account.Id)"
    Write-Host "----------------------------------------`n"

    $confirmation = Read-Host "Is this the correct context? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Error "Please select the correct subscription using Set-AzContext or Connect-AzAccount"
        return $false
    }
    return $true
}

# Ensure Az module is installed
if (-not (Get-Module -ListAvailable Az)) {
    Write-Host "Az PowerShell module not found. Installing..."
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
}

# Validate Azure context
if (-not (Test-AzureContext)) {
    exit 1
}

# Create or update resource group
Write-Host "Creating/updating resource group..."
try {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
}
catch {
    Write-Error "Failed to create/update resource group: $_"
    exit 1
}

# Deploy Bicep template
Write-Host "Deploying infrastructure..."
$deploymentName = "az104-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    New-AzDeployment `
        -Name $deploymentName `
        -Location $Location `
        -TemplateFile "main.bicep" `
        -TemplateParameterObject @{
            location = $Location
            environmentName = $EnvironmentName
            resourceGroupName = $ResourceGroupName
        } `
        -Verbose
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Host "`nDeployment complete!"

# Display connection information
Write-Host "`nConnection Information:"
Write-Host "----------------------------------------"
Write-Host "To connect to VMs:"
Write-Host "1. Use Azure Bastion from the Azure Portal"
Write-Host "2. Connect to Windows VM using RDP through Bastion"
Write-Host "3. Connect to Linux VM using SSH through Bastion"
Write-Host "`nNote: All resources are sending logs to Log Analytics workspace"
Write-Host "Check the Log Analytics workspace for monitoring data"
Write-Host "`nIMPORTANT SECURITY NOTES:"
Write-Host "----------------------------------------"
Write-Host "1. VM credentials are stored in Key Vault 'certstar-keyvault1'"
Write-Host "2. Ensure Key Vault access is properly restricted"
Write-Host "3. Review NSG rules and Firewall settings after deployment"
Write-Host "4. All VM access is through Azure Bastion only" 