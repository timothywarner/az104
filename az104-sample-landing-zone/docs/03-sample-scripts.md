# Administrator's Sample Scripts

This document provides practical scripts for common Azure administration tasks, organized by AZ-104 exam areas.

## 1. Identity and Governance Scripts (20-25%)

### Management Group Operations
```powershell
# Get all management groups
function Get-AllManagementGroups {
    $groups = Get-AzManagementGroup
    foreach ($group in $groups) {
        Write-Host "Group: $($group.DisplayName)"
        Write-Host "ID: $($group.Id)"
        Write-Host "Children: $($group.Children.Count)"
        Write-Host "---"
    }
}

# Move subscription between management groups
function Move-SubscriptionToManagementGroup {
    param (
        [string]$SubscriptionId,
        [string]$TargetGroupId
    )
    
    New-AzManagementGroupSubscription `
        -GroupId $TargetGroupId `
        -SubscriptionId $SubscriptionId
}
```

### RBAC Management
```powershell
# Bulk role assignment check
function Get-RoleAssignmentReport {
    param (
        [string]$ResourceGroupPattern
    )
    
    $rgs = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like $ResourceGroupPattern }
    foreach ($rg in $rgs) {
        Write-Host "Checking $($rg.ResourceGroupName)..."
        Get-AzRoleAssignment -ResourceGroupName $rg.ResourceGroupName |
            Select-Object DisplayName, RoleDefinitionName, Scope
    }
}

# Custom role creation
function New-CustomContributorRole {
    param (
        [string]$RoleName,
        [string]$Scope
    )
    
    $role = Get-AzRoleDefinition "Contributor"
    $role.Id = $null
    $role.Name = $RoleName
    $role.Description = "Custom role based on Contributor"
    $role.AssignableScopes.Clear()
    $role.AssignableScopes.Add($Scope)
    
    New-AzRoleDefinition -Role $role
}
```

## 2. Storage Management Scripts (15-20%)

### Storage Account Operations
```powershell
# Check storage account access
function Test-StorageAccountAccess {
    param (
        [string]$ResourceGroupName,
        [string]$StorageAccountName
    )
    
    try {
        $keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        $context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $keys[0].Value
        
        # Test container access
        Get-AzStorageContainer -Context $context -MaxCount 1
        Write-Host "✅ Storage account access successful"
    }
    catch {
        Write-Error "❌ Storage account access failed: $_"
    }
}

# Rotate storage account keys
function Update-StorageAccountKeys {
    param (
        [string]$ResourceGroupName,
        [string]$StorageAccountName
    )
    
    # Get current key1
    $keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $oldKey1 = $keys[0].Value
    
    # Regenerate key2 first
    New-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -KeyName key2
    Write-Host "Key2 regenerated"
    
    # Wait for propagation
    Start-Sleep -Seconds 30
    
    # Regenerate key1
    New-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -KeyName key1
    Write-Host "Key1 regenerated"
}
```

## 3. Compute Resource Scripts (20-25%)

### VM Management
```powershell
# VM size change with validation
function Update-VMSize {
    param (
        [string]$ResourceGroupName,
        [string]$VMName,
        [string]$NewSize
    )
    
    # Get VM
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    
    # Check if size is available
    $location = $vm.Location
    $availableSizes = Get-AzVMSize -Location $location
    
    if ($availableSizes.Name -contains $NewSize) {
        # Stop VM if running
        $vm | Stop-AzVM -Force
        
        # Update size
        $vm.HardwareProfile.VmSize = $NewSize
        Update-AzVM -VM $vm -ResourceGroupName $ResourceGroupName
        
        # Start VM
        $vm | Start-AzVM
        Write-Host "VM size updated successfully"
    }
    else {
        Write-Error "Size $NewSize not available in $location"
    }
}

# VM backup status check
function Get-VMBackupStatus {
    param (
        [string]$ResourceGroupName,
        [string]$VMName
    )
    
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    $backupStatus = Get-AzRecoveryServicesBackupStatus -Name $vm.Name -ResourceGroupName $ResourceGroupName -Type 'AzureVM'
    
    if ($backupStatus.BackedUp -eq $true) {
        $container = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName $vm.Name
        $backupItem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType "AzureVM"
        Write-Host "Last Backup Status: $($backupItem.LastBackupStatus)"
        Write-Host "Last Backup Time: $($backupItem.LastBackupTime)"
    }
    else {
        Write-Warning "VM is not configured for backup"
    }
}
```

