# AZ-104 Lab Environment

This repository contains Infrastructure as Code (IaC) templates to deploy a comprehensive Azure lab environment for AZ-104 certification preparation.

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

1. Azure Subscription with appropriate permissions
2. PowerShell 7.0 or later
3. Az PowerShell module
4. Key Vault with VM credentials (setup instructions provided separately)

## Deployment

1. Clone this repository
2. Navigate to the infrastructure directory
3. Run the deployment script:
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

## Contributing

Please submit issues and pull requests for any improvements.

## License

See [LICENSE](LICENSE) file.

## Disclaimer

This is a lab environment for learning purposes. Review and adjust security settings before using in any other scenario.
