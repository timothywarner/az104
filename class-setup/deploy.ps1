# Deploy AZ-104 Lab Environment
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Location = "southcentralus",
    
    [Parameter()]
    [string]$ResourceGroupName = "az104-rg",
    
    [Parameter()]
    [string]$EnvironmentName = "az104lab",

    [Parameter()]
    [string]$KeyVaultName = "certstar-keyvault1",

    [Parameter()]
    [string]$KeyVaultResourceGroup = "permanent-rg"
)

# Function to write colored output
function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $color = switch ($Type) {
        'Info' { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline
    Write-Host $Message -ForegroundColor $color
}

# Function to test Azure context
function Test-AzureContext {
    Write-Status "Checking Azure Context..." -Type Info
    $context = Get-AzContext
    if (-not $context) {
        Write-Status "Not logged into Azure. Please run Connect-AzAccount first." -Type Error
        return $false
    }
    Write-Status "Current Context:" -Type Info
    Write-Status "  Subscription: $($context.Subscription.Name)" -Type Info
    Write-Status "  Tenant: $($context.Tenant.Id)" -Type Info
    return $true
}

# Function to test Key Vault access
function Test-KeyVaultAccess {
    param(
        [string]$VaultName,
        [string]$VaultResourceGroup
    )
    Write-Status "Checking access to Key Vault '$VaultName' in resource group '$VaultResourceGroup'..." -Type Info
    try {
        $vault = Get-AzKeyVault -VaultName $VaultName -ResourceGroupName $VaultResourceGroup
        if (-not $vault) {
            Write-Status "Key Vault '$VaultName' not found in resource group '$VaultResourceGroup'" -Type Error
            return $false
        }
        # Test if we can access secrets
        $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name "vmpassword2" -ErrorAction SilentlyContinue
        if (-not $secret) {
            Write-Status "Cannot access secret 'vmpassword2' in Key Vault '$VaultName'" -Type Error
            return $false
        }
        Write-Status "Successfully verified access to Key Vault and secret" -Type Success
        return $true
    }
    catch {
        Write-Status "Error accessing Key Vault: $_" -Type Error
        return $false
    }
}

# Ensure required PowerShell modules are installed
Write-Status "Checking required PowerShell modules..." -Type Info
$requiredModules = @(
    'Az.Accounts',
    'Az.Resources',
    'Az.Storage',
    'Az.Network',
    'Az.Compute',
    'Az.KeyVault'
)

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Status "Installing module $module..." -Type Warning
        Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
    }
    Write-Status "✓ $module ready" -Type Success
}

# Test Azure context
if (-not (Test-AzureContext)) {
    exit 1
}

# Test Key Vault access
if (-not (Test-KeyVaultAccess -VaultName $KeyVaultName -VaultResourceGroup $KeyVaultResourceGroup)) {
    exit 1
}

# Create or update resource group
Write-Status "Creating/Updating resource group '$ResourceGroupName' in '$Location'..." -Type Info
try {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force | Out-Null
    Write-Status "✓ Resource group ready" -Type Success
}
catch {
    Write-Status "Failed to create/update resource group: $_" -Type Error
    exit 1
}

# Deploy Bicep template
$deploymentName = "az104-lab-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$templateFile = Join-Path $PSScriptRoot "main.bicep"

Write-Status "Starting deployment '$deploymentName'..." -Type Info
Write-Status "This deployment will take approximately 30-45 minutes to complete." -Type Warning
Write-Status "The following resources will be deployed:" -Type Info
Write-Status "  • Log Analytics Workspace with insights" -Type Info
Write-Status "  • Hub VNet with Azure Firewall, VPN Gateway, and Bastion" -Type Info
Write-Status "  • Spoke VNet with peering" -Type Info
Write-Status "  • Application Gateway with WAF" -Type Info
Write-Status "  • Windows VM (IIS) and Linux VM" -Type Info
Write-Status "  • Storage Account and Container Registry" -Type Info
Write-Status "  • Logic App for VM monitoring" -Type Info

try {
    $deployment = New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $templateFile `
        -environmentName $EnvironmentName `
        -location $Location `
        -keyVaultName $KeyVaultName `
        -keyVaultResourceGroup $KeyVaultResourceGroup `
        -Verbose

    if ($deployment.ProvisioningState -eq 'Failed') {
        Write-Status "Deployment failed: $($deployment.Error)" -Type Error
        exit 1
    }
    
    Write-Status "✓ Deployment completed successfully!" -Type Success
    Write-Status "`nResources deployed:" -Type Success
    Write-Status "• Log Analytics Workspace: $($deployment.Outputs.logAnalyticsWorkspaceName.Value)" -Type Info
    Write-Status "• Storage Account: $($deployment.Outputs.storageAccountName.Value)" -Type Info
    Write-Status "• Container Registry: $($deployment.Outputs.acrName.Value)" -Type Info
}
catch {
    Write-Status "Deployment failed: $_" -Type Error
    exit 1
}

Write-Status "`nAccess Information:" -Type Warning
Write-Status "• Use Azure Bastion to connect to VMs" -Type Info
Write-Status "• Monitor resources in Log Analytics workspace: $($deployment.Outputs.logAnalyticsWorkspaceName.Value)" -Type Info 