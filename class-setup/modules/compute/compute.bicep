param location string
param prefix string
param hubWorkloadSubnetId string
param spokeWorkloadSubnetId string
param logAnalyticsWorkspaceId string

@secure()
param adminPassword string
param adminUsername string = 'azureuser'

var windowsVmName = '${prefix}-win-vm'
var linuxVmName = '${prefix}-linux-vm'

// Network Interfaces with static IPs
resource windowsNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${windowsVmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: hubWorkloadSubnetId
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.2.4'  // Static IP in hub workload subnet
        }
      }
    ]
  }
}

resource linuxNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${linuxVmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: spokeWorkloadSubnetId
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.1.0.4'  // Static IP in spoke workload subnet
        }
      }
    ]
  }
}

// Windows Server VM with IIS
resource windowsVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: windowsVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'winserver'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
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

// Install IIS using Custom Script Extension
resource windowsVmIIS 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: windowsVm
  name: 'InstallIIS'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Install-WindowsFeature -Name Web-Server,Web-Mgmt-Tools -IncludeManagementTools'
    }
  }
}

// Linux VM
resource linuxVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
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

// VM Extensions for Log Analytics
resource windowsVmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: windowsVm
  name: 'MicrosoftMonitoringAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
    }
  }
}

resource linuxVmExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: linuxVm
  name: 'OmsAgentForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.13'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
    }
  }
}

// Dependency Agent for VM Insights
resource windowsDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: windowsVm
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
}

resource linuxDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: linuxVm
  name: 'DependencyAgentLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
}

// Auto-shutdown for Windows VM
resource windowsVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${windowsVmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '23:30' // 5:30 PM Central = 23:30 UTC
    }
    timeZoneId: 'Central Standard Time'
    targetResourceId: windowsVm.id
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: 'timothywarner316@gmail.com'
      notificationLocale: 'en'
    }
  }
}

// Auto-shutdown for Linux VM
resource linuxVmSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${linuxVmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '23:30' // 5:30 PM Central = 23:30 UTC
    }
    timeZoneId: 'Central Standard Time'
    targetResourceId: linuxVm.id
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 30
      emailRecipient: 'timothywarner316@gmail.com'
      notificationLocale: 'en'
    }
  }
} 
