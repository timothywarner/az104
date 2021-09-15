Set-Location -Path '~\azure-admin-crash-course\101-storage-account-create'

code .\azuredeploy.json
code .\azuredeploy.parameters.json

Test-AzResourceGroupDeployment -ResourceGroupName oreilly -Mode Incremental -TemplateFile .\azuredeploy.json -TemplateParameterFile

New-AzResourceGroupDeployment -Name 'deploy-storage-account' `
    -ResourceGroupName oreilly `
    -Mode Incremental `
    -TemplateParameterFile '.\azuredeploy.json' `
    -Verbose