function Get-CloudPlatform {
  <#
  .SYNOPSIS
    Determines the cloud platform
  .DESCRIPTION
    This function returns a value that is one of 'ec2', 'azure', 'gcloud' or $null.
    The code checks for the existence of well known agent services to make the determination.
  #>
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    $cloudPlatform = $null;
    try {
      $cloudAgentServices = @(Get-Service -Name @('AmazonSSMAgent', 'Ec2Config', 'GCEAgent', 'WindowsAzureGuestAgent', 'WindowsAzureNetAgentSvc') -ErrorAction SilentlyContinue | % { $_.Name });
      if ($cloudAgentServices.Contains('AmazonSSMAgent') -or $cloudAgentServices.Contains('Ec2Config')) {
        $cloudPlatform = 'amazon';
      } elseif ($cloudAgentServices.Contains('WindowsAzureGuestAgent') -or $cloudAgentServices.Contains('WindowsAzureNetAgentSvc')) {
        $cloudPlatform = 'azure';
      } elseif ($cloudAgentServices.Contains('GCEAgent')) {
        $cloudPlatform = 'gcloud';
      }
    } catch {
      Write-Log -message ('{0} :: exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.Message) -severity 'warn';
      if ($_.Exception.InnerException) {
        Write-Log -message ('{0} :: inner exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.InnerException.Message) -severity 'warn';
      }
    }
    return $cloudPlatform;
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function Get-CloudBucketResource {
  <#
  .SYNOPSIS
    Downloads a file resource from a cloud bucket
  #>
  param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('amazon', 'azure', 'google')]
    [string] $platform,

    [Parameter(Mandatory = $true)]
    [string] $bucket,

    [Parameter(Mandatory = $true)]
    [string] $key,

    [Parameter(Mandatory = $true)]
    [string] $destination,

    [switch] $overwrite = $false,

    [switch] $force = $false
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    if ($force) {
      try {
        New-Item -Path ([System.IO.Path]::GetDirectoryName($destination)) -ItemType Directory -Force
        Write-Log -message ('{0} :: destination directory created: {1} ' -f $($MyInvocation.MyCommand.Name), ([System.IO.Path]::GetDirectoryName($destination))) -severity 'debug';
      } catch {
        Write-Log -message ('{0} :: failed to create destination directory: {1} ' -f $($MyInvocation.MyCommand.Name), ([System.IO.Path]::GetDirectoryName($destination))) -severity 'error';
      }
    }
    try {
      if (-not (Test-Path -Path ([System.IO.Path]::GetDirectoryName($destination)) -ErrorAction SilentlyContinue)) {
        throw [System.IO.DirectoryNotFoundException]('destination directory path does not exist: {0}. use `-force` switch or specify a destination directory path that exists.' -f ([System.IO.Path]::GetDirectoryName($destination)));
      }
      if ((-not $overwrite) -and (Test-Path -Path $destination -ErrorAction SilentlyContinue)) {
        throw [System.ArgumentException]('destination file exists: {0}. use `-overwrite` switch or specify a destination file path that does not exist.' -f $destination);
      }
      switch -regex ($platform) {
        'amazon' {
          if (-not (Get-CloudCredentialAvailability -platform $platform)) {
            throw ('no credentials detected for platform: {0}' -f $platform);
          }
          # https://docs.aws.amazon.com/powershell/latest/reference/items/Copy-S3Object.html
          Copy-S3Object -BucketName $bucket -Key $key -LocalFile $destination;
          break;
        }
        'azure' {
          # https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageblobcontent?view=azps-1.8.0
          Get-AzStorageBlobContent -Container $bucket -Blob $key -Destination $destination;
          break;
        }
        'google' {
          Read-GcsObject -Bucket $bucket -ObjectName $key -OutFile $destination;
          break;
        }
        default {
          throw [System.ArgumentException]('unsupported platform: {0}. use: amazon|azure|google' -f $platform);
          break;
        }
      }
      if (Test-Path -Path $destination -ErrorAction SilentlyContinue) {
        Write-Log -message ('{0} :: {1} fetched from {2}/{3}/{4}' -f $($MyInvocation.MyCommand.Name), $destination, $platform, $bucket, $key) -severity 'info';
      } else {
        Write-Log -message ('{0} :: error fetching {1} from {2}/{3}/{4}' -f $($MyInvocation.MyCommand.Name), $destination, $platform, $bucket, $key) -severity 'warn';
      }
    } catch {
      Write-Log -message ('{0} :: exception fetching {1} from {2}/{3}/{4}: {5}' -f $($MyInvocation.MyCommand.Name), $destination, $platform, $bucket, $key, $_.Exception.Message) -severity 'error';
      if ($_.Exception.InnerException) {
        Write-Log -message ('{0} :: inner exception fetching {1} from {2}/{3}/{4}: {5}' -f $($MyInvocation.MyCommand.Name), $destination, $platform, $bucket, $key, $_.Exception.InnerException.Message) -severity 'error';
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function Get-CloudCredentialAvailability {
  <#
  .SYNOPSIS
    Downloads a file resource from a cloud bucket
  #>
  param (
    [ValidateSet('amazon', 'azure', 'google')]
    [string] $platform
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    switch ($platform) {
      'amazon' {
        return ((@(Get-AWSCredential -ErrorAction SilentlyContinue).Length -gt 0) -or (@(Get-AWSCredential -ListProfileDetail -ErrorAction SilentlyContinue).Length -gt 0));
        break;
      }
      'azure' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      'google' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      default {
        throw [System.ArgumentException]('unsupported platform: {0}. use: amazon-s3|azure-blob-storage|google-cloud-storage' -f $platform);
        break;
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function New-CloudInstanceFromImageExport {
  <#
  .SYNOPSIS
    Instantiates a new cloud instance from an exported image
  #>
  param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('amazon', 'azure', 'google')]
    [string] $platform,

    [Parameter(Mandatory = $true)]
    [string] $localImagePath,

    [Parameter(Mandatory = $true)]
    [string] $targetResourceId,

    [Parameter(Mandatory = $true)]
    [string] $targetResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $targetResourceRegion,

    [Parameter(Mandatory = $true)]
    [string] $targetInstanceName,

    [string] $targetInstanceMachineVariantFormat = 'Standard_F{0}s_v2',

    [int] $targetInstanceCpuCount = 2,

    [int] $targetInstanceRamGb = 8,

    [hashtable] $targetInstanceTags = @{},

    [ValidateSet('ssd', 'hdd')]
    [string] $targetInstanceDiskVariant = 'ssd',

    [Parameter(Mandatory = $true)]
    [int] $targetInstanceDiskSizeGb,

    [int] $targetInstanceDiskIops,

    [Parameter(Mandatory = $true)]
    [string] $targetVirtualNetworkName,

    [Parameter(Mandatory = $true)]
    [string] $targetVirtualNetworkAddressPrefix,

    [string[]] $targetVirtualNetworkDnsServers = @('1.1.1.1', '1.0.0.1'),

    [Parameter(Mandatory = $true)]
    [string] $targetSubnetName,
    
    [Parameter(Mandatory = $true)]
    [string] $targetSubnetAddressPrefix,

    [string] $targetFirewallConfigurationName = ('{0}-{1}' -f $(if ($platform -eq 'azure') { 'nsg' } else { 'fwc' }), $targetResourceGroupName),
    [hashtable[]] $targetFirewallRules = @(
      @{
        'Name' = 'rdp-only';
        'Description' = 'allow: inbound tcp connections, for: rdp, from: anywhere, to: any host, on port: 3389';
        'Access' = 'Allow';
        'Protocol' = 'Tcp';
        'Direction' = 'Inbound';
        'Priority' = 110;
        'SourceAddressPrefix' = 'Internet';
        'SourcePortRange' = '*';
        'DestinationAddressPrefix' = '*';
        'DestinationPortRange' = '3389'
      },
      @{
        'Name' = 'ssh-only';
        'Description' = 'allow: inbound tcp connections, for: ssh, from: anywhere, to: any host, on port: 22';
        'Access' = 'Allow';
        'Protocol' = 'Tcp';
        'Direction' = 'Inbound';
        'Priority' = 120;
        'SourceAddressPrefix' = 'Internet';
        'SourcePortRange' = '*';
        'DestinationAddressPrefix' = '*';
        'DestinationPortRange' = '22'
      }
    )
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';

    Write-Log -message ('{0} :: param/platform: {1}' -f $($MyInvocation.MyCommand.Name), $platform) -severity 'trace';
    Write-Log -message ('{0} :: param/localImagePath: {1}' -f $($MyInvocation.MyCommand.Name), $localImagePath) -severity 'trace';

    Write-Log -message ('{0} :: param/targetResourceId: {1}' -f $($MyInvocation.MyCommand.Name), $targetResourceId) -severity 'trace';
    Write-Log -message ('{0} :: param/targetResourceGroupName: {1}' -f $($MyInvocation.MyCommand.Name), $targetResourceGroupName) -severity 'trace';
    Write-Log -message ('{0} :: param/targetResourceRegion: {1}' -f $($MyInvocation.MyCommand.Name), $targetResourceRegion) -severity 'trace';

    Write-Log -message ('{0} :: param/targetInstanceName: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName) -severity 'trace';
    foreach ($key in $targetInstanceTags.Keys) {
      Write-Log -message ('{0} :: param/targetInstanceTags.{1}: {2}' -f $($MyInvocation.MyCommand.Name), $key, $targetInstanceTags[$key]) -severity 'trace';
    }
    Write-Log -message ('{0} :: param/targetInstanceMachineVariantFormat: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceMachineVariantFormat) -severity 'trace';
    Write-Log -message ('{0} :: param/targetInstanceCpuCount: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceCpuCount) -severity 'trace';
    Write-Log -message ('{0} :: param/targetInstanceRamGb: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceRamGb) -severity 'trace';

    Write-Log -message ('{0} :: param/targetInstanceDiskVariant: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceDiskVariant) -severity 'trace';
    Write-Log -message ('{0} :: param/targetInstanceDiskSizeGb: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceDiskSizeGb) -severity 'trace';
    Write-Log -message ('{0} :: param/targetInstanceDiskIops: {1}' -f $($MyInvocation.MyCommand.Name), $targetInstanceDiskIops) -severity 'trace';

    Write-Log -message ('{0} :: param/targetVirtualNetworkName: {1}' -f $($MyInvocation.MyCommand.Name), $targetVirtualNetworkName) -severity 'trace';
    Write-Log -message ('{0} :: param/targetVirtualNetworkAddressPrefix: {1}' -f $($MyInvocation.MyCommand.Name), $targetVirtualNetworkAddressPrefix) -severity 'trace';
    for ($i = 0; $i -lt $targetVirtualNetworkDnsServers.Length; $i++) {
      Write-Log -message ('{0} :: param/targetVirtualNetworkDnsServers[{1}]: {2}' -f $($MyInvocation.MyCommand.Name), $i, $targetVirtualNetworkDnsServers[$i]) -severity 'trace';
    }
    Write-Log -message ('{0} :: param/targetSubnetName: {1}' -f $($MyInvocation.MyCommand.Name), $targetSubnetName) -severity 'trace';
    Write-Log -message ('{0} :: param/targetSubnetAddressPrefix: {1}' -f $($MyInvocation.MyCommand.Name), $targetSubnetAddressPrefix) -severity 'trace';

    Write-Log -message ('{0} :: param/targetFirewallConfigurationName: {1}' -f $($MyInvocation.MyCommand.Name), $targetFirewallConfigurationName) -severity 'trace';
    for ($i = 0; $i -lt $targetFirewallRules.Length; $i++) {
      foreach ($key in $targetFirewallRules[$i].Keys) {
        Write-Log -message ('{0} :: param/targetFirewallRules[{1}].{2}: {3}' -f $($MyInvocation.MyCommand.Name), $i, $key, $targetFirewallRules[$i][$key]) -severity 'trace';
      }
    }
  }
  process {
    switch -regex ($platform) {
      'amazon' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      'azure' {
        switch ($targetInstanceCpuCount) {
          default {
            switch ($targetInstanceRamGb) {
              default {
                $azMachineVariant = ($targetInstanceMachineVariantFormat -f $targetInstanceCpuCount);
                break;
              }
            }
            break;
          }
        }
        Write-Log -message ('{0} :: var/azMachineVariant: {1}' -f $($MyInvocation.MyCommand.Name), $azMachineVariant) -severity 'trace';
        switch ($targetInstanceDiskVariant) {
          'hdd' {
            $azStorageAccountType = 'Standard_LRS';
            break;
          }
          'ssd' {
            $azStorageAccountType = 'StandardSSD_LRS';
            break;
          }
        }
        Write-Log -message ('{0} :: var/azStorageAccountType: {1}' -f $($MyInvocation.MyCommand.Name), $azStorageAccountType) -severity 'trace';
        $tags['resourceId'] = $targetResourceId;

        # resource group
        $azResourceGroup = (Get-AzResourceGroup `
          -Name $targetResourceGroupName `
          -Location $targetResourceRegion `
          -ErrorAction SilentlyContinue);
        if (-not ($azResourceGroup)) {
          $azResourceGroup = (New-AzResourceGroup `
            -Name $targetResourceGroupName `
            -Location $targetResourceRegion);
        }

        # boot/os disk
        $azDiskConfig = (New-AzDiskConfig `
          -SkuName $azStorageAccountType `
          -OsType 'Windows' `
          -UploadSizeInBytes ((Get-Item -Path $localImagePath).Length) `
          -Location $targetResourceRegion `
          -CreateOption 'Upload');
        $azDisk = (New-AzDisk `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName ('disk-{0}' -f $targetResourceId) `
          -Disk $azDiskConfig);
        $azDiskAccess = (Grant-AzDiskAccess `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName $azDisk.Name `
          -DurationInSecond 86400 `
          -Access 'Write');
        & AzCopy.exe @('copy', $localImagePath, ($azDiskAccess.AccessSAS), '--blob-type', 'PageBlob');
        (Revoke-AzDiskAccess `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName $azDisk.Name);

        # networking
        $azVirtualNetwork = (Get-AzVirtualNetwork `
          -Name $targetVirtualNetworkName `
          -ResourceGroupName $targetResourceGroupName `
          -ErrorAction SilentlyContinue);
        if (-not ($azVirtualNetwork)) {
          $azVirtualNetworkSubnetConfig = (New-AzVirtualNetworkSubnetConfig `
            -Name $targetSubnetName `
            -AddressPrefix $targetSubnetAddressPrefix);
          $azVirtualNetwork = (New-AzVirtualNetwork `
            -Name $targetVirtualNetworkName `
            -ResourceGroupName $targetResourceGroupName `
            -Location $targetResourceRegion `
            -AddressPrefix $targetVirtualNetworkAddressPrefix `
            -Subnet $azVirtualNetworkSubnetConfig `
            -DnsServer $targetVirtualNetworkDnsServers);
        }
        $azNetworkSecurityGroup = (Get-AzNetworkSecurityGroup `
          -Name $targetFirewallConfigurationName `
          -ResourceGroupName $targetResourceGroupName `
          -ErrorAction SilentlyContinue);
        if (-not ($azNetworkSecurityGroup)) {
          $azNetworkSecurityRuleConfigs = @($targetFirewallRules | % { (New-AzNetworkSecurityRuleConfig `
            -Name $_.Name `
            -Description $_.Description `
            -Access $_.Access `
            -Protocol $_.Protocol `
            -Direction $_.Direction `
            -Priority $_.Priority `
            -SourceAddressPrefix $_.SourceAddressPrefix `
            -SourcePortRange $_.SourcePortRange `
            -DestinationAddressPrefix $_.DestinationAddressPrefix `
            -DestinationPortRange $_.DestinationPortRange) });
          $azNetworkSecurityGroup = (New-AzNetworkSecurityGroup `
            -Name $targetFirewallConfigurationName `
            -ResourceGroupName $targetResourceGroupName `
            -Location $targetResourceRegion `
            -SecurityRules $azNetworkSecurityRuleConfigs);
        }
        $azPublicIpAddress = (New-AzPublicIpAddress `
          -Name ('ip-{0}' -f $targetResourceId) `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -AllocationMethod 'Dynamic');

        $azNetworkInterface = (New-AzNetworkInterface `
          -Name ('ni-{0}' -f $targetResourceId) `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -SubnetId $azVirtualNetwork.Subnets[0].Id `
          -PublicIpAddressId $azPublicIpAddress.Id `
          -NetworkSecurityGroupId $azNetworkSecurityGroup.Id);

        # virtual machine
        $azVM = (New-AzVMConfig `
          -VMName $targetInstanceName `
          -VMSize $azMachineVariant);
        $azVM = (Add-AzVMNetworkInterface `
          -VM $azVM `
          -Id $azNetworkInterface.Id);
        $azVM = (Set-AzVMOSDisk `
          -VM $azVM `
          -ManagedDiskId $azDisk.Id `
          -StorageAccountType $azStorageAccountType `
          -DiskSizeInGB $targetInstanceDiskSizeGb `
          -CreateOption 'Attach' `
          -Windows:$true);
        $azVM = (New-AzVM `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -Tag $targetInstanceTags `
          -VM $azVM);
        $azVM;
        # todo: return something. maybe a hashtable describing the created instance?
        break;
      }
      'google' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      default {
        throw [System.ArgumentException]('unsupported platform: {0}. use: amazon-s3|azure-blob-storage|google-cloud-storage' -f $platform);
        break;
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function New-CloudImageFromInstance {
  <#
  .SYNOPSIS
    Instantiates a new cloud instance from an exported image
  #>
  param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('amazon', 'azure', 'google')]
    [string] $platform,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $region,

    [Parameter(Mandatory = $true)]
    [string] $instanceName,

    [Parameter(Mandatory = $true)]
    [string] $imageName,

    [hashtable] $imageTags = $null
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    switch -regex ($platform) {
      'amazon' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      'azure' {
        $azVMStatus = (Get-AzVM `
          -ResourceGroupName $resourceGroupName `
          -Name $instanceName `
          -Status);
        if (($azVMStatus) -and ($azVMStatus.Statuses | ? { ($_.Code -eq 'PowerState/running') })) {
          $stopOperation = (Stop-AzVM `
            -ResourceGroupName $resourceGroupName `
            -Name $instanceName `
            -Force `
            -ErrorAction SilentlyContinue);
          Write-Log -message ('{0} :: stop operation on instance: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $instanceName, $resourceGroupName, $stopOperation.Status) -severity 'debug';
        }
        $generalizeOperation = (Set-AzVm `
          -ResourceGroupName $resourceGroupName `
          -Name $instanceName `
          -Generalized);
        Write-Log -message ('{0} :: generalize operation on instance: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $instanceName, $resourceGroupName, $generalizeOperation.Status) -severity 'debug';
        $azVM = (Get-AzVM `
          -ResourceGroupName $resourceGroupName `
          -Name $instanceName);
        try {
          if ($imageTags) {
            $azImageConfig = (New-AzImageConfig `
              -Location $region `
              -Tag $imageTags `
              -SourceVirtualMachineId $azVM.Id);
          } else {
            $azImageConfig = (New-AzImageConfig `
              -Location $region `
              -SourceVirtualMachineId $azVM.Id);
          }
          Write-Log -message ('{0} :: image config creation operation from instance id: {1}, in region: {2}, completed' -f $($MyInvocation.MyCommand.Name), $azVM.Id, $azVM.Location) -severity 'debug';
          try {
            $azImage = (New-AzImage `
              -Image $azImageConfig `
              -ImageName $imageName `
              -ResourceGroupName $resourceGroupName);
            Write-Log -message ('{0} :: image creation operation from instance: {1}, in resource group: {2}, has status: {3}, for image: {4}, in region: {5}' -f $($MyInvocation.MyCommand.Name), $instanceName, $resourceGroupName, $azImage.ProvisioningState, $azImage.Name, $azImage.Location) -severity 'debug';
          } catch {
            Write-Log -message ('{0} :: image creation operation for image: {1}, in resource group: {2}, threw exception: {3}' -f $($MyInvocation.MyCommand.Name), $imageName, $resourceGroupName, $_.Exception.Message) -severity 'warn';
            if ($_.Exception.InnerException) {
              Write-Log -message ('{0} :: image creation operation for image: {1}, in resource group: {2}, threw inner exception: {3}' -f $($MyInvocation.MyCommand.Name), $imageName, $resourceGroupName, $_.Exception.InnerException.Message) -severity 'warn';
            }
          }
        } catch {
          Write-Log -message ('{0} :: image config creation operation from instance: {1}, in region: {2}, threw exception: {3}' -f $($MyInvocation.MyCommand.Name), $instanceName, $region, $_.Exception.Message) -severity 'warn';
          if ($_.Exception.InnerException) {
            Write-Log -message ('{0} :: image config creation operation from instance: {1}, in region: {2}, threw inner exception: {3}' -f $($MyInvocation.MyCommand.Name), $instanceName, $region, $_.Exception.InnerException.Message) -severity 'warn';
          }
        }
        break;

      }
      'google' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      default {
        throw [System.ArgumentException]('unsupported platform: {0}. use: amazon-s3|azure-blob-storage|google-cloud-storage' -f $platform);
        break;
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}