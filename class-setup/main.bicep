targetScope = 'resourceGroup'

param location string
param environmentName string
param keyVaultName string
param keyVaultResourceGroup string = 'permanent-rg'

// Monitoring Module
module monitoring 'modules/monitoring/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    prefix: environmentName
  }
}

// Networking Module
module networking 'modules/networking/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    location: location
    prefix: environmentName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Storage Module
module storage 'modules/storage/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    prefix: environmentName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Key Vault Reference
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroup)
}

// Compute Module
module compute 'modules/compute/compute.bicep' = {
  name: 'compute-deployment'
  params: {
    location: location
    prefix: environmentName
    hubWorkloadSubnetId: networking.outputs.hubWorkloadSubnetId
    spokeWorkloadSubnetId: networking.outputs.spokeWorkloadSubnetId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    adminPassword: keyVault.getSecret('vmpassword2')
  }
  dependsOn: [
    networking
  ]
}

// Logic App Module
module logicApp 'modules/logic/logic.bicep' = {
  name: 'logic-deployment'
  params: {
    location: location
    prefix: environmentName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    monitoring
  ]
}

// Outputs
output storageAccountName string = storage.outputs.storageAccountName
output acrName string = storage.outputs.acrName
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName 
