// Parameters
param location string
param environmentName string
param tags object = {}

// Import networking configuration
var networkingConfig = {
  addressPrefix: '10.0.0.0/16'
  subnets: {
    AzureBastionSubnet: '10.0.1.0/24'    // Required name for Bastion
    GatewaySubnet: '10.0.2.0/24'         // Required name for VPN Gateway
    AzureFirewallSubnet: '10.0.3.0/24'   // Required name for Firewall
  }
}

// Create Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-hub-${environmentName}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkingConfig.addressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: networkingConfig.subnets.AzureBastionSubnet
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: networkingConfig.subnets.GatewaySubnet
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: networkingConfig.subnets.AzureFirewallSubnet
        }
      }
    ]
  }
}

// Outputs
output vnetId string = hubVnet.id
output vnetName string = hubVnet.name
output bastionSubnetId string = hubVnet.properties.subnets[0].id
output gatewaySubnetId string = hubVnet.properties.subnets[1].id
output firewallSubnetId string = hubVnet.properties.subnets[2].id 
