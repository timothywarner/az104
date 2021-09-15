@description('VNet name')
param vnetName string = 'spoke2-vnet'

@description('VNet address prefix')
param vnetAddressPrefix string = '10.140.0.0/16'

@description('app subnet name')
param spoke2SubnetName string = 'data'

@description('web subnet prefix')
param spoke2SubnetPrefix string = '10.140.1.0/24'

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
        name: spoke2SubnetName
        properties: {
          addressPrefix: spoke2SubnetPrefix
        }
      }
    ]
  }
}
