# Linux VM / SSH Keys

# Generate SSH key pair
ssh-keygen -t rsa -b 2048

# Display your public key
cat ~/.ssh/id_rsa.pub

# SSH into your VM
ssh user@vmaddress

# Quick create VM
# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name "mySubnet" `
    -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName "myResourceGroup" `
    -Location "EastUS" `
    -Name "myVNET" `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
    -ResourceGroupName "myResourceGroup" `
    -Location "EastUS" `
    -AllocationMethod Static `
    -IdleTimeoutInMinutes 4 `
    -Name "mypublicdns$(Get-Random)"

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "myNetworkSecurityGroupRuleSSH"  `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22 `
    -Access "Allow"

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
    -Name "myNetworkSecurityGroupRuleWWW"  `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 1001 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80 `
    -Access "Allow"

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName "myResourceGroup" `
    -Location "EastUS" `
    -Name "myNetworkSecurityGroup" `
    -SecurityRules $nsgRuleSSH, $nsgRuleWeb

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
    -Name "myNic" `
    -ResourceGroupName "myResourceGroup" `
    -Location "EastUS" `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id `
    -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
    -VMName "myVM" `
    -VMSize "Standard_D1" | `
    Set-AzVMOperatingSystem `
    -Linux `
    -ComputerName "myVM" `
    -Credential $cred `
    -DisablePasswordAuthentication | `
    Set-AzVMSourceImage `
    -PublisherName "Canonical" `
    -Offer "UbuntuServer" `
    -Skus "16.04-LTS" `
    -Version "latest" | `
    Add-AzVMNetworkInterface `
    -Id $nic.Id

# Configure the SSH key
$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
    -VM $vmconfig `
    -KeyData $sshPublicKey `
    -Path "/home/azureuser/.ssh/authorized_keys"

New-AzVM `
    -ResourceGroupName "myResourceGroup" `
    -Location eastus -VM $vmConfig

# Connect to the VM
Get-AzPublicIpAddress -ResourceGroupName "myResourceGroup" | Select "IpAddress"

ssh azureuser@10.111.12.123

# Install a web server
sudo apt-get -y update
sudo apt-get -y install nginx

# Browser to http://pubip
