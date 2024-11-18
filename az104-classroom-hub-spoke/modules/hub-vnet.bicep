// Parameters
param location string
param environmentName string
param tags object = {}

// Network configuration
var networkConfig = {
  addressSpace: {
    addressPrefixes: [
      '10.0.0.0/16'
    ]
  }
  subnets: [
    {
      name: 'AzureBastionSubnet'
      properties: {
        addressPrefix: '10.0.1.0/24'
      }
    }
    {
      name: 'GatewaySubnet'
      properties: {
        addressPrefix: '10.0.2.0/24'
      }
    }
    {
      name: 'AzureFirewallSubnet'
      properties: {
        addressPrefix: '10.0.3.0/24'
      }
    }
  ]
}

// Create Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-hub-${environmentName}'
  location: location
  tags: tags
  properties: {
    addressSpace: networkConfig.addressSpace
    subnets: networkConfig.subnets
  }
}

// Outputs
output vnetId string = hubVnet.id
output vnetName string = hubVnet.name
output bastionSubnetId string = hubVnet.properties.subnets[0].id
output gatewaySubnetId string = hubVnet.properties.subnets[1].id
output firewallSubnetId string = hubVnet.properties.subnets[2].id 
