Remove-Module -Name @('PackageManagement', 'PowerShellGet') -ErrorAction SilentlyContinue;
# https://github.com/PowerShell/PowerShellGet/issues/446
# prevent loading of the old PackageManagement and PowerShellGet modules
$env:PSModulePath = [string]::Join(([IO.Path]::PathSeparator), @($env:PSModulePath.Split([IO.Path]::PathSeparator) | ? { $_ -ne 'C:\Program Files (x86)\WindowsPowerShell\Modules' }));
Import-Module -Name 'PackageManagement' -RequiredVersion '1.4.5' -Force;
Import-Module -Name 'PowerShellGet' -RequiredVersion '2.2.1' -Force;

[string] $module = 'posh-minions-managed';
[string] $userModulePath = ('{0}{1}{2}' -f ($env:PSModulePath.Split([IO.Path]::PathSeparator)[0]), ([IO.Path]::DirectorySeparatorChar), $module);
[string] $moduleSrcPath = ('{0}{1}src' -f $userModulePath, ([IO.Path]::DirectorySeparatorChar));
[string] $clonedSrcModuleDataFile = ('{0}{1}{2}.psd1' -f $env:TRAVIS_BUILD_DIR, ([IO.Path]::DirectorySeparatorChar), $module);
Write-Host ('env:PSModulePath {0}' -f $env:PSModulePath);
Write-Host ('userModulePath {0}' -f $userModulePath);
Write-Host ('moduleSrcPath {0}' -f $moduleSrcPath);
Write-Host ('clonedSrcModuleDataFile {0}' -f $clonedSrcModuleDataFile);
if (New-Item -Path $moduleSrcPath -ItemType 'Directory' -Force) {
  Write-Host ('created path: {0}' -f $moduleSrcPath);
} else {
  Write-Host ('failed to create path: {0}' -f $moduleSrcPath);
}
Remove-Module -Name $module -ErrorAction SilentlyContinue;
$clonedSrcModuleData = (Import-PowerShellDataFile -Path $clonedSrcModuleDataFile);
$copyCount = 0;
foreach ($packageFile in @($clonedSrcModuleData.FileList)) {
  $srcPackageFile = ('{0}{1}{2}' -f $env:TRAVIS_BUILD_DIR.Replace('/', ([IO.Path]::DirectorySeparatorChar.ToString())), ([IO.Path]::DirectorySeparatorChar), $packageFile);
  $dstPackageFile = ('{0}{1}{2}' -f $userModulePath, ([IO.Path]::DirectorySeparatorChar), $packageFile);
  try {
    Copy-Item -Path $srcPackageFile -Destination $dstPackageFile;
    Write-Host ('copied: {0} to {1}' -f $srcPackageFile, $dstPackageFile);
    $copyCount++;
  } catch {
    Write-Host ('failed to copy: {0} to {1}' -f $srcPackageFile, $dstPackageFile);
  }
}
Write-Host ('copied {0}/{1} package files to {2}' -f $copyCount, $clonedSrcModuleData.FileList.Length, $userModulePath);
if ($copyCount -eq $clonedSrcModuleData.FileList.Length) {
  foreach ($requiredModule in $clonedSrcModuleData.RequiredModules) {
    Install-Module -Name $requiredModule.ModuleName -Repository 'PSGallery' -Scope CurrentUser -Verbose;
    Import-Module -Name $requiredModule.ModuleName;
  }
  Import-Module -Name $module;
  Get-Module -Name $module;
  Publish-Module -Name $module -NuGetApiKey $env:NuGetApiKey -Verbose;
  exit 0
} else {
  Write-Host 'module publish skipped';
  exit 1
}
