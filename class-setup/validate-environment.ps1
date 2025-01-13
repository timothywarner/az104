# Validate AZ-104 Lab Environment Prerequisites
[CmdletBinding()]
param()

$requiredModules = @(
    'Az.Accounts',
    'Az.Resources',
    'Az.KeyVault',
    'Az.Storage',
    'Az.ContainerRegistry'
)

$requiredFiles = @(
    'main.bicep',
    'modules/compute/compute.bicep',
    'modules/networking/networking.bicep',
    'modules/storage/storage.bicep',
    'modules/monitoring/monitoring.bicep',
    'modules/logic/logic.bicep',
    'scripts/populate-acr.ps1'
)

function Test-DockerInstallation {
    try {
        $dockerVersion = docker --version
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "`nValidating AZ-104 Lab Environment Setup...`n" -ForegroundColor Cyan

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $($psVersion.ToString())"
if ($psVersion.Major -lt 7) {
    Write-Warning "PowerShell 7 or higher is recommended. Current version: $($psVersion.ToString())"
}

# Check Az modules
Write-Host "`nChecking required PowerShell modules..."
$modulesToInstall = @()
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        $modulesToInstall += $module
        Write-Warning "Module '$module' is not installed"
    }
    else {
        Write-Host "✓ Module '$module' is installed" -ForegroundColor Green
    }
}

if ($modulesToInstall.Count -gt 0) {
    Write-Host "`nMissing modules will be installed when you run deploy.ps1"
}

# Check file structure
Write-Host "`nChecking required files..."
$missingFiles = @()
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $PSScriptRoot $file
    if (-not (Test-Path $filePath)) {
        $missingFiles += $file
        Write-Warning "Missing file: $file"
    }
    else {
        Write-Host "✓ File exists: $file" -ForegroundColor Green
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Some required files are missing. Please check the repository structure."
    exit 1
}

# Check Docker (optional)
Write-Host "`nChecking Docker installation..."
if (Test-DockerInstallation) {
    Write-Host "✓ Docker is installed" -ForegroundColor Green
    Write-Host "  ACR population will be available"
}
else {
    Write-Warning "Docker is not installed. ACR population will be skipped."
}

# Summary
Write-Host "`nValidation Summary:" -ForegroundColor Cyan
Write-Host "----------------------------------------"
if ($modulesToInstall.Count -eq 0 -and $missingFiles.Count -eq 0) {
    Write-Host "✓ Environment is ready for deployment" -ForegroundColor Green
    Write-Host "`nYou can run the deployment with:"
    Write-Host ".\deploy.ps1 -KeyVaultName 'YOUR-KV-NAME' [-PopulateACR]" -ForegroundColor Yellow
}
else {
    Write-Warning "Please address the warnings above before deploying"
}

# Display current Azure context if logged in
$context = Get-AzContext -ErrorAction SilentlyContinue
if ($context) {
    Write-Host "`nCurrent Azure Context:"
    Write-Host "----------------------------------------"
    Write-Host "Subscription: $($context.Subscription.Name)"
    Write-Host "Account: $($context.Account.Id)"
}
else {
    Write-Host "`nNot logged into Azure. Run 'Connect-AzAccount' first." -ForegroundColor Yellow
} 