## 4. Network Management Scripts (15-20%)

### Network Troubleshooting
```powershell
# Comprehensive network check
function Test-NetworkConfiguration {
    param (
        [string]$ResourceGroupName,
        [string]$VNetName
    )
    
    # Check VNet
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    Write-Host "VNet Address Space: $($vnet.AddressSpace.AddressPrefixes)"
    
    # Check Subnets
    foreach ($subnet in $vnet.Subnets) {
        Write-Host "`nSubnet: $($subnet.Name)"
        Write-Host "Address Prefix: $($subnet.AddressPrefix)"
        
        # Check NSG
        if ($subnet.NetworkSecurityGroup) {
            $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $subnet.NetworkSecurityGroup.Id.Split('/')[-1]
            Write-Host "NSG Rules:"
            $nsg.SecurityRules | Format-Table Name, Priority, Direction, Access, SourceAddressPrefix, DestinationPortRange
        }
        
        # Check Route Table
        if ($subnet.RouteTable) {
            $rt = Get-AzRouteTable -ResourceGroupName $ResourceGroupName -Name $subnet.RouteTable.Id.Split('/')[-1]
            Write-Host "Routes:"
            $rt.Routes | Format-Table Name, AddressPrefix, NextHopType
        }
    }
}

# NSG rule analysis
function Get-NSGRuleImpact {
    param (
        [string]$ResourceGroupName,
        [string]$NSGName,
        [string]$SourceIP,
        [string]$DestinationPort
    )
    
    $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName
    $matchingRules = $nsg.SecurityRules | Where-Object {
        ($_.Direction -eq "Inbound") -and
        (($_.SourceAddressPrefix -eq "*") -or ($_.SourceAddressPrefix -eq $SourceIP)) -and
        (($_.DestinationPortRange -eq "*") -or ($_.DestinationPortRange -eq $DestinationPort))
    } | Sort-Object Priority
    
    foreach ($rule in $matchingRules) {
        Write-Host "Rule: $($rule.Name)"
        Write-Host "Priority: $($rule.Priority)"
        Write-Host "Access: $($rule.Access)"
        Write-Host "---"
    }
}
```

## 5. Monitoring Scripts (10-15%)

### Azure Monitor and Diagnostics
```powershell
# Resource health check
function Get-ResourceHealthSummary {
    param (
        [string]$ResourceGroupName
    )
    
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    foreach ($resource in $resources) {
        $health = Get-AzHealthResource -ResourceId $resource.Id
        Write-Host "`nResource: $($resource.Name)"
        Write-Host "Type: $($resource.ResourceType)"
        Write-Host "Health: $($health.Properties.availabilityState)"
    }
}

# Log Analytics query helper
function Search-LogAnalytics {
    param (
        [string]$WorkspaceName,
        [string]$ResourceGroupName,
        [string]$Query,
        [int]$Days = 7
    )
    
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
    $queryResults = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspace.CustomerId -Query $Query -Timespan (New-TimeSpan -Days $Days)
    
    return $queryResults.Results
}
```

## Usage Examples

```powershell
# Identity and Governance
Get-AllManagementGroups
Get-RoleAssignmentReport -ResourceGroupPattern "rg-prod-*"

# Storage
Test-StorageAccountAccess -ResourceGroupName "rg-storage-prod" -StorageAccountName "stprod001"
Update-StorageAccountKeys -ResourceGroupName "rg-storage-prod" -StorageAccountName "stprod001"

# Compute
Update-VMSize -ResourceGroupName "rg-compute-prod" -VMName "vm-prod-001" -NewSize "Standard_D4s_v3"
Get-VMBackupStatus -ResourceGroupName "rg-compute-prod" -VMName "vm-prod-001"

# Network
Test-NetworkConfiguration -ResourceGroupName "rg-network-prod" -VNetName "vnet-prod-001"
Get-NSGRuleImpact -ResourceGroupName "rg-network-prod" -NSGName "nsg-prod-001" -SourceIP "10.0.0.0/24" -DestinationPort "443"

# Monitoring
Get-ResourceHealthSummary -ResourceGroupName "rg-prod-001"
Search-LogAnalytics -WorkspaceName "law-prod-001" -ResourceGroupName "rg-monitoring-prod" -Query "Heartbeat | summarize count() by Computer | where count_ == 0"
```

## Next Steps
→ [Back to Deployment Guide](02-deployment-guide.md)
→ [Back to Implementation Guide](01-design-decisions.md) 