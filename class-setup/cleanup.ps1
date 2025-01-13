# AZ-104 Environment Cleanup Script
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "az104-rg"
)

function Remove-ResourceLocks {
    param (
        [string]$ResourceGroupName
    )
    Write-Host "Checking for resource locks..."
    $locks = Get-AzResourceLock -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    
    if ($locks) {
        Write-Host "Found $($locks.Count) lock(s). Removing..."
        foreach ($lock in $locks) {
            Write-Host "Removing lock: $($lock.Name)"
            Remove-AzResourceLock -LockId $lock.LockId -Force
        }
    }
    else {
        Write-Host "No resource locks found."
    }
}

function Test-AzureContext {
    $context = Get-AzContext
    if (-not $context) {
        Write-Error "Not logged into Azure. Please run Connect-AzAccount first."
        return $false
    }

    Write-Host "`nCurrent Azure Context:"
    Write-Host "----------------------------------------"
    Write-Host "Subscription: $($context.Subscription.Name)"
    Write-Host "Account: $($context.Account.Id)"
    Write-Host "----------------------------------------`n"

    $confirmation = Read-Host "Is this the correct context? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Error "Please select the correct subscription using Set-AzContext or Connect-AzAccount"
        return $false
    }
    return $true
}

# Ensure Az modules are loaded
Import-Module Az.Accounts
Import-Module Az.Resources

# Validate Azure context
if (-not (Test-AzureContext)) {
    exit 1
}

# Confirm deletion
Write-Host "`nWARNING: This will delete all resources in resource group '$ResourceGroupName'" -ForegroundColor Red
Write-Host "This action cannot be undone!" -ForegroundColor Red
$confirmation = Read-Host "`nAre you sure you want to proceed? (yes/no)"
if ($confirmation -ne 'yes') {
    Write-Host "Cleanup cancelled."
    exit 0
}

try {
    # Check if resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Resource group '$ResourceGroupName' not found. Nothing to clean up."
        exit 0
    }

    # Remove any resource locks
    Remove-ResourceLocks -ResourceGroupName $ResourceGroupName

    # Get all resources for logging
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    Write-Host "`nResources to be deleted:"
    $resources | ForEach-Object { Write-Host "- $($_.Name) ($($_.ResourceType))" }

    # Delete the resource group and all resources
    Write-Host "`nDeleting resource group and all resources..."
    Remove-AzResourceGroup -Name $ResourceGroupName -Force

    Write-Host "`nCleanup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Error during cleanup: $_"
    Write-Error $_.Exception.Message
    exit 1
} 