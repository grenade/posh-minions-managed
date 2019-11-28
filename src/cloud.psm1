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
          # https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstoragefilecontent?view=azps-1.8.0
          Get-AzStorageFileContent -ShareName $bucket -Path $key -Destination $destination;
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