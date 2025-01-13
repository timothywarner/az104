# Administrator's Sample Scripts

This document provides practical scripts for common Azure administration tasks, organized by AZ-104 exam areas. Each section includes PowerShell, Azure CLI, and KQL examples where applicable.

## 1. Identity and Governance Scripts (20-25%)

### Management Group Operations
```powershell
# PowerShell: Get all management groups with details
function Get-AllManagementGroups {
    $groups = Get-AzManagementGroup
    foreach ($group in $groups) {
        Write-Host "Group: $($group.DisplayName)"
        Write-Host "ID: $($group.Id)"
        Write-Host "Children: $($group.Children.Count)"
        Write-Host "---"
    }
}
```

```bash
# Azure CLI: Management group operations
# List all management groups
az account management-group list --query "[].{Name:name, DisplayName:displayName, ID:id}" -o table

# Get management group hierarchy
az account management-group show --name "mg-root" --expand --recurse
```

### RBAC Management
```powershell
# PowerShell: Role assignment analysis
function Get-RoleAssignmentReport {
    param (
        [string]$ResourceGroupPattern,
        [switch]$IncludeInherited
    )
    
    $rgs = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like $ResourceGroupPattern }
    foreach ($rg in $rgs) {
        Write-Host "Checking $($rg.ResourceGroupName)..."
        Get-AzRoleAssignment -ResourceGroupName $rg.ResourceGroupName -IncludeClassicAdministrators:$IncludeInherited |
            Select-Object DisplayName, RoleDefinitionName, Scope, ObjectType |
            Format-Table -AutoSize
    }
}

# PowerShell: Custom role creation with permissions
function New-CustomAdminRole {
    param (
        [string]$RoleName,
        [string]$Scope
    )
    
    $role = Get-AzRoleDefinition "Virtual Machine Contributor"
    $role.Id = $null
    $role.Name = $RoleName
    $role.Description = "Custom role for VM and Network management"
    $role.Actions.Add("Microsoft.Network/virtualNetworks/*")
    $role.Actions.Add("Microsoft.Network/networkSecurityGroups/*")
    $role.NotActions.Add("Microsoft.Network/virtualNetworks/delete")
    $role.AssignableScopes.Clear()
    $role.AssignableScopes.Add($Scope)
    
    New-AzRoleDefinition -Role $role
}
```

```bash
# Azure CLI: RBAC operations
# List role assignments with detailed output
az role assignment list \
    --resource-group "rg-prod" \
    --include-inherited \
    --query "[].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" \
    -o table

# Create custom role from JSON
az role definition create --role-definition @custom-role.json
```

## 2. Storage Management Scripts (15-20%)

### Storage Account Operations
```powershell
# PowerShell: Comprehensive storage account check
function Test-StorageAccountSecurity {
    param (
        [string]$ResourceGroupName,
        [string]$StorageAccountName
    )
    
    try {
        # Get storage account
        $sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        
        # Check encryption
        Write-Host "Encryption Status:"
        Write-Host "Blob encryption: $($sa.Encryption.Services.Blob.Enabled)"
        Write-Host "File encryption: $($sa.Encryption.Services.File.Enabled)"
        
        # Check network rules
        Write-Host "`nNetwork Rules:"
        Write-Host "Default Action: $($sa.NetworkRuleSet.DefaultAction)"
        Write-Host "IP Rules: $($sa.NetworkRuleSet.IpRules.Count)"
        Write-Host "VNet Rules: $($sa.NetworkRuleSet.VirtualNetworkRules.Count)"
        
        # Check access keys
        $keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        Write-Host "`nAccess Keys: $($keys.Count) active keys"
        
        # Test container access
        $context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $keys[0].Value
        Get-AzStorageContainer -Context $context -MaxCount 1
        Write-Host "✅ Storage account access successful"
    }
    catch {
        Write-Error "❌ Storage account check failed: $_"
    }
}
```

```bash
# Azure CLI: Storage account management
# Create storage account with security features
az storage account create \
    --name $storageAccount \
    --resource-group $resourceGroup \
    --sku Standard_GRS \
    --encryption-services blob file \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --https-only true

# Configure network rules
az storage account network-rule add \
    --resource-group $resourceGroup \
    --account-name $storageAccount \
    --ip-address $clientIP
```

### Storage Monitoring KQL
```kusto
// Monitor storage account operations
StorageBlobLogs
| where TimeGenerated > ago(1d)
| where OperationName has "Delete"
| summarize count() by AccountName, OperationName, StatusText
| order by count_ desc

