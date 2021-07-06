# Create VNet

# Create RG
$rg = @{
  Name     = 'CreateVNetQS-rg'
  Location = 'EastUS'
}
New-AzResourceGroup @rg

# Create a VNet
$vnet = @{
  Name              = 'myVNet'
  ResourceGroupName = 'CreateVNetQS-rg'
  Location          = 'EastUS'
  AddressPrefix     = '10.0.0.0/16'
}
$virtualNetwork = New-AzVirtualNetwork @vnet

# Add a subnet
$subnet = @{
  Name           = 'default'
  VirtualNetwork = $virtualNetwork
  AddressPrefix  = '10.0.0.0/24'
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnet

# Associate the subnet to the VNet
$virtualNetwork | Set-AzVirtualNetwork

# Create a VM
$vm1 = @{
  ResourceGroupName  = 'CreateVNetQS-rg'
  Location           = 'EastUS'
  Name               = 'myVM1'
  VirtualNetworkName = 'myVNet'
  SubnetName         = 'default'
}
New-AzVM @vm1 -AsJob