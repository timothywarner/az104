param virtualNetworkName string = 'consumer-vnet'
param vNetIpPrefix string = '10.60.0.0/16'
param bastionSubnetIpPrefix string = '10.60.5.0/24'
param bastionHostName string = 'ps-bastion'
param location string = resourceGroup().location
param createNewVNet bool = false

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${bastionHostName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = if (createNewVNet) {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetIpPrefix
      ]
    }
  }
}

resource subNet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = if(createNewVNet) {
  name: '${virtualNetwork.name}/AzureBastionSubnet'
  properties: {
    addressPrefix: bastionSubnetIpPrefix
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subNet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
