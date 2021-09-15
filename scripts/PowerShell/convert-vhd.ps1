# Convert VHDX to VHD 
Convert-VHD -Path 'C:\users\public\Documents\Hyper-V\Virtual hard disks\win16template.vhdx' -DestinationPath 'c:\VHD\win16template.vhd' -Verbose

# Launch Sysprep
Start-Process -FilePath 'C:\Windows\System32\Sysprep\sysprep.exe'

# Upload to Azure blob storage

