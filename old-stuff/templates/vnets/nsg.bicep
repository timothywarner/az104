@description('Name for the new VNet.')
param vnetName string = 'TestVNet'

@description('CIDR prefix for the VNet address space.')
param vnetPrefix string = '192.168.0.0/16'

@description('Name for the front end subnet.')
param frontEndSubnetName string = 'FrontEnd'

@description('CIDR address prefix for the front end subnet.')
param frontEndSubnetPrefix string = '192.168.1.0/24'

@description('Name for the back end subnet.')
param backEndSubnetName string = 'BackEnd'

@description('CIDR address prefix for the back end subnet.')
param backEndSubnetPrefix string = '192.168.2.0/24'

@description('Name for the NSG used to allow remote RDP')
param frontEndNSGName string = 'NSG-BackEnd'

@description('Name for the NSG used to allow access to web servers on port 80')
param backEndNSGName string = 'NSG-FrontEnd'

resource backEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: backEndNSGName
  location: resourceGroup().location
  tags: {
    displayName: 'NSG - Remote Access'
  }
  properties: {
    securityRules: [
      {
        name: 'allow-frontend'
        properties: {
          description: 'Allow FE Subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: frontEndSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'block-internet'
        properties: {
          description: 'Block Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 200
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource frontEndNSGName_resource 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: frontEndNSGName
  location: resourceGroup().location
  tags: {
    displayName: 'NSG - Front End'
  }
  properties: {
    securityRules: [
      {
        name: 'rdp-rule'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'web-rule'
        properties: {
          description: 'Allow WEB'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: vnetName
  location: resourceGroup().location
  tags: {
    displayName: 'VNet'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    subnets: [
      {
        name: frontEndSubnetName
        properties: {
          addressPrefix: frontEndSubnetPrefix
          networkSecurityGroup: {
            id: frontEndNSGName_resource.id
          }
        }
      }
      {
        name: backEndSubnetName
        properties: {
          addressPrefix: backEndSubnetPrefix
          networkSecurityGroup: {
            id: backEndNSGName_resource.id
          }
        }
      }
    ]
  }
}
