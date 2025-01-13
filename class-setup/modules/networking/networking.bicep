param location string
param prefix string
param logAnalyticsWorkspaceId string

// Networking parameters
param hubVnetAddressPrefix string = '10.0.0.0/16'
param spokeVnetAddressPrefix string = '10.1.0.0/16'
param firewallSubnetPrefix string = '10.0.0.0/24'
param gatewaySubnetPrefix string = '10.0.1.0/24'
param bastionSubnetPrefix string = '10.0.3.0/24'
param hubWorkloadSubnetPrefix string = '10.0.2.0/24'
param appGatewaySubnetPrefix string = '10.0.4.0/24'
param spokeWorkloadSubnetPrefix string = '10.1.0.0/24'
param aksSubnetPrefix string = '10.1.1.0/24'

// WAF Policy
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-05-01' = {
  name: '${prefix}-waf-policy'
  location: location
  properties: {
    customRules: []
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

// Hub VNET
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${prefix}-hub-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: appGatewaySubnetPrefix
        }
      }
      {
        name: 'HubWorkloadSubnet'
        properties: {
          addressPrefix: hubWorkloadSubnetPrefix
          networkSecurityGroup: {
            id: hubNsg.id
          }
          routeTable: {
            id: hubRouteTable.id
          }
        }
      }
    ]
  }
}

// Spoke VNET
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${prefix}-spoke-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'WorkloadSubnet'
        properties: {
          addressPrefix: spokeWorkloadSubnetPrefix
          networkSecurityGroup: {
            id: spokeNsg.id
          }
          routeTable: {
            id: spokeRouteTable.id
          }
        }
      }
      {
        name: 'AksSubnet'
        properties: {
          addressPrefix: aksSubnetPrefix
          routeTable: {
            id: spokeRouteTable.id
          }
        }
      }
    ]
  }
}

// Hub NSG with open rules
resource hubNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${prefix}-hub-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAll'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Spoke NSG with open rules
resource spokeNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${prefix}-spoke-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAll'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Route Tables
resource hubRouteTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: '${prefix}-hub-rt'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'ToFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.4'  // Firewall private IP
        }
      }
    ]
  }
}

resource spokeRouteTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: '${prefix}-spoke-rt'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'ToFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.4'  // Firewall private IP
        }
      }
    ]
  }
}

// Application Gateway Public IP
resource appGatewayPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${prefix}-appgw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Application Gateway
resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: '${prefix}-appgw'
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/AppGatewaySubnet'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: appGatewayPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'iisPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: '10.0.2.4'  // Windows VM static IP
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'iisSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: 'iisListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${prefix}-appgw', 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${prefix}-appgw', 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'iisRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${prefix}-appgw', 'iisListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${prefix}-appgw', 'iisPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${prefix}-appgw', 'iisSettings')
          }
        }
      }
    ]
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}

// VNET Peering Hub to Spoke
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: hubVnet
  name: '${hubVnet.name}-to-${spokeVnet.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// VNET Peering Spoke to Hub
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVnet
  name: '${spokeVnet.name}-to-${hubVnet.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

// Azure Firewall Public IP
resource firewallPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${prefix}-firewall-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: '${prefix}-firewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: firewallPip.id
          }
        }
      }
    ]
    threatIntelMode: 'Alert'
  }
}

// Diagnostic Settings for Azure Firewall
resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: firewall
  name: '${prefix}-firewall-diag'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: '${prefix}-vpn-gateway'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/GatewaySubnet'
          }
          publicIPAddress: {
            id: vpnGatewayPip.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}

// VPN Gateway Public IP
resource vpnGatewayPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${prefix}-vpn-gateway-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion Host
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${prefix}-bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: '${prefix}-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${hubVnet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

// Network Watcher
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-05-01' = {
  name: '${prefix}-networkwatcher'
  location: location
}

// NSG Flow Logs
resource hubNsgFlowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  parent: networkWatcher
  name: '${hubNsg.name}-flowlog'
  location: location
  properties: {
    targetResourceId: hubNsg.id
    storageId: flowLogStorage.id
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalyticsWorkspaceId
        trafficAnalyticsInterval: 10
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: 30
      enabled: true
    }
  }
}

resource spokeNsgFlowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  parent: networkWatcher
  name: '${spokeNsg.name}-flowlog'
  location: location
  properties: {
    targetResourceId: spokeNsg.id
    storageId: flowLogStorage.id
    enabled: true
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalyticsWorkspaceId
        trafficAnalyticsInterval: 10
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: 30
      enabled: true
    }
  }
}

// Storage for NSG Flow Logs
resource flowLogStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: replace('${prefix}flowlogs', '-', '')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// Diagnostic Settings for Hub VNet
resource hubVnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${hubVnet.name}-diag'
  scope: hubVnet
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

// Diagnostic Settings for Spoke VNet
resource spokeVnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${spokeVnet.name}-diag'
  scope: spokeVnet
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
      }
    ]
  }
}

// Diagnostic Settings for Application Gateway
resource appGatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appGateway.name}-diag'
  scope: appGateway
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
  }
}

// Diagnostic Settings for VPN Gateway
resource vpnGatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${vpnGateway.name}-diag'
  scope: vpnGateway
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'GatewayDiagnosticLog'
        enabled: true
      }
      {
        category: 'TunnelDiagnosticLog'
        enabled: true
      }
      {
        category: 'RouteDiagnosticLog'
        enabled: true
      }
      {
        category: 'IKEDiagnosticLog'
        enabled: true
      }
    ]
  }
}

// Diagnostic Settings for Bastion Host
resource bastionDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${bastionHost.name}-diag'
  scope: bastionHost
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'BastionAuditLogs'
        enabled: true
      }
    ]
  }
}

// Outputs for other modules
output hubVnetId string = hubVnet.id
output spokeVnetId string = spokeVnet.id
output hubWorkloadSubnetId string = '${hubVnet.id}/subnets/HubWorkloadSubnet'
output spokeWorkloadSubnetId string = '${spokeVnet.id}/subnets/WorkloadSubnet'
output aksSubnetId string = '${spokeVnet.id}/subnets/AksSubnet'
output appGatewayPublicIp string = appGatewayPip.properties.ipAddress 
