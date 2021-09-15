
param location string = resourceGroup().location

param vmName string

@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
  '2016-Nano-Server'
  '2016-Datacenter-with-Containers'
  '2016-Datacenter'
  '2019-Datacenter'
])
param windowsOSVersion string

param adminUsername string

@secure()
param adminPassword string

param vmSize string

param createNewVnet bool = false

param applyCSE bool = true

param cseURI string = 'https://raw.githubusercontent.com/timothywarner/frankenstein/main/vms/windows-cse.ps1'

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
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
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
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
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
  commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ./${last(split(cseURI, '/'))}'
}

resource vmext 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if (applyCSE) {
  name: virtualMachineExtensionCustomScript.name
  location: virtualMachineExtensionCustomScript.location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: virtualMachineExtensionCustomScript.fileUris
      commandToExecute: virtualMachineExtensionCustomScript.commandToExecute
    }
    protectedSettings: {}
  }
}
