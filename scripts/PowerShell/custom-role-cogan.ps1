Ref: https://samcogan.com/custom-azure-rbac-roles/

Get-AzureRmRoleDefinition -Name "Virtual Machine Contributor" | ConvertTo-Json | Out-File "C:\Temp\Virtual Machine Contributor.json"

Get-AzureRMProviderOperation "Microsoft.Compute/*" | fl Operation

# Add "Microsoft.Compute/Disks*",

New-AzureRmRoleDefinition -InputFile 'C:\temp\Virtual Machine Managed Disk Contributor.json'


