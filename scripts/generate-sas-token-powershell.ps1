Ref: https://timw.info/2pn

$context = (Get-AzStorageAccount -ResourceGroupName 'oreilly' -AccountName 'oreillystg7044').context

New-AzStorageAccountSASToken -Context $context -Service Blob, File, Table, Queue -ResourceType Service, Container, Object -Permission racwdlup

StorageAccountName = 'oreillystg7044'
 $ContainerName = 'scripts'
 Create a storage context
 $sasToken = ''
 $StorageContext = New-AzStorageContext $StorageAccountName -SasToken $sasToken
 Upload a file
 $storageContainer = Get-AzStorageContainer -Name $ContainerName -Context $StorageContext
 $storageContainer | Set-AzStorageBlobContent –File 'D:\file.txt' –Blob 'file.txt'
