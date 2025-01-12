@description('Primary location for all resources')
param location string

@description('Environment name for resource naming')
param environmentName string

@description('Resource tags')
param tags object = {}

// Use variables for resource naming
var bastionHostName = 'bas-${environmentName}'
var publicIPName = 'pip-${bastionHostName}'

// Create Public IP for Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIPName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Create Bastion Host
resource bastionHost 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: bastionHostName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// Outputs
output bastionId string = bastionHost.id
output bastionName string = bastionHost.name 
