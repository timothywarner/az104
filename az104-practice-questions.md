# AZ-104 Practice Questions by Exam Objective

## Identity and Governance (20-25%)

### Question 1
Your organization needs to implement a governance solution that applies policies across multiple subscriptions. Which Azure feature should you use?

A. Resource Groups
B. Management Groups
C. Azure Policy Initiatives
D. Subscription Tags

**Correct Answer: B**

**Explanation:** Management Groups provide a governance scope above subscriptions, allowing you to organize subscriptions and apply policies, RBAC, and compliance requirements hierarchically.

**Learn More:** [Azure Management Groups documentation](https://learn.microsoft.com/en-us/azure/governance/management-groups/)

### Question 2
Which PowerShell command creates a custom RBAC role from a JSON definition file?

A. ```New-AzRoleDefinition -InputFile "role.json"```
B. ```Set-AzRoleDefinition -Path "role.json"```
C. ```Add-AzRoleDefinition -File "role.json"```
D. ```Import-AzRoleDefinition -JsonPath "role.json"```

**Correct Answer: A**

**Explanation:** `New-AzRoleDefinition` creates a new custom RBAC role from a JSON definition file containing the role properties.

**Learn More:** [Create custom roles using PowerShell](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles-powershell)

### Question 3
Review this Azure CLI command:
```bash
az policy assignment create \
    --name 'require-tag-department' \
    --scope /subscriptions/0000000-0000-0000-0000-000000000000 \
    --policy 'required-tag-value'
```

What is the purpose of this command?

A. Creates a tag named 'department'
B. Assigns a policy requiring a specific tag
C. Lists all resources with the 'department' tag
D. Removes the 'department' tag requirement

**Correct Answer: B**

**Explanation:** This command assigns a policy that enforces tag requirements at the subscription scope.

**Learn More:** [Create policy assignments using Azure CLI](https://learn.microsoft.com/en-us/azure/governance/policy/assign-policy-azurecli)

### Question 4
Which Bicep code correctly defines a management group?

A. ```bicep
resource mg 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'mg-finance'
  properties: {
    displayName: 'Finance Management Group'
  }
}
```
B. ```bicep
resource mg 'Microsoft.Resources/managementGroups@2021-04-01' = {
  name: 'mg-finance'
}
```
C. ```bicep
resource mg 'Microsoft.Management/groups@2021-04-01' = {
  name: 'mg-finance'
  type: 'managementGroup'
}
```
D. ```bicep
resource mg 'Microsoft.Management@2021-04-01' = {
  type: 'managementGroups'
  name: 'mg-finance'
}
```

**Correct Answer: A**

**Explanation:** The correct resource type for management groups in Bicep is 'Microsoft.Management/managementGroups@version'.

**Learn More:** [Bicep management group template](https://learn.microsoft.com/en-us/azure/governance/management-groups/create-management-group-bicep)

### Question 5
You need to query all resources with a specific tag using Azure Resource Graph. Which KQL query should you use?

A. ```kusto
resources | where tags.environment == 'Production'
```
B. ```kusto
Resources | where tags['environment'] == 'Production'
```
C. ```kusto
Resources | where tag == 'Production'
```
D. ```kusto
resourcecontainers | where tags.environment == 'Production'
```

**Correct Answer: B**

**Explanation:** The correct syntax uses Resources table and bracket notation for accessing tag values.

**Learn More:** [Query Azure resources using Resource Graph](https://learn.microsoft.com/en-us/azure/governance/resource-graph/concepts/query-language)

## Storage (15-20%)

### Question 1
Which PowerShell command creates a storage account with geo-redundant storage?

A. ```powershell
New-AzStorageAccount -ResourceGroupName "rg1" -Name "storage1" -Location "eastus" -SkuName "Standard_GRS"
```
B. ```powershell
New-AzStorageAccount -ResourceGroupName "rg1" -Name "storage1" -Location "eastus" -Type "GRS"
```
C. ```powershell
Add-AzStorageAccount -ResourceGroupName "rg1" -Name "storage1" -Location "eastus" -Redundancy "Geo"
```
D. ```powershell
Set-AzStorageAccount -ResourceGroupName "rg1" -Name "storage1" -Location "eastus" -GeoRedundant
```

**Correct Answer: A**

**Explanation:** The `New-AzStorageAccount` cmdlet with `-SkuName "Standard_GRS"` creates a storage account with geo-redundant storage.

**Learn More:** [Create storage account with PowerShell](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create)

### Question 2
Review this Bicep code for a storage account:
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'mystorageaccount'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}
```

What security feature is NOT enabled in this template?

A. Secure transfer (HTTPS)
B. Infrastructure encryption
C. Blob encryption
D. TLS 1.2

**Correct Answer: B**

**Explanation:** The template enables HTTPS, blob encryption, and TLS 1.2, but doesn't enable infrastructure encryption (requireInfrastructureEncryption property).

**Learn More:** [Storage security in Bicep](https://learn.microsoft.com/en-us/azure/storage/common/storage-service-encryption)

### Question 3
Which KQL query shows blob operations with response status 403 (Forbidden) in the last hour?

A. ```kusto
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where StatusText == "403"
```
B. ```kusto
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where ResponseStatus == 403
```
C. ```kusto
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where StatusCode == 403
```
D. ```kusto
AzureMetrics
| where TimeGenerated > ago(1h)
| where ResponseCode == "403"
```

**Correct Answer: C**

**Explanation:** The correct query uses StorageBlobLogs table and StatusCode field to find forbidden operations.

**Learn More:** [Query storage logs in Log Analytics](https://learn.microsoft.com/en-us/azure/storage/common/storage-analytics-logging)

### Question 4
Which Azure CLI command creates an immutable blob storage policy?

A. ```bash
az storage container policy create --account-name mystorageaccount --container-name mycontainer --policy-name lockPolicy
```
B. ```bash
az storage container immutability-policy create --account-name mystorageaccount --container-name mycontainer --period 365
```
C. ```bash
az storage policy set --account-name mystorageaccount --container-name mycontainer --immutable true
```
D. ```bash
az storage container lock --account-name mystorageaccount --container-name mycontainer --duration 365
```

**Correct Answer: B**

**Explanation:** The `az storage container immutability-policy create` command creates an immutable storage policy for a container.

**Learn More:** [Configure immutable blob storage](https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview)

### Question 5
Review this ARM template snippet:
```json
{
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2021-06-01",
    "name": "[parameters('storageAccountName')]",
    "location": "[parameters('location')]",
    "sku": {
        "name": "Standard_LRS"
    },
    "kind": "StorageV2",
    "properties": {
        "networkAcls": {
            "defaultAction": "Deny",
            "virtualNetworkRules": [
                {
                    "id": "[parameters('subnetId')]",
                    "action": "Allow"
                }
            ]
        }
    }
}
```

What type of access control is being configured?

A. RBAC permissions
B. Service endpoints
C. Private endpoints
D. Shared access signatures

**Correct Answer: B**

**Explanation:** The template configures service endpoint access by allowing specific subnet access through virtualNetworkRules.

**Learn More:** [Configure service endpoints in ARM](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security)

## Compute Resources (20-25%)

### Question 1
You need to ensure a VM automatically recovers from hardware failures. Which feature should you use?

A. Availability Set
B. Availability Zone
C. Azure Site Recovery
D. Azure Backup

**Correct Answer: B**

**Explanation:** Availability Zones protect from datacenter-level failures by placing VMs in separate physical locations within a region.

**Learn More:** [Azure Availability Zones overview](https://learn.microsoft.com/en-us/azure/availability-zones/az-overview)

### Question 2
Which VM size series is optimized for memory-intensive database workloads?

A. Dsv4-series
B. Fsv2-series
C. Esv5-series
D. Mv2-series

**Correct Answer: D**

**Explanation:** Mv2-series VMs are designed for memory-intensive workloads with high memory-to-CPU ratios.

**Learn More:** [Memory optimized virtual machine sizes](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-memory)

### Question 3
You need to run a containerized application with minimal management overhead. Which service should you use?

A. Azure Kubernetes Service (AKS)
B. Azure Container Instances (ACI)
C. Azure App Service
D. Azure Functions

**Correct Answer: B**

**Explanation:** ACI provides serverless containers without cluster management overhead, ideal for simple containerized applications.

**Learn More:** [Azure Container Instances overview](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-overview)

### Question 4
Which feature should you use to collect and analyze VM performance data?

A. Azure Monitor
B. Network Watcher
C. Service Health
D. Activity Log

**Correct Answer: A**

**Explanation:** Azure Monitor collects, analyzes, and acts on telemetry data from Azure resources.

**Learn More:** [Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)

### Question 5
You need to back up Azure File Shares. Which service should you use?

A. Azure Site Recovery
B. Azure Backup
C. Storage Account Replication
D. Azure Copy

**Correct Answer: B**

**Explanation:** Azure Backup provides native backup capabilities for Azure File Shares with point-in-time recovery.

**Learn More:** [Back up Azure file shares](https://learn.microsoft.com/en-us/azure/backup/azure-file-share-backup-overview)

## Virtual Networking (15-20%)

### Question 1
Which service enables private connectivity between Azure VNets and on-premises networks?

A. Azure Firewall
B. ExpressRoute
C. Application Gateway
D. Load Balancer

**Correct Answer: B**

**Explanation:** ExpressRoute provides private, dedicated connectivity between on-premises networks and Azure.

**Learn More:** [ExpressRoute overview](https://learn.microsoft.com/en-us/azure/expressroute/expressroute-introduction)

### Question 2
You need to filter inbound traffic to a subnet. Which feature should you use?

A. Route Table
B. Network Security Group
C. Application Security Group
D. Service Endpoint

**Correct Answer: B**

**Explanation:** Network Security Groups filter network traffic to and from Azure resources in a virtual network.

**Learn More:** [Network security groups overview](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)

### Question 3
Which feature enables service-to-service communication without exposing services to the internet?

A. Private Link
B. Service Endpoint
C. VNet Peering
D. Public IP

**Correct Answer: A**

**Explanation:** Private Link provides secure access to Azure PaaS services over a private endpoint in your VNet.

**Learn More:** [Azure Private Link overview](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview)

### Question 4
Which service should you use to collect and analyze VM performance data?

A. Azure Monitor
B. Network Watcher
C. Service Health
D. Activity Log

**Correct Answer: A**

**Explanation:** Azure Monitor collects, analyzes, and acts on telemetry data from Azure resources.

**Learn More:** [Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview)

### Question 5
You need to back up Azure File Shares. Which service should you use?

A. Azure Site Recovery
B. Azure Backup
C. Storage Account Replication
D. Azure Copy

**Correct Answer: B**

**Explanation:** Azure Backup provides native backup capabilities for Azure File Shares with point-in-time recovery.

**Learn More:** [Back up Azure file shares](https://learn.microsoft.com/en-us/azure/backup/azure-file-share-backup-overview)

## Monitoring and Backup (10-15%)

### Question 1
Review this KQL query for Log Analytics:
```kusto
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| where AvgCPU > 90
```

What will this query return?

A. All VMs with any CPU spike in the last hour
B. VMs with average CPU above 90% over 5-minute intervals
C. Total CPU time for each VM in the last hour
D. Number of times CPU exceeded 90%

**Correct Answer: B**

**Explanation:** The query calculates 5-minute averages of CPU usage and filters for instances where the average exceeds 90%.

**Learn More:** [Log Analytics query syntax](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/query-language)

### Question 2
Review this Azure CLI command for creating an alert rule:
```bash
az monitor metrics alert create \
    --name "high-cpu-alert" \
    --resource-group "rg-prod" \
    --scopes $vmId \
    --condition "max Percentage CPU > 90" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --action $actionGroupId
```

What is the alert evaluation behavior?

A. Triggers when CPU exceeds 90% for 5 consecutive minutes
B. Checks CPU every minute and alerts if max value in last 5 minutes exceeds 90%
C. Alerts when average CPU is above 90% for any 1-minute period
D. Evaluates CPU every 5 minutes and alerts on any value above 90%

**Correct Answer: B**

**Explanation:** The alert evaluates every minute (evaluation-frequency) looking at the maximum CPU value over a 5-minute window (window-size).

**Learn More:** [Create metric alerts with Azure CLI](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-metric)

### Question 3
Which PowerShell command configures diagnostic settings to send platform logs to Log Analytics?

A. ```powershell
Set-AzDiagnosticSetting -ResourceId $vmId -WorkspaceId $workspaceId -Enabled $true
```
B. ```powershell
New-AzDiagnosticSetting -ResourceId $vmId -WorkspaceId $workspaceId -EnableLog $true
```
C. ```powershell
Set-AzVMDiagnosticsExtension -ResourceId $vmId -WorkspaceId $workspaceId
```
D. ```powershell
New-AzDiagnosticSetting -ResourceId $vmId -WorkspaceId $workspaceId -Category "AllLogs" -Enabled $true
```

**Correct Answer: A**

**Explanation:** `Set-AzDiagnosticSetting` is the correct cmdlet for configuring Azure resource diagnostic settings.

**Learn More:** [Configure diagnostic settings](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings)

### Question 4
Review this Bicep template for a Recovery Services vault:
```bicep
resource recoveryVault 'Microsoft.RecoveryServices/vaults@2021-06-01' = {
  name: 'rv-prod-001'
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    encryption: {
      keyVaultProperties: {
        keyUri: keyVaultKey.properties.keyUri
      }
    }
  }
}
```

What security feature is being implemented?

A. Network isolation only
B. Customer-managed keys only
C. Both network isolation and customer-managed keys
D. Soft delete protection

**Correct Answer: C**

**Explanation:** The template configures both private network access and encryption using customer-managed keys stored in Key Vault.

**Learn More:** [Recovery Services vault encryption](https://learn.microsoft.com/en-us/azure/backup/encryption-at-rest-with-cmk)

### Question 5
Which ARM template snippet enables diagnostic settings for capturing all metrics and logs?

A. ```json
{
    "logs": [
        {
            "category": "AllLogs",
            "enabled": true
        }
    ],
    "metrics": [
        {
            "category": "AllMetrics",
            "enabled": true
        }
    ]
}
```
B. ```json
{
    "categories": {
        "logs": "enabled",
        "metrics": "enabled"
    }
}
```
C. ```json
{
    "properties": {
        "logs": "All",
        "metrics": "All"
    }
}
```
D. ```json
{
    "diagnostics": {
        "enabled": true,
        "categories": "All"
    }
}
```

**Correct Answer: A**

**Explanation:** The correct format uses separate arrays for logs and metrics, with specific category names "AllLogs" and "AllMetrics".

**Learn More:** [Create diagnostic settings using ARM templates](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings-template)

## Next Steps
→ [Back to Study Guide](README.md)
→ [Practice in Azure Portal](https://portal.azure.com) 