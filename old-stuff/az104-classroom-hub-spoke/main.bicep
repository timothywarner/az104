/*
  Hub-Spoke Network Infrastructure Deployment
  
  This template deploys a hub-spoke network topology with the following components:
  
  Hub Resources (rg-hub-{env}):
  - Hub Virtual Network with subnets for Bastion, Gateway, and Firewall
  - Azure Bastion Service
  - Monitoring resources
  - Private DNS Zones
  
  Spoke Resources (rg-spoke-{env}):
  - Spoke Virtual Network peered with Hub
  - Virtual Machines (Windows & Linux)
  - Application Gateway
  - Supporting network infrastructure
  
  Usage:
  1. Customize variables.bicep with your desired values
  2. Deploy using:
     az deployment sub create \
       --location eastus \
       --template-file main.bicep \
       --parameters environmentName=dev
  
  Reference Architecture:
  https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke
*/

targetScope = 'subscription'

// Parameters
@description('Primary location for all resources')
param location string = 'eastus'
@description('Environment name - dev, test, or prod')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

// Add default tags that will be applied to all resources
var defaultTags = {
  environment: environmentName
  project: 'az104-classroom'
  deployedBy: 'bicep'
}

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
    tags: defaultTags
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
    tags: defaultTags
  }
}

// Deploy Bastion Host
module bastion 'modules/bastion.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'bastionDeployment'
  params: {
    location: location
    hubVnetName: hubVnet.outputs.vnetName
    tags: defaultTags
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
    tags: defaultTags
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
    tags: defaultTags
  }
}

// Deploy Monitoring Resources
module monitoring 'modules/monitoring.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'monitoringDeployment'
  params: {
    location: location
    environmentName: environmentName
    tags: defaultTags
  }
}

// Deploy Private DNS Zones
module privateDns 'modules/private-dns.bicep' = {
  scope: resourceGroup(hubResourceGroup.name)
  name: 'privateDnsDeployment'
  params: {
    hubVnetId: hubVnet.outputs.vnetId
    tags: defaultTags
  }
}
