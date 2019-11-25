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