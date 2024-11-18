param vnetName string = 'hub-vnet'
param vnetAddressSpace string = '10.40.0.0/16'
param subnet1Name string = 'web'
param subnet1Prefix string = '10.40.1.0/24'
param subnet2Name string = 'data'
param subnet2Prefix string = '10.40.2.0/24'
param natGatewayName string = 'hubNATGateway1'
param publicIpDNS string = 'gw-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param createNewVNet bool = false

var publicIpName = '${natGatewayName}-ip'

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: publicIpDNS
    }
  }
}

resource natGateway 'Microsoft.Network/natGateways@2020-06-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = if (createNewVNet) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${vnetName}/${subnet1Name}'
  properties: {
    addressPrefix: subnet1Prefix
    natGateway: {
      id: natGateway.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${vnetName}/${subnet2Name}'
  properties: {
    addressPrefix: subnet2Prefix
    natGateway: {
      id: natGateway.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}
