@description('VNet name')
param vnetName string = 'spoke1-vnet'

@description('VNet address prefix')
param vnetAddressPrefix string = '10.120.0.0/16'

@description('app subnet name')
param spoke1SubnetName string = 'data'

@description('data subnet prefix')
param spoke1SubnetPrefix string = '10.120.1.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: spoke1SubnetName
        properties: {
          addressPrefix: spoke1SubnetPrefix
        }
      }
    ]
  }
}
