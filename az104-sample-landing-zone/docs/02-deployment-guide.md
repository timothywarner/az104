# Administrator's Deployment Guide

## Prerequisites

### 1. Required Access
- Global Administrator or User Administrator role in Entra ID
- Subscription Owner role
- Management Group Administrator role

### 2. Required Tools
```powershell
# Verify tool installation and versions
az --version                    # Azure CLI
pwsh -Command "$PSVersionTable" # PowerShell 7+
az bicep version               # Bicep CLI

# Install/Update tools if needed
winget install Microsoft.AzureCLI
winget install Microsoft.PowerShell
az bicep install
Install-Module -Name Az -Force
```

### 3. Environment Preparation
```powershell
# Login and set context
Connect-AzAccount
az login

# Verify subscription access
Get-AzSubscription
az account list -o table

# Set working subscription
$subscriptionId = "your-subscription-id"
Set-AzContext -Subscription $subscriptionId
az account set --subscription $subscriptionId
```

## Deployment Sequence

### Phase 1: Identity and Governance Setup (20-25%)

1. **Create Management Group Hierarchy**
```powershell
# Create root management group
New-AzManagementGroup -GroupName "mg-root" -DisplayName "Root Management"

# Create child management groups
New-AzManagementGroup -GroupName "mg-platform" -DisplayName "Platform" -ParentId "/providers/Microsoft.Management/managementGroups/mg-root"
New-AzManagementGroup -GroupName "mg-workloads" -DisplayName "Workloads" -ParentId "/providers/Microsoft.Management/managementGroups/mg-root"
```

2. **Configure RBAC and Governance**
```powershell
# Assign built-in roles
New-AzRoleAssignment `
    -SignInName "user@domain.com" `
    -RoleDefinitionName "Contributor" `
    -ResourceGroupName "rg-workload-prod"

# Create and assign policy
$policy = Get-AzPolicyDefinition -Name "require-tag-on-rg"
New-AzPolicyAssignment `
    -Name "require-tags" `
    -PolicyDefinition $policy `
    -Scope "/subscriptions/$subscriptionId"
```

### Phase 2: Storage Implementation (15-20%)

1. **Create Storage Infrastructure**
```bash
# Create resource group
az group create \
    --name rg-storage-prod \
    --location eastus

# Create storage account
az storage account create \
    --name stproddata001 \
    --resource-group rg-storage-prod \
    --sku Standard_GRS \
    --encryption-services blob \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false
```

2. **Configure Storage Security**
```powershell
# Configure network rules
Add-AzStorageAccountNetworkRule `
    -ResourceGroupName "rg-storage-prod" `
    -Name "stproddata001" `
    -VirtualNetworkResourceId $vnetSubnetId

# Generate SAS token
$storageContext = New-AzStorageContext -StorageAccountName "stproddata001" -UseConnectedAccount
New-AzStorageAccountSASToken `
    -Context $storageContext `
    -Service Blob,File `
    -ResourceType Service,Container,Object `
    -Permission "racwdlup"
```

### Phase 3: Compute Resources (20-25%)

1. **Deploy Virtual Machines**
```bash
# Create VM with availability set
az vm create \
    --resource-group rg-compute-prod \
    --name vm-prod-001 \
    --image Win2019Datacenter \
    --size Standard_DS2_v2 \
    --admin-username azureuser \
    --admin-password "ComplexPassword123!" \
    --availability-set av-set-prod

# Configure VM backup
az backup protection enable-for-vm \
    --resource-group rg-compute-prod \
    --vault-name rv-prod-001 \
    --vm vm-prod-001 \
    --policy-name "DefaultPolicy"
```

2. **Configure App Service**
```powershell
# Create App Service Plan
New-AzAppServicePlan `
    -ResourceGroupName "rg-apps-prod" `
    -Name "asp-prod-001" `
    -Location "eastus" `
    -Tier "Standard" `
    -NumberofWorkers 2

# Create Web App with slots
New-AzWebApp `
    -ResourceGroupName "rg-apps-prod" `
    -Name "app-prod-001" `
    -Location "eastus" `
    -AppServicePlan "asp-prod-001"
```

### Phase 4: Network Configuration (15-20%)

1. **Create Virtual Network Infrastructure**
```bash
# Create VNet and subnets
az network vnet create \
    --name vnet-prod-001 \
    --resource-group rg-network-prod \
    --address-prefix 10.0.0.0/16 \
    --subnet-name subnet-workload \
    --subnet-prefix 10.0.1.0/24

# Configure NSG
az network nsg create \
    --name nsg-prod-001 \
    --resource-group rg-network-prod

az network nsg rule create \
    --name allow-https \
    --nsg-name nsg-prod-001 \
    --priority 100 \
    --resource-group rg-network-prod \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-port-ranges 443
```

2. **Implement Load Balancer**
```powershell
# Create load balancer
New-AzLoadBalancer `
    -ResourceGroupName "rg-network-prod" `
    -Name "lb-prod-001" `
    -Location "eastus" `
    -SKU "Standard" `
    -FrontendIpConfiguration $frontendIP `
    -BackendAddressPool $backendPool
```

### Phase 5: Monitoring Setup (10-15%)

1. **Configure Azure Monitor**
```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
    --resource-group rg-monitoring-prod \
    --workspace-name law-prod-001

# Create alert rule
az monitor metrics alert create \
    --name "cpu-alert" \
    --resource-group rg-monitoring-prod \
    --scopes "/subscriptions/$subscriptionId/resourceGroups/rg-compute-prod/providers/Microsoft.Compute/virtualMachines/vm-prod-001" \
    --condition "max percentage CPU > 80" \
    --window-size 5m \
    --evaluation-frequency 1m
```

2. **Set Up Backup**
```powershell
# Create Recovery Services vault
New-AzRecoveryServicesVault `
    -ResourceGroupName "rg-backup-prod" `
    -Name "rsv-prod-001" `
    -Location "eastus"

# Configure backup policy
$policy = New-AzRecoveryServicesBackupProtectionPolicy `
    -Name "daily-backup" `
    -WorkloadType "AzureVM" `
    -RetentionDaily 7
```

## Validation Steps

### 1. Verify Identity and Access
```powershell
# Check role assignments
Get-AzRoleAssignment -ResourceGroupName "rg-workload-prod"

# Verify policy compliance
Get-AzPolicyState -ResourceGroupName "rg-workload-prod"
```

### 2. Test Network Connectivity
```bash
# Test VNet peering
az network vnet peering list \
    --resource-group rg-network-prod \
    --vnet-name vnet-prod-001

# Verify NSG rules
az network nsg rule list \
    --nsg-name nsg-prod-001 \
    --resource-group rg-network-prod
```

### 3. Monitor Resources
```powershell
# Check VM metrics
Get-AzMetric -ResourceId $vmId -MetricName "Percentage CPU"

# Verify backup status
Get-AzRecoveryServicesBackupJob -Status "InProgress"
```

## Next Steps
→ [Sample Scripts](03-sample-scripts.md)
→ [Back to Implementation Guide](01-design-decisions.md) 