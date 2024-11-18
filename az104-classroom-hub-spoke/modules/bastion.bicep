// Parameters
param location string
param environmentName string
param hubVnetName string
param tags object = {}

// Create Public IP for Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-bastion-${environmentName}'
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
  name: 'bas-${environmentName}'
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
