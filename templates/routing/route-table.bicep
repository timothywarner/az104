
param routeTableName string = 'default-route-table'
param location string = resourceGroup().location

resource routetable 'Microsoft.Network/routeTables@2020-07-01' = {
  name: routeTableName
  location: location
  tags: {}
  properties: {
    routes: [
      {
        id: 'azure-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '1.2.3.4'
        }
        name: 'AzureFirewall'
      }
      {
        id: 'vnet-gateway'
        properties: {
          addressPrefix: '192.168.0.0/16'
          nextHopType: 'VirtualNetworkGateway'
        }
        name: 'VNetGateway'
      }
      {
        id: 'internet'
        properties: {
          addressPrefix: '8.8.8.8/32'
          nextHopType: 'Internet'
        }
        name: 'Internet'
      }
    ]
    disableBgpRoutePropagation: true
  }
}
