if ((Get-PSRepository -Name 'PSGallery').InstallationPolicy -ne 'Trusted') {
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted';
  Write-Host 'installation policy for repository: PSGallery, set to Trusted';
}
Get-Module -Name @('PackageManagement', 'PowerShellGet');
Install-Module -Name 'PackageManagement' -RequiredVersion '1.4.5' -AllowClobber -Force;
Install-Module -Name 'PowerShellGet' -RequiredVersion '2.2.1' -AllowClobber -Force;
Remove-Module -Name @('PackageManagement', 'PowerShellGet');
# https://github.com/PowerShell/PowerShellGet/issues/446
# prevent loading of the old PackageManagement and PowerShellGet modules
$env:PSModulePath = [string]::Join(([IO.Path]::PathSeparator), @($env:PSModulePath.Split([IO.Path]::PathSeparator) | ? { $_ -ne 'C:\Program Files (x86)\WindowsPowerShell\Modules' }));
Import-Module -Name 'PackageManagement' -RequiredVersion '1.4.5' -Force;
Import-Module -Name 'PowerShellGet' -RequiredVersion '2.2.1' -Force;
Get-Module -Name @('PackageManagement', 'PowerShellGet');