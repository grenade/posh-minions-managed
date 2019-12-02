# login:
Connect-AzAccount

# this succeeded. disks can be seen at: https://portal.azure.com/#blade/HubsExtension/BrowseResourceBlade/resourceType/Microsoft.Compute%2Fdisks
# or with:
# Get-AzDisk -ResourceGroupName 'gecko-t' -name 'windows10*'
# Get-AzDisk -ResourceGroupName 'gecko-1' -name 'windowsserver201*'
foreach ($vhdPath in @(Get-ChildItem -Path 'D:\azure-ci\*.vhd')) {
  $resourceGroupName = $(if ($vhdPath.Name.Contains('server')) { 'gecko-1' } else { 'gecko-t' });
  $diskName = [io.path]::GetFileNameWithoutExtension($vhdPath.Name).Replace('-fixed.vhd', '');
  $targetLocation = 'East US';
  $storageSkuName = 'StandardSSD_LRS'; #Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS
  $osType = 'Windows'; # Windows, Linux
  $vhdSizeBytes = (Get-Item -Path $vhdPath.FullName).Length;
  $diskconfig = New-AzDiskConfig -SkuName $storageSkuName -OsType $osType -UploadSizeInBytes $vhdSizeBytes -Location $targetLocation -CreateOption 'Upload';
  New-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName -Disk $diskconfig;
  $diskSas = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $diskName -DurationInSecond 86400 -Access 'Write';
  $disk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $diskName;
  & AzCopy.exe @('copy', $vhdPath.FullName, $diskSas.AccessSAS, '--blob-type', 'PageBlob')
  Revoke-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $diskName;
}

# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/upload-generalized-managed
# none of what's below works yet.
# figure out how to get the BlobUri required by Set-AzImageOsDisk
$targetLocation = 'East US';
$osType = 'Windows';


foreach ($vhdPath in @(Get-ChildItem -Path 'D:\azure-ci\*.vhd')) {
  $resourceId = (([Guid]::NewGuid()).ToString().Substring(24));
  $vmName = ('vm-{0}' -f $resourceId);
  $vmSize = 'Standard_A2';

  # disks
  $resourceGroupName = $(if ($vhdPath.Name.Contains('server')) { 'gecko-1' } else { 'gecko-t' });
  $osDiskName = [io.path]::GetFileNameWithoutExtension($vhdPath.Name).Replace('-fixed.vhd', '');
  $osDisk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $osDiskName;
  $osDiskSizeInGb = 128;

  # networking
  $virtualNetworkName = ('{0}-vnet' -f $resourceGroupName);
  #$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet;
  $virtualNetwork = (Get-AzVirtualNetwork -Name $virtualNetworkName);

  #$allowRdpNsr = New-AzNetworkSecurityRuleConfig -Name myRdpRule -Description 'Allow RDP' -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
  #$nsgName = ('{0}-nsg' -f $vmName)
  #$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $targetLocation -Name $nsgName -SecurityRules $allowRdpNsr
  # todo: recreate nsg with name corresponding to resource group name and location
  $networkSecurityGroup = (Get-AzNetworkSecurityGroup -Name 'vm-d3ff927c7414-nsg');
  $publicIpAddressName = ('ip-{0}' -f $resourceId)
  $publicIpAddress = New-AzPublicIpAddress `
    -Name $publicIpAddressName `
    -ResourceGroupName $resourceGroupName `
    -Location $targetLocation `
    -AllocationMethod 'Dynamic'

  $networkInterfaceName = ('ni-{0}' -f $resourceId)
  $networkInterface = New-AzNetworkInterface `
    -Name $networkInterfaceName `
    -ResourceGroupName $resourceGroupName `
    -Location $targetLocation `
    -SubnetId $virtualNetwork.Subnets[0].Id `
    -PublicIpAddressId $publicIpAddress.Id `
    -NetworkSecurityGroupId $networkSecurityGroup.Id

  # virtual machine
  $vm = Add-AzVMNetworkInterface `
    -VM (New-AzVMConfig -VMName $vmName -VMSize $vmSize) `
    -Id $networkInterface.Id
  $vm = Set-AzVMOSDisk `
    -VM $vm `
    -ManagedDiskId $osDisk.Id `
    -StorageAccountType $osDiskType `
    -DiskSizeInGB $osDiskSizeInGb `
    -CreateOption Attach `
    -Windows:$true
  New-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Location $targetLocation `
    -VM $vm
  Get-AzVM `
    -ResourceGroupName $resourceGroupName




















  $imageConfig = New-AzImageConfig -Location $targetLocation
  
  Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -StorageAccountType $osDiskType -DiskSizeInGB $osDiskSizeInGb -CreateOption Attach -Windows
  $imageOsDisk = Set-AzImageOsDisk `
   -Image $imageConfig `
   -OsType $osType `
   -OsState 'Generalized' ` # https://azure.microsoft.com/en-us/blog/vm-image-blog-post/
   -BlobUri $urlOfUploadedImageVhd `
   -DiskSizeGB 20
  
  New-AzImage `
   -ImageName $imageName `
   -ResourceGroupName $rgName `
   -Image $imageConfig
  
  New-AzVm `
    -ResourceGroupName $rgName `
    -Name "myVM" `
    -ImageName $imageName `
    -Location $location `
    -VirtualNetworkName "myVnet" `
    -SubnetName "mySubnet" `
    -SecurityGroupName "myNSG" `
    -PublicIpAddressName "myPIP" `
    -OpenPorts 3389
}