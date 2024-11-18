
param location string = resourceGroup().location

param vmName string

param adminUsername string

@allowed([
  'password'
  'sshPublicKey'
])
param authenticationType string

@secure()
param adminPasswordOrKey string

param vmSize string

param applyCSE bool = true

param cseURI string = 'https://raw.githubusercontent.com/timothywarner/frankenstein/main/vms/linux-cse.sh'

param createNewVnet bool = false

param vnetName string = 'VirtualNetwork'

param addressPrefixes array = [
  '10.0.0.0/16'
]

param subnetName string

param subnetPrefix string

param vnetResourceGroupName string = resourceGroup().name

var subnetId = createNewVnet ? subnet.id : resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

resource nsg 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2017-09-01' = if (createNewVnet) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2017-09-01' = if (createNewVnet) {
  name: '${vnet.name}/${subnetName}'
  properties: {
    addressPrefix: subnetPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2017-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: any(authenticationType != 'password' ? {
        disablePasswordAuthentication: false
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPasswordOrKey
            }
          ]
        }
      } : null)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Virtual Machine Extensions - Custom Script
var virtualMachineExtensionCustomScript = {
  name: '${vm.name}/config-app'
  location: location
  fileUris: [
    cseURI
  ]
  commandToExecute: './linux-cse.sh'
}

resource vmext 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = if (applyCSE) {
  name: virtualMachineExtensionCustomScript.name
  location: virtualMachineExtensionCustomScript.location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: virtualMachineExtensionCustomScript.fileUris
      commandToExecute: virtualMachineExtensionCustomScript.commandToExecute
    }
    protectedSettings: {}
  }
}
