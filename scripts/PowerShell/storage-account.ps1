# Azure Storage Accounts

# List storage accounts
Get-AzStorageAccount | Select StorageAccountName, Location

# Retrieve an existing storage account
$resourceGroup = "myexistingresourcegroup"
$storageAccountName = "myexistingstorageaccount"

$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $storageAccountName

# Create a storage account
# Get list of locations and select one.
Get-AzLocation | select Location
$location = "eastus"

# Create a new resource group.
$resourceGroup = "teststoragerg"
New-AzResourceGroup -Name $resourceGroup -Location $location

# Set the name of the storage account and the SKU name.
$storageAccountName = "testpshstorage"
$skuName = "Standard_LRS"

# Create the storage account.
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $storageAccountName `
    -Location $location `
    -SkuName $skuName

# Retrieve the context.
$ctx = $storageAccount.Context

# Manage access keys
$storageAccountKey = `
(Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroup `
        -Name $storageAccountName).Value[0]


# Regenerate the key
New-AzStorageAccountKey -ResourceGroupName $resourceGroup `
    -Name $storageAccountName `
    -KeyName key1

# Delete the storage account
Remove-AzStorageAccount -ResourceGroup $resourceGroup -AccountName $storageAccountName











