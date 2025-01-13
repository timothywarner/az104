param location string
param prefix string
param adminPassword string
param hubWorkloadSubnetId string
param spokeWorkloadSubnetId string
param logAnalyticsWorkspaceId string

// Windows VM NIC
resource windowsNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${prefix}-win-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.2.4'
          subnet: {
            id: hubWorkloadSubnetId
          }
        }
      }
    ]
  }
}

// Windows VM
resource windowsVm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${prefix}-win-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'winvm'
      adminUsername: 'azureuser'
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Install IIS on Windows VM
resource windowsVmIIS 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: windowsVm
  name: 'InstallIIS'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Install-WindowsFeature -Name Web-Server,Web-Mgmt-Tools'
    }
  }
}

// Windows VM Auto-shutdown
resource windowsVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${windowsVm.name}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '2300'
    }
    timeZoneId: 'UTC'
    targetResourceId: windowsVm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

// Windows VM Monitoring Extension
resource windowsVmMonitoring 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: windowsVm
  name: 'MicrosoftMonitoringAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsWorkspaceId, '2020-08-01').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceId, '2020-08-01').primarySharedKey
    }
  }
}

// Windows VM Dependency Agent
resource windowsVmDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: windowsVm
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
  }
}

// Linux VM NIC
resource linuxNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${prefix}-linux-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.0.4'
          subnet: {
            id: spokeWorkloadSubnetId
          }
        }
      }
    ]
  }
}

// Linux VM
resource linuxVm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${prefix}-linux-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'linuxvm'
      adminUsername: 'azureuser'
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: linuxNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Linux VM Auto-shutdown
resource linuxVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${linuxVm.name}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '2300'
    }
    timeZoneId: 'UTC'
    targetResourceId: linuxVm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

output windowsVmName string = windowsVm.name
output linuxVmName string = linuxVm.name 
