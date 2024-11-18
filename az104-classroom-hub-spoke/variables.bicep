// Environment and Location
@description('Primary location for all resources')
param location string = 'eastus'

@description('Environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

// Networking
var networkingConfig = {
  hub: {
    addressPrefix: '10.0.0.0/16'
    subnets: {
      AzureBastionSubnet: '10.0.1.0/24'    // Required name for Bastion
      GatewaySubnet: '10.0.2.0/24'         // Required name for VPN Gateway
      AzureFirewallSubnet: '10.0.3.0/24'   // Required name for Firewall
    }
  }
  spoke: {
    addressPrefix: '10.1.0.0/16'
    subnets: {
      workload: '10.1.1.0/24'
      appGateway: '10.1.2.0/24'
    }
  }
}

// Resource naming convention
var namingConfig = {
  hub: {
    vnet: 'vnet-hub-${environmentName}'
    nsg: 'nsg-hub-${environmentName}'
    bastion: 'bas-hub-${environmentName}'
  }
  spoke: {
    vnet: 'vnet-spoke-${environmentName}'
    nsg: 'nsg-spoke-${environmentName}'
    appGateway: 'agw-spoke-${environmentName}'
  }
  shared: {
    logAnalytics: 'log-shared-${environmentName}'
    appInsights: 'appi-shared-${environmentName}'
    keyVault: 'kv-shared-${environmentName}'
  }
}

// Tags
var defaultTags = {
  environment: environmentName
  project: 'az104-classroom'
  deployedBy: 'bicep'
}

// Outputs for use in other modules
output location string = location
output environmentName string = environmentName
output networking object = networkingConfig
output naming object = namingConfig
output tags object = defaultTags