// Analyze storage access patterns
StorageFileLogs
| where TimeGenerated > ago(7d)
| summarize RequestCount=count() by bin(TimeGenerated, 1h), RequestType
| render timechart
```

## 3. Compute Resource Scripts (20-25%)

### VM Management
```powershell
# PowerShell: VM operations with error handling
function Update-VMConfiguration {
    param (
        [string]$ResourceGroupName,
        [string]$VMName,
        [string]$NewSize,
        [switch]$EnableBackup
    )
    
    try {
        # Get VM
        $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
        
        # Check size availability
        $location = $vm.Location
        $availableSizes = Get-AzVMSize -Location $location
        
        if ($availableSizes.Name -contains $NewSize) {
            # Stop VM if running
            $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
            if ($vmStatus.Statuses.DisplayStatus -contains "VM running") {
                Write-Host "Stopping VM..."
                $vm | Stop-AzVM -Force
            }
            
            # Update size
            $vm.HardwareProfile.VmSize = $NewSize
            Update-AzVM -VM $vm -ResourceGroupName $ResourceGroupName
            
            # Configure backup if requested
            if ($EnableBackup) {
                $vault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName
                Enable-AzRecoveryServicesBackupProtection `
                    -ResourceGroupName $ResourceGroupName `
                    -Name $VMName `
                    -Policy $vault.DefaultPolicy
            }
            
            # Start VM
            $vm | Start-AzVM
            Write-Host "VM configuration updated successfully"
        }
        else {
            Write-Error "Size $NewSize not available in $location"
        }
    }
    catch {
        Write-Error "VM update failed: $_"
    }
}
```

```bash
# Azure CLI: VM management
# Create VM with detailed configuration
az vm create \
    --resource-group $resourceGroup \
    --name $vmName \
    --image Win2019Datacenter \
    --size Standard_DS2_v2 \
    --admin-username azureuser \
    --admin-password $password \
    --nsg-rule RDP \
    --public-ip-sku Standard \
    --os-disk-size-gb 128 \
    --boot-diagnostics-storage $diagStorage

# Configure VM backup
az backup protection enable-for-vm \
    --resource-group $resourceGroup \
    --vault-name $vaultName \
    --vm $vmName \
    --policy-name $policyName
```

### VM Monitoring KQL
```kusto
// Monitor VM performance
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

// Track VM status changes
VMOperationalLogs
| where TimeGenerated > ago(24h)
| where OperationName has "restart" or OperationName has "deallocate"
| project TimeGenerated, Computer, OperationName, Status
| order by TimeGenerated desc
```

## 4. Network Management Scripts (15-20%)

### Network Troubleshooting
```powershell
# PowerShell: Network security analysis
function Test-NetworkSecurity {
    param (
        [string]$ResourceGroupName,
        [string]$VNetName
    )
    
    # Check VNet
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    Write-Host "VNet Configuration:"
    Write-Host "Address Space: $($vnet.AddressSpace.AddressPrefixes)"
    Write-Host "DNS Servers: $($vnet.DhcpOptions.DnsServers)"
    
    # Check each subnet
    foreach ($subnet in $vnet.Subnets) {
        Write-Host "`nSubnet: $($subnet.Name)"
        Write-Host "Address Range: $($subnet.AddressPrefix)"
        
        # Check NSG
        if ($subnet.NetworkSecurityGroup) {
            $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $subnet.NetworkSecurityGroup.Id.Split('/')[-1]
            Write-Host "NSG Rules:"
            $nsg.SecurityRules | 
                Sort-Object Priority |
                Format-Table Name, Priority, Direction, Access, SourceAddressPrefix, DestinationPortRange
            
            # Check for risky rules
            $riskyRules = $nsg.SecurityRules | Where-Object { 
                $_.SourceAddressPrefix -eq "*" -and 
                $_.Access -eq "Allow" -and 
                $_.Direction -eq "Inbound"
            }
            if ($riskyRules) {
                Write-Warning "Found potentially risky rules allowing all inbound traffic:"
                $riskyRules | Format-Table Name, Priority, DestinationPortRange
            }
        }
        
        # Check service endpoints
        if ($subnet.ServiceEndpoints) {
            Write-Host "Service Endpoints:"
            $subnet.ServiceEndpoints | Format-Table Service, ProvisioningState
        }
    }
    
    # Check peerings
    $peerings = Get-AzVirtualNetworkPeering -ResourceGroupName $ResourceGroupName -VirtualNetworkName $VNetName
    if ($peerings) {
        Write-Host "`nVNet Peerings:"
        $peerings | Format-Table Name, PeeringState, AllowForwardedTraffic, AllowGatewayTransit
    }
}
```

```bash
# Azure CLI: Network operations
# Create VNet with subnets
az network vnet create \
    --name $vnetName \
    --resource-group $resourceGroup \
    --address-prefix 10.0.0.0/16 \
    --subnet-name frontend \
    --subnet-prefix 10.0.1.0/24

# Add NSG rules
az network nsg rule create \
    --resource-group $resourceGroup \
    --nsg-name $nsgName \
    --name allow-https \
    --priority 100 \
    --direction Inbound \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-port-ranges 443 \
    --protocol Tcp \
    --access Allow

# Test connectivity
az network watcher test-ip-flow \
    --resource-group $resourceGroup \
    --vm $vmName \
    --direction Inbound \
    --protocol TCP \
    --local 10.0.1.4 \
    --remote 193.168.1.10 \
    --local-port 443
```

### Network Monitoring KQL
```kusto
// Monitor NSG flow logs
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| where FlowType_s == "MaliciousFlow"
| project TimeGenerated, NSGName_s, SourceIP_s, DestinationIP_s, DestinationPort_d
| order by TimeGenerated desc

// Analyze network connectivity issues
AzureDiagnostics
| where ResourceType == "NETWORKSECURITYGROUPS"
| where OperationName == "NetworkSecurityGroupCounters"
| summarize count() by bin(TimeGenerated, 5m), allowed_out=tostring(split(counter_s, "|")[0])
| render timechart
```

## 5. Monitoring and Backup Scripts (10-15%)

### Azure Monitor Operations
```powershell
# PowerShell: Set up comprehensive monitoring
function Set-AzureMonitoring {
    param (
        [string]$ResourceGroupName,
        [string]$WorkspaceName,
        [string[]]$VMNames
    )
    
    try {
        # Create Log Analytics workspace if not exists
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $location
        }
        
        # Enable VM insights
        foreach ($vmName in $VMNames) {
            $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName
            Set-AzVMExtension -ResourceGroupName $ResourceGroupName `
                -VMName $vmName `
                -Name "MicrosoftMonitoringAgent" `
                -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
                -ExtensionType "MicrosoftMonitoringAgent" `
                -TypeHandlerVersion "1.0" `
                -Settings @{"workspaceId" = $workspace.CustomerId} `
                -ProtectedSettings @{"workspaceKey" = $workspace.PrimarySharedKey}
        }
        
        # Create alert rules
        $actionGroup = New-AzActionGroup -ResourceGroupName $ResourceGroupName `
            -Name "EmailAlert" `
            -ShortName "email" `
            -Receiver @{
                Name = "emailReceiver"
                EmailAddress = "admin@contoso.com"
                UseCommonAlertSchema = $true
            }
        
        # CPU alert rule
        Add-AzMetricAlertRule -ResourceGroupName $ResourceGroupName `
            -Name "HighCPU" `
            -Location $location `
            -TargetResourceId $vm.Id `
            -MetricName "Percentage CPU" `
            -Operator GreaterThan `
            -Threshold 90 `
            -WindowSize (New-TimeSpan -Minutes 5) `
            -TimeAggregationOperator Average `
            -Actions $actionGroup
            
        Write-Host "Monitoring setup completed successfully"
    }
    catch {
        Write-Error "Monitoring setup failed: $_"
    }
}
```

```bash
# Azure CLI: Monitoring setup
# Create Log Analytics workspace
az monitor log-analytics workspace create \
    --resource-group $resourceGroup \
    --workspace-name $workspaceName \
    --location $location \
    --sku PerGB2018

# Create alert rule
az monitor metrics alert create \
    --name "high-cpu-alert" \
    --resource-group $resourceGroup \
    --scopes $vmId \
    --condition "max Percentage CPU > 90" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --action $actionGroupId
```

### Monitoring and Diagnostics KQL
```kusto
// CPU Performance Analysis
Perf
| where CounterName == "% Processor Time"
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| where AvgCPU > 90
| render timechart

// Memory Usage Tracking
Perf
| where CounterName == "% Used Memory"
| where TimeGenerated > ago(4h)
| summarize AvgMem = avg(CounterValue) by Computer, bin(TimeGenerated, 15m)
| render timechart

// Security Event Analysis
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 4625  // Failed logon attempts
| summarize FailedLogins=count() by TargetAccount, Computer
| where FailedLogins > 10
| order by FailedLogins desc

// Service Health Tracking
AzureActivity
| where TimeGenerated > ago(7d)
| where OperationName has "Microsoft.ServiceHealth"
| project TimeGenerated, SubscriptionId, EventLevel, OperationName, Description
| order by TimeGenerated desc
```

## Usage Examples

```powershell
# Identity and Governance
Get-AllManagementGroups
Get-RoleAssignmentReport -ResourceGroupPattern "rg-prod-*" -IncludeInherited

# Storage
Test-StorageAccountSecurity -ResourceGroupName "rg-storage-prod" -StorageAccountName "stprod001"

# Compute
Update-VMConfiguration -ResourceGroupName "rg-compute-prod" -VMName "vm-prod-001" -NewSize "Standard_D4s_v3" -EnableBackup

# Network
Test-NetworkSecurity -ResourceGroupName "rg-network-prod" -VNetName "vnet-prod-001"

# Monitoring
Set-AzureMonitoring -ResourceGroupName "rg-monitoring-prod" -WorkspaceName "law-prod-001" -VMNames @("vm-prod-001", "vm-prod-002")
```

## Next Steps
→ [Back to Deployment Guide](02-deployment-guide.md)
→ [Back to Implementation Guide](01-design-decisions.md) 