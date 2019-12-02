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
        $cloudPlatform = 'ec2';
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
    [ValidateSet('amazon', 'aws', 's3', 'azure', 'azure-blob-storage', 'az', 'google', 'google-cloud-storage', 'gcloud', 'gcp', 'gcs')]
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
        'amazon|aws|s3' {
          if (-not (Get-CloudCredentialAvailability -platform $platform)) {
            throw ('no credentials detected for platform: {0}' -f $platform);
          }
          # https://docs.aws.amazon.com/powershell/latest/reference/items/Copy-S3Object.html
          Copy-S3Object -BucketName $bucket -Key $key -LocalFile $destination;
          break;
        }
        'azure|azure-blob-storage|az' {
          # https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageblobcontent?view=azps-1.8.0
          Get-AzStorageBlobContent -Container $bucket -Blob $key -Destination $destination;
          break;
        }
        'google|google-cloud-storage|gcloud|gcp|gcs' {
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
    [ValidateSet('amazon', 'aws', 's3', 'azure', 'azure-blob-storage', 'az', 'google', 'google-cloud-storage', 'gcloud', 'gcp', 'gcs')]
    [string] $platform
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    switch -regex ($platform) {
      'amazon|aws|s3' {
        return ((@(Get-AWSCredential -ErrorAction SilentlyContinue).Length -gt 0) -or (@(Get-AWSCredential -ListProfileDetail -ErrorAction SilentlyContinue).Length -gt 0));
        break;
      }
      'azure|azure-blob-storage|az' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      'google|google-cloud-storage|gcloud|gcp|gcs' {
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
    [ValidateSet('amazon', 'aws', 'ec2', 'azure', 'az', 'google', 'google-cloud-compute', 'google-compute-engine', 'gcloud', 'gcp', 'gce')]
    [string] $platform,

    [Alias('path', 'imagePath')]
    [string] $localImagePath,

    [Alias('resourceId')]
    [string] $targetResourceId,

    [Alias('rg', 'resourceGroup')]
    [string] $targetResourceGroupName,

    [Alias('region', 'location', 'targetRegion', 'targetLocation')]
    [string] $targetResourceRegion,

    [int] $targetInstanceCpuCount,

    [int] $targetInstanceRamGb,

    [Alias('hostname', 'instance', 'instanceName', 'targetInstance')]
    [string] $targetInstanceName,

    [Alias('vnet', 'virtualNetwork', 'networkName')]
    # todo: implement regional/location specific naming
    [string] $targetVirtualNetworkName

    [ValidateSet('ssd', 'hdd')]
    [Alias('disk', 'diskType')]
    [string] $targetInstanceDiskVariant = 'ssd',
    [int] $targetInstanceDiskSizeGb,

    [hashtable] $targetInstanceTags = @{},

    [string] $targetVirtualNetworkAddressPrefix = '10.0.0.0/16',
    [string[]] $targetVirtualNetworkDnsServers = @('1.1.1.1', '1.0.0.1'),
    [string] $targetSubnetAddressPrefix = '10.0.1.0/24'

    # todo: implement iops selection
    #[int] $diskIops = 0,
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    switch -regex ($platform) {
      'amazon|aws|s3' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      'azure|az' {
        switch ($targetInstanceCpuCount) {
          default {
            switch ($targetInstanceRamGb) {
              default {
                $azMachineVariant = ('Standard_A{0}' -f $targetInstanceCpuCount);
                break;
              }
            }
            break;
          }
        }
        switch ($targetDiskVariant) {
          'hdd' {
            $azStorageAccountType = 'Standard_LRS';
            break;
          }
          'ssd' {
            $azStorageAccountType = 'StandardSSD_LRS';
            break;
          }
        }
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
        $azDisk = New-AzDisk `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName ('disk-{0}' -f $targetResourceId) `
          -Disk $azDiskConfig;
        $azDiskAccess = Grant-AzDiskAccess `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName $azDisk.Name `
          -DurationInSecond 86400 `
          -Access 'Write';
        & AzCopy.exe @('copy', $localImagePath, ($azDiskAccess.AccessSAS), '--blob-type', 'PageBlob');
        Revoke-AzDiskAccess `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName $azDisk.Name;

        # networking
        $azVirtualNetwork = (Get-AzVirtualNetwork `
          -Name $targetVirtualNetworkName `
          -ResourceGroupName $targetResourceGroupName `
          -ErrorAction SilentlyContinue);
        if (-not ($azVirtualNetwork)) {
          $azVirtualNetworkSubnetConfig = (New-AzVirtualNetworkSubnetConfig `
            -Name ('sn-{0}' -f $targetResourceId) `
            -AddressPrefix $subnetAddressPrefix);
          $azVirtualNetwork = (New-AzVirtualNetwork `
            -Name $targetVirtualNetworkName `
            -ResourceGroupName $targetResourceGroupName `
            -Location $targetResourceRegion `
            -AddressPrefix $virtualNetworkAddressPrefix `
            -Subnet $azVirtualNetworkSubnetConfig `
            -DnsServer $targetVirtualNetworkDnsServers);
        }
        $azNetworkSecurityGroup = (Get-AzNetworkSecurityGroup `
          -Name $target.network.flow[0] `
          -ResourceGroupName $targetResourceGroupName `
          -ErrorAction SilentlyContinue);
        if (-not ($azNetworkSecurityGroup)) {
          $rdpAzNetworkSecurityRuleConfig = (New-AzNetworkSecurityRuleConfig `
            -Name 'rdp-only' `
            -Description 'allow: inbound tcp connections, for: rdp, from: anywhere, to: any host, on port: 3389' `
            -Access 'Allow' `
            -Protocol 'Tcp' `
            -Direction 'Inbound' `
            -Priority 110 `
            -SourceAddressPrefix 'Internet' `
            -SourcePortRange '*' `
            -DestinationAddressPrefix '*' `
            -DestinationPortRange 3389);
          $sshAzNetworkSecurityRuleConfig = (New-AzNetworkSecurityRuleConfig `
            -Name 'ssh-only' `
            -Description 'allow: inbound tcp connections, for: ssh, from: anywhere, to: any host, on port: 22' `
            -Access 'Allow' `
            -Protocol 'Tcp' `
            -Direction 'Inbound' `
            -Priority 120 `
            -SourceAddressPrefix 'Internet' `
            -SourcePortRange '*' `
            -DestinationAddressPrefix '*' `
            -DestinationPortRange 22);
          $azNetworkSecurityGroup = New-AzNetworkSecurityGroup `
            -Name $target.network.flow[0] `
            -ResourceGroupName $targetResourceGroupName `
            -Location $targetResourceRegion `
            -SecurityRules @($rdpAzNetworkSecurityRuleConfig, $sshAzNetworkSecurityRuleConfig);
        }
        $azPublicIpAddress = New-AzPublicIpAddress `
          -Name ('ip-{0}' -f $targetResourceId) `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -AllocationMethod 'Dynamic';

        $azNetworkInterface = New-AzNetworkInterface `
          -Name ('ni-{0}' -f $targetResourceId) `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -SubnetId $azVirtualNetwork.Subnets[0].Id `
          -PublicIpAddressId $azPublicIpAddress.Id `
          -NetworkSecurityGroupId $azNetworkSecurityGroup.Id;

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
        # todo: return something. maybe a hashtable describing the created instance?
        break;
      }
      'google|google-cloud-compute|google-compute-engine|gcloud|gcp|gce' {
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
    [ValidateSet('amazon', 'aws', 'ec2', 'azure', 'az', 'google', 'google-cloud-compute', 'google-compute-engine', 'gcloud', 'gcp', 'gce')]
    [string] $platform,

    [Alias('rg', 'resourceGroup')]
    [string] $resourceGroupName,

    [Alias('region', 'location', 'targetRegion', 'targetLocation')]
    [string] $region,

    [Alias('hostname', 'instance', 'instanceName', 'targetInstance')]
    [string] $instanceName,

    [string] $imageName,
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    switch -regex ($platform) {
      'amazon|aws|s3' {
        throw [System.NotImplementedException]('this method is awaiting implementation for platform: {0}' -f $platform);
        break;
      }
      'azure|az' {
        Stop-AzVM `
          -ResourceGroupName $resourceGroupName `
          -Name $instanceName `
          -Force `
          -ErrorAction SilentlyContinue
        Set-AzVm `
          -ResourceGroupName $resourceGroupName `
          -Name $instanceName `
          -Generalized
        $azVM = (Get-AzVM `
          -ResourceGroupName $resourceGroupName `
          -Name $instanceName);
        $azImageConfig = (New-AzImageConfig `
          -Location $region `
          -SourceVirtualMachineId $azVM.Id);
        $azImage = (New-AzImage `
          -Image $azImageConfig `
          -ImageName $imageName `
          -ResourceGroupName $resourceGroupName);
        $azImage;
        break;

      }
      'google|google-cloud-compute|google-compute-engine|gcloud|gcp|gce' {
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