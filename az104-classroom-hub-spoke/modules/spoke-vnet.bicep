// Parameters
param location string
param environmentName string
param hubVnetId string
param tags object = {}

// Import networking configuration
var networkingConfig = {
  addressPrefix: '10.1.0.0/16'
  subnets: {
    workload: '10.1.1.0/24'
    appGateway: '10.1.2.0/24'
  }
}

// Create Spoke Virtual Network
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-spoke-${environmentName}'
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
        name: 'snet-workload'
        properties: {
          addressPrefix: networkingConfig.subnets.workload
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'snet-appgw'
        properties: {
          addressPrefix: networkingConfig.subnets.appGateway
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Create VNet Peering (Spoke to Hub)
resource spokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVnet
  name: 'peering-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// Outputs
output vnetId string = spokeVnet.id
output vnetName string = spokeVnet.name
output workloadSubnetId string = spokeVnet.properties.subnets[0].id
output appGatewaySubnetId string = spokeVnet.properties.subnets[1].id 
