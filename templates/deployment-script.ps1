$subscriptionID = ''
$tenantID = ''
$deploymentName = 'class-db'
$resourceGroupName = 'pluralsight'
$templatePath = './vnets/hub-vnet.bicep'
$context = Get-AzContext

if (($context.Subscription -ne $subscriptionID) -and ($context.Tenant -ne $tenantID)) {
  Connect-AzAccount -Tenant $tenantID
}

New-AzResourceGroupDeployment -Name $deploymentName `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $templatePath `
  -Mode Incremental `
  -Verbose #TODO: integrate with PowerShell background jobs