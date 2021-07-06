$vmName = ""
$vmRgName = ""
$extensionName = "AADLoginForWindows"
$publisher = "Microsoft.Azure.ActiveDirectory"

$vm = Get-AzVm -ResourceGroupName $vmRgName -Name $vmName
Set-AzVMExtension -ResourceGroupName $vmRgName `
                    -VMName $vm.Name `
                    -Name $extensionName `
                    -Location $vm.Location `
                    -Publisher $publisher `
                    -Type "AADLoginForWindows" `
                    -TypeHandlerVersion "0.4"