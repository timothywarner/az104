# AZ-104 Lab Environment Setup

This directory contains Infrastructure as Code (IaC) templates to deploy a comprehensive Azure lab environment for AZ-104 certification training.

## Architecture

The environment consists of:

- Hub-Spoke Network Topology
  - Hub VNet with Azure Firewall, VPN Gateway, and Bastion
  - Spoke VNet with workload subnet and AKS subnet
  - Full VNet peering configuration
  
- Compute Resources
  - Windows Server 2022 VM in Hub
  - Ubuntu 20.04 VM in Spoke
  - All VMs use cost-optimized B-series SKUs
  
- Monitoring & Security
  - Log Analytics Workspace with full solutions
  - NSG Flow Logs with Traffic Analytics
  - Azure Bastion for secure VM access
  - Network Security Groups on all subnets
  
- Sample Logic App
  - Demonstrates service health monitoring
  - Managed Identity configuration
  - Log Analytics integration

## Prerequisites

1. Azure Subscription (Azure Pass or Pay-As-You-Go)
2. PowerShell 7.0 or later
3. Az PowerShell module
4. Azure Key Vault (setup instructions below)

## Initial Setup

1. Create an Azure Key Vault (if not exists):
   ```powershell
   # These steps should be done by the instructor
   $rg = "az104-rg"
   $location = "southcentralus"
   $kvName = "YOUR-KV-NAME"  # Replace with your Key Vault name
   
   # Create Key Vault
   az keyvault create --name $kvName --resource-group $rg --location $location
   
   # Add VM password secret
   az keyvault secret set --vault-name $kvName --name "vmpassword2" --value "YOUR-SECURE-PASSWORD"
   ```

2. Clone this repository
3. Navigate to the class-setup directory
4. Run the deployment script:
   ```powershell
   ./deploy.ps1
   ```

The script will:
- Verify your Azure context
- Create/update resource group
- Deploy all resources
- Display connection information

## Security Notes

1. All VM access is through Azure Bastion only
2. No public IPs on VMs
3. NSGs restrict all unnecessary traffic
4. All credentials are stored in Azure Key Vault
5. All resources send logs to Log Analytics

## Cost Optimization

- B-series VMs for cost efficiency
- NSG flow logs retention set to 30 days
- Standard SKU for Azure Firewall
- Consider stopping VMs when not in use

## Student Instructions

1. Clone this repository
2. Navigate to the class-setup directory
3. Run the deployment script with your Azure Pass subscription:
   ```powershell
   ./deploy.ps1
   ```
4. Follow the prompts to verify your Azure context
5. Wait for deployment to complete (approximately 30-45 minutes)

## Cleanup

To remove all resources:
```powershell
Remove-AzResourceGroup -Name "az104-rg" -Force
```

## Troubleshooting

1. If deployment fails:
   - Check Azure Pass subscription status
   - Verify you're in the correct subscription context
   - Review error messages in the Azure Portal
   
2. If VM access fails:
   - Ensure you're using Azure Bastion
   - Verify NSG rules
   - Check VM status in Azure Portal

## Note to Students

This is a lab environment for learning purposes. The configuration emphasizes learning opportunities over production-ready security. Review and understand each component as part of your AZ-104 studies. 