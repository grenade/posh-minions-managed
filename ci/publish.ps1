begin {
  [string] $module = 'posh-minions-managed';
  [string] $modulePath = ('{0}/{1}' -f $env:PSModulePath.Split(':')[0], $module);
  Write-Host ('begin: PSModulePath "{0}"' -f $env:PSModulePath);
}
process {
  New-Item -Path ('{0}/src' -f $modulePath) -ItemType 'Directory' -Force;
  Write-Host ('created paths: "{0}"' -f ('{0}/src' -f $modulePath));
  foreach ($psFile in @(Get-ChildItem -Path 'src/*.psm1')) {
    Copy-Item -Path $psFile -Destination ('{0}/src/' -f $modulePath)
    Write-Host ('copied: "{0}" to "{1}"' -f $psFile, ('{0}/src/' -f $modulePath));
  }
  Copy-Item -Path '*.psd1' -Destination ('{0}/' -f $modulePath)
  Write-Host ('copied: "*.psd1" to "{0}"' -f ('{0}/' -f $modulePath));

  Remove-Module -Name $module -ErrorAction SilentlyContinue
  Import-Module -Name $module
  Get-Module -Name $module
  Publish-Module -Name $module -NuGetApiKey $env:NuGetApiKey
}
end {
  Write-Host ('end: modulePath "{0}"' -f $modulePath);
}