# AZ-104 Lab Environment - Instructor Guide

This document provides instructions for managing the AZ-104 lab environment, including setup and cleanup procedures.

## Environment Management

### Initial Setup

1. Create Key Vault and secret:
   ```powershell
   $rg = "az104-rg"
   $location = "southcentralus"
   $kvName = "YOUR-KV-NAME"
   
   # Create Key Vault
   az keyvault create --name $kvName --resource-group $rg --location $location
   
   # Add VM password secret
   az keyvault secret set --vault-name $kvName --name "vmpassword2" --value "YOUR-SECURE-PASSWORD"
   ```

2. Deploy environment:
   ```powershell
   ./deploy.ps1 -KeyVaultName "YOUR-KV-NAME"
   ```

### Quick Reset

To reset the environment between classes:

1. Run cleanup script:
   ```powershell
   ./cleanup.ps1
   ```

2. Redeploy environment:
   ```powershell
   ./deploy.ps1
   ```

### Cost Management

- Environment uses cost-optimized components:
  - B-series VMs
  - Standard SKU for Azure Firewall
  - 30-day retention for logs
  
- Estimated daily cost: ~$20-25 USD
- Remember to delete resources after class

### Security Notes

1. Key Vault Management:
   - Use Azure RBAC for access control
   - Regularly rotate VM passwords
   - Monitor Key Vault access logs

2. Network Security:
   - All VM access through Bastion only
   - NSGs on all subnets
   - Azure Firewall in hub network

3. Monitoring:
   - All resources send logs to Log Analytics
   - NSG flow logs enabled
   - Traffic Analytics configured

## GitHub Advanced Security

This repository is configured with GitHub Advanced Security (GHAS) features:

1. Secret Scanning:
   - Enabled for push protection
   - Scans for Azure credentials and tokens
   - Alerts on potential secret exposure

2. Best Practices:
   - Never commit credentials or secrets
   - Use environment variables for sensitive values
   - Review security alerts promptly

## Troubleshooting

### Common Issues

1. Deployment Failures:
   - Verify subscription quota limits
   - Check Key Vault access
   - Review activity logs in Azure Portal

2. VM Access Issues:
   - Verify Bastion is deployed
   - Check NSG rules
   - Verify VM status

3. Cleanup Issues:
   - Check for resource locks
   - Verify Azure context
   - Use force flag if needed

### Support

For issues or questions:
1. Check Azure Portal activity logs
2. Review deployment logs
3. Contact repository maintainers 