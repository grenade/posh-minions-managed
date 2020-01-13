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
        New-Item -Path ([System.IO.Path]::GetDirectoryName($destination)) -ItemType Directory -Force | Out-Null;
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
          Copy-S3Object -BucketName $bucket -Key $key -LocalFile $destination | Out-Null;
          break;
        }
        'azure' {
          # https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageblobcontent?view=azps-1.8.0
          Get-AzStorageBlobContent -Container $bucket -Blob $key -Destination $destination | Out-Null;
          break;
        }
        'google' {
          # https://googlecloudplatform.github.io/google-cloud-powershell/#/google-cloud-storage/GcsObject/Read-GcsObject
          Read-GcsObject -Bucket $bucket -ObjectName $key -OutFile $destination | Out-Null;
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

function Set-CloudBucketResource {
  <#
  .SYNOPSIS
    Uploads a local file resource to a cloud bucket
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
    [string] $source
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    try {
      switch -regex ($platform) {
        'amazon' {
          if (-not (Get-CloudCredentialAvailability -platform $platform)) {
            throw ('no credentials detected for platform: {0}' -f $platform);
          }
          # https://docs.aws.amazon.com/powershell/latest/reference/items/Write-S3Object.html
          Write-S3Object -BucketName $bucket -Key $key -File $source | Out-Null;
          break;
        }
        'azure' {
          # https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageblobcontent?view=azps-1.8.0
          Set-AzStorageBlobContent -Container $bucket -Blob $key -File $source | Out-Null;
          break;
        }
        'google' {
          # https://googlecloudplatform.github.io/google-cloud-powershell/#/google-cloud-storage/GcsObject/Write-GcsObject
          Write-GcsObject -Bucket $bucket -ObjectName $key -File $source | Out-Null;
          break;
        }
        default {
          throw [System.ArgumentException]('unsupported platform: {0}. use: amazon|azure' -f $platform);
          break;
        }
      }
      Write-Log -message ('{0} :: {1} uploaded to {2}/{3}/{4}' -f $($MyInvocation.MyCommand.Name), $source, $platform, $bucket, $key) -severity 'info';
    } catch {
      Write-Log -message ('{0} :: exception uploading {1} to {2}/{3}/{4}: {5}' -f $($MyInvocation.MyCommand.Name), $source, $platform, $bucket, $key, $_.Exception.Message) -severity 'error';
      if ($_.Exception.InnerException) {
        Write-Log -message ('{0} :: inner exception uploading {1} to {2}/{3}/{4}: {5}' -f $($MyInvocation.MyCommand.Name), $source, $platform, $bucket, $key, $_.Exception.InnerException.Message) -severity 'error';
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function Test-CloudBucketResource {
  <#
  .SYNOPSIS
    Checks whether or not a cloud bucket resource exists
  #>
  param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('amazon', 'azure', 'google')]
    [string] $platform,

    [Parameter(Mandatory = $true)]
    [string] $bucket,

    [Parameter(Mandatory = $true)]
    [string] $key
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace' -supressOutput:$true;
  }
  process {
    switch -regex ($platform) {
      'amazon' {
        if (-not (Get-CloudCredentialAvailability -platform $platform)) {
          throw ('no credentials detected for platform: {0}' -f $platform);
        }
        # https://docs.aws.amazon.com/powershell/latest/reference/items/Get-S3Object.html
        return [bool] (@(Get-S3Object -BucketName $bucket -Key $key).Length -gt 0);
        break;
      }
      'azure' {
        # https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageblob?view=azps-1.8.0
        return [bool] (@(Get-AzStorageBlob -Container $bucket -Blob $key).Length -gt 0);
        break;
      }
      'google' {
        # https://googlecloudplatform.github.io/google-cloud-powershell/#/google-cloud-storage/GcsObject/Get-GcsObject
        return [bool] (@(Get-GcsObject -Bucket $bucket -ObjectName $key).Length -gt 0);
        break;
      }
      default {
        throw [System.ArgumentException]('unsupported platform: {0}. use: amazon|azure' -f $platform);
        break;
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace' -supressOutput:$true;
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

    [hashtable[]] $targetInstanceDisks = @(
      @{
        'Variant' = 'ssd';
        'SizeInGB' = 64;
        'Os' = $true
      },
      @{
        'Variant' = 'ssd';
        'SizeInGB' = 128
      }
    ),

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

    for ($i = 0; $i -lt $targetInstanceDisks.Length; $i++) {
      foreach ($key in $targetInstanceDisks[$i].Keys) {
        Write-Log -message ('{0} :: param/targetInstanceDisks[{1}].{2}: {3}' -f $($MyInvocation.MyCommand.Name), $i, $key, $targetInstanceDisks[$i][$key]) -severity 'trace';
      }
    }

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
          Write-Log -message ('{0} :: resource group create operation for resource group: {1}, in region: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $targetResourceGroupName, $targetResourceRegion, $azResourceGroup.ProvisioningState) -severity 'debug';
        } else {
          Write-Log -message ('{0} :: resource group find operation for resource group: {1}, in region: {2}, suceeded' -f $($MyInvocation.MyCommand.Name), $targetResourceGroupName, $targetResourceRegion) -severity 'debug';
        }

        # boot/os disk
        $azDiskConfig = (New-AzDiskConfig `
          -SkuName 'StandardSSD_LRS' `
          -OsType 'Windows' `
          -UploadSizeInBytes ((Get-Item -Path $localImagePath).Length) `
          -Location $targetResourceRegion `
          -CreateOption 'Upload');
        Write-Log -message ('{0} :: disk config create operation for disk: {1}, with disk variant: {2}, completed' -f $($MyInvocation.MyCommand.Name), ('disk-{0}' -f $targetResourceId), 'StandardSSD_LRS') -severity 'debug';
        $azDisk = (New-AzDisk `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName ('disk-{0}' -f $targetResourceId) `
          -Disk $azDiskConfig);
        Write-Log -message ('{0} :: disk create operation for disk: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), ('disk-{0}' -f $targetResourceId), $targetResourceGroupName, $azDisk.ProvisioningState) -severity 'debug';
        $azDiskAccessGrantOperation = (Grant-AzDiskAccess `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName $azDisk.Name `
          -DurationInSecond 86400 `
          -Access 'Write');
        Write-Log -message ('{0} :: grant access operation on disk: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $azDisk.Name, $targetResourceGroupName, $azDiskAccessGrantOperation.Status) -severity 'debug';
        & AzCopy.exe @('copy', $localImagePath, ($azDiskAccessGrantOperation.AccessSAS), '--blob-type', 'PageBlob');
        $azDiskAccessRevokeOperation = (Revoke-AzDiskAccess `
          -ResourceGroupName $targetResourceGroupName `
          -DiskName $azDisk.Name);
        Write-Log -message ('{0} :: revoke access operation on disk: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $azDisk.Name, $targetResourceGroupName, $azDiskAccessRevokeOperation.Status) -severity 'debug';

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
          Write-Log -message ('{0} :: virtual network create operation for virtual network: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $targetVirtualNetworkName, $targetResourceGroupName, $azVirtualNetwork.ProvisioningState) -severity 'debug';
        } else {
          Write-Log -message ('{0} :: virtual network find operation for virtual network: {1}, in resource group: {2}, suceeded' -f $($MyInvocation.MyCommand.Name), $targetVirtualNetworkName, $targetResourceGroupName) -severity 'debug';
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
          Write-Log -message ('{0} :: network security group create operation for network security group: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $targetFirewallConfigurationName, $targetResourceGroupName, $azNetworkSecurityGroup.ProvisioningState) -severity 'debug';
        } else {
          Write-Log -message ('{0} :: network security group find operation for network security group: {1}, in resource group: {2}, suceeded' -f $($MyInvocation.MyCommand.Name), $targetFirewallConfigurationName, $targetResourceGroupName) -severity 'debug';
        }
        $azPublicIpAddress = (New-AzPublicIpAddress `
          -Name ('ip-{0}' -f $targetResourceId) `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -AllocationMethod 'Dynamic');
        Write-Log -message ('{0} :: public ip address create operation for public ip address: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), ('ip-{0}' -f $targetResourceId), $targetResourceGroupName, $azPublicIpAddress.ProvisioningState) -severity 'debug';

        $azNetworkInterface = (New-AzNetworkInterface `
          -Name ('ni-{0}' -f $targetResourceId) `
          -ResourceGroupName $targetResourceGroupName `
          -Location $targetResourceRegion `
          -SubnetId $azVirtualNetwork.Subnets[0].Id `
          -PublicIpAddressId $azPublicIpAddress.Id `
          -NetworkSecurityGroupId $azNetworkSecurityGroup.Id);
        Write-Log -message ('{0} :: network interface create operation for network interface: {1}, in resource group: {2}, on subnet: {3}, with public ip: {4}, in network security group: {5}, has status: {6}' -f $($MyInvocation.MyCommand.Name), ('ni-{0}' -f $targetResourceId), $targetResourceGroupName, $azVirtualNetwork.Subnets[0].Id.Split('/')[-1], $azPublicIpAddress.Id.Split('/')[-1], $azNetworkSecurityGroup.Id.Split('/')[-1], $azNetworkInterface.ProvisioningState) -severity 'debug';

        # virtual machine
        $azVM = (New-AzVMConfig `
          -VMName $targetInstanceName `
          -VMSize $azMachineVariant);
        Write-Log -message ('{0} :: instance config create operation for instance: {1}, with machine variant: {2}, completed' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $azMachineVariant) -severity 'debug';
        $azVM = (Add-AzVMNetworkInterface `
          -VM $azVM `
          -Id $azNetworkInterface.Id);
        Write-Log -message ('{0} :: add network interface operation for instance: {1}, in resource group: {2}, has status: {3}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $targetResourceGroupName, $azVM.ProvisioningState) -severity 'debug';
        for ($i = 0; $i -lt $targetInstanceDisks.Length; $i++) {
          switch ($targetInstanceDisks[$i].Variant) {
            'hdd' {
              $azDiskVariant = 'Standard_LRS';
              break;
            }
            'ssd' {
              $azDiskVariant = 'StandardSSD_LRS';
              break;
            }
            default {
              $azDiskVariant = 'Standard_LRS';
              break;
            }
          }
          if ($targetInstanceDisks[$i].Os) {
            $azVM = (Set-AzVMOSDisk `
              -VM $azVM `
              -ManagedDiskId $azDisk.Id `
              -StorageAccountType $azDiskVariant `
              -DiskSizeInGB $targetInstanceDisks[$i].SizeInGB `
              -CreateOption 'Attach' `
              -Windows:$true);
            Write-Log -message ('{0} :: set os disk operation for instance: {1}, in resource group: {2}, for os disk: {3}, with disk variant: {4}, has status: {5}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $targetResourceGroupName, $azDisk.Id.Split('/')[-1], $azDiskVariant, $azVM.ProvisioningState) -severity 'debug';
          } else {
            $azVM = (Set-AzVMDataDisk `
              -VM $azVM `
              -Lun ($i - 1) `
              -DiskSizeInGB $targetInstanceDisks[$i].SizeInGB) `
              -StorageAccountType $azDiskVariant;
            Write-Log -message ('{0} :: set data disk operation for instance: {1}, in resource group: {2}, for data disk with lun: {3}, with disk variant: {4}, has status: {5}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $targetResourceGroupName, ($i - 1), $azDiskVariant, $azVM.ProvisioningState) -severity 'debug';
          }
        }
        try {
          $azVM = (New-AzVM `
            -ResourceGroupName $targetResourceGroupName `
            -Location $targetResourceRegion `
            -Tag $targetInstanceTags `
            -VM $azVM);
          Write-Log -message ('{0} :: instance create operation for instance: {1}, with machine variant: {2}, using os disk: {3}, in resource group: {4}, in region: {5}, has status: {6}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $azMachineVariant, $azDisk.Id.Split('/')[-1], $targetResourceGroupName, $targetResourceRegion, $azVM.ProvisioningState) -severity 'debug';
        } catch {
          Write-Log -message ('{0} :: instance create operation for instance: {1}, with machine variant: {2}, using os disk: {3}, in resource group: {4}, in region: {5}, threw exception: {6}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $azMachineVariant, $azDisk.Id.Split('/')[-1], $targetResourceGroupName, $targetResourceRegion, $_.Exception.Message) -severity 'error';
          if ($_.Exception.InnerException) {
            Write-Log -message ('{0} :: instance create operation for instance: {1}, with machine variant: {2}, using os disk: {3}, in resource group: {4}, in region: {5}, threw inner exception: {6}' -f $($MyInvocation.MyCommand.Name), $targetInstanceName, $azMachineVariant, $azDisk.Id.Split('/')[-1], $targetResourceGroupName, $targetResourceRegion, $_.Exception.InnerException.Message) -severity 'error';
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
    Write-Log -message ('{0} :: param/platform: {1}' -f $($MyInvocation.MyCommand.Name), $platform) -severity 'trace';
    Write-Log -message ('{0} :: param/resourceGroupName: {1}' -f $($MyInvocation.MyCommand.Name), $resourceGroupName) -severity 'trace';
    Write-Log -message ('{0} :: param/region: {1}' -f $($MyInvocation.MyCommand.Name), $region) -severity 'trace';
    Write-Log -message ('{0} :: param/instanceName: {1}' -f $($MyInvocation.MyCommand.Name), $instanceName) -severity 'trace';
    Write-Log -message ('{0} :: param/imageName: {1}' -f $($MyInvocation.MyCommand.Name), $imageName) -severity 'trace';
    foreach ($key in $imageTags.Keys) {
      Write-Log -message ('{0} :: param/imageTags.{1}: {2}' -f $($MyInvocation.MyCommand.Name), $key, $imageTags[$key]) -severity 'trace';
    }
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
          Write-Log -message ('{0} :: image config creation operation from instance id: {1}, in region: {2}, completed' -f $($MyInvocation.MyCommand.Name), $instanceName, $region) -severity 'debug';
          try {
            $azImage = (New-AzImage `
              -Image $azImageConfig `
              -ImageName $imageName `
              -ResourceGroupName $resourceGroupName);
            Write-Log -message ('{0} :: image creation operation from instance: {1}, in resource group: {2}, has status: {3}, for image: {4}, in region: {5}' -f $($MyInvocation.MyCommand.Name), $instanceName, $resourceGroupName, $azImage.ProvisioningState, $azImage.Name, $azImage.Location) -severity 'debug';
          } catch {
            Write-Log -message ('{0} :: image create operation for image: {1}, in resource group: {2}, threw exception: {3}' -f $($MyInvocation.MyCommand.Name), $imageName, $resourceGroupName, $_.Exception.Message) -severity 'error';
            if ($_.Exception.InnerException) {
              Write-Log -message ('{0} :: image create operation for image: {1}, in resource group: {2}, threw inner exception: {3}' -f $($MyInvocation.MyCommand.Name), $imageName, $resourceGroupName, $_.Exception.InnerException.Message) -severity 'error';
            }
            throw
          }
        } catch {
          Write-Log -message ('{0} :: image config creation operation from instance: {1}, in region: {2}, threw exception: {3}' -f $($MyInvocation.MyCommand.Name), $instanceName, $region, $_.Exception.Message) -severity 'error';
          if ($_.Exception.InnerException) {
            Write-Log -message ('{0} :: image config creation operation from instance: {1}, in region: {2}, threw inner exception: {3}' -f $($MyInvocation.MyCommand.Name), $instanceName, $region, $_.Exception.InnerException.Message) -severity 'error';
          }
          throw
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