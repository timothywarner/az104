param hubVnetName string = 'hub-vnet'
param spoke1VnetName string = 'spoke1-vnet'
param spoke2VnetName string = 'spoke2-vnet'
param remoteVnetRg string = 'prod-rg'

resource peer1 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${hubVnetName}/hub-to-spoke1'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', spoke1VnetName)
    }
  }
}

resource peer2 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${spoke1VnetName}/spoke1-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', hubVnetName)
    }
  }
}

resource peer3 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${hubVnetName}/hub-to-spoke2'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', spoke2VnetName)
    }
  }
}

resource peer4 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  name: '${spoke2VnetName}/spoke2-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetRg, 'Microsoft.Network/virtualNetworks', hubVnetName)
    }
  }
}
