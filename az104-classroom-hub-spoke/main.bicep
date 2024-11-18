targetScope = 'subscription'

// Parameters
@description('Primary location for all resources')
param location string = 'eastus'
@description('Environment name')
param environmentName string = 'dev'

// Resource Group Names
var hubRgName = 'rg-hub-${environmentName}'
var spokeRgName = 'rg-spoke-${environmentName}'

// Create Resource Groups
resource hubResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubRgName
  location: location
}

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spokeRgName
  location: location
}

// Deploy Hub VNet
module hubVnet 'modules/hub-vnet.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'hubVnetDeployment'
  params: {
    location: location
    environmentName: environmentName
  }
}

// Deploy Spoke VNet
module spokeVnet 'modules/spoke-vnet.bicep' = {
  scope: resourceGroup(spokeResourceGroup.name)
  name: 'spokeVnetDeployment'
  params: {
    location: location
    environmentName: environmentName
    hubVnetId: hubVnet.outputs.vnetId
  }
}

// Deploy Bastion Host
module bastion 'modules/bastion.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'bastionDeployment'
  params: {
    location: location
    hubVnetName: hubVnet.outputs.vnetName
  }
}

// Deploy Virtual Machines
module virtualMachines 'modules/virtual-machines.bicep' = {
  scope: resourceGroup(spokeResourceGroup.name)
  name: 'vmDeployment'
  params: {
    location: location
    environmentName: environmentName
    subnetId: spokeVnet.outputs.vmSubnetId
  }
}

// Deploy Application Gateway
module appGateway 'modules/app-gateway.bicep' = {
  scope: resourceGroup(spokeResourceGroup.name)
  name: 'appGatewayDeployment'
  params: {
    location: location
    environmentName: environmentName
    subnetId: spokeVnet.outputs.appGwSubnetId
  }
}

// Deploy Monitoring Resources
module monitoring 'modules/monitoring.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'monitoringDeployment'
  params: {
    location: location
    environmentName: environmentName
  }
}

// Deploy Private DNS Zones
module privateDns 'modules/private-dns.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'privateDnsDeployment'
  params: {
    hubVnetId: hubVnet.outputs.vnetId
  }
}
