# create the ASGs
$webAsg = New-AzApplicationSecurityGroup -ResourceGroupName Contoso -Name webAsg -Location eastus
$sqlAsg = New-AzApplicationSecurityGroup -ResourceGroupName Contoso -Name sqlAsg -Location eastus

# define NSG rules that reference ASG
$webRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowHttps" `
    -Access Allow `
    -Protocol Tcp `
    -Direction outbound `
    -Priority 1500 `
    -SourceApplicationSecurityGroupId $webAsg.id `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange 443

$sqlRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowSql" `
    -Access Allow `
    -Protocol Tcp `
    -Direction outbound `
    -Priority 1000 `
    -SourceApplicationSecurityGroupId $sqlAsg.id `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange 1433

# Create an NSG, plugging in new rules
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName asgTest -Location westcentralus -Name asgTest -SecurityRules $webRule, $sqlRule

# Assign NSG to a subnet
$vnet = Get-AzVirtualNetwork -Name asgtest -ResourceGroupName asgtest
Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $vnet -NetworkSecurityGroupId $nsg.Id -AddressPrefix '10.1.0.0/24'
Set-AzVirtualNetwork -VirtualNetwork $vnet

# Assign vNICs to ASG
$webNic = Get-AzNetworkInterface -Name web134 -ResourceGroupName asgtest
$webNic.IpConfigurations[0].ApplicationSecurityGroups = $webAsg
Set-AzNetworkInterface -NetworkInterface $webNic

$sqlNic = Get-AzNetworkInterface -Name sql1333 -ResourceGroupName asgtest
$sqlNic.IpConfigurations[0].ApplicationSecurityGroups = $sqlAsg
Set-AzNetworkInterface -NetworkInterface $sqlNic