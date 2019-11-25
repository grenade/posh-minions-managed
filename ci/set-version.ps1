begin {
  [string] $module = 'posh-minions-managed';
  [string] $path = ('{0}.psd1' -f $module);
  [string] $match = '0.0.0';
  try {
    $version = (Find-Module -Repository 'PSGallery' -Name $module).Version.Split('.');
    $replace = ('{0}.{1}.{2}' -f $version[0], $version[1], (([int] $version[2]) + 1));
  } catch {
    $replace = '0.0.1';
  }
  Write-Host ('begin: replace "{0}" with "{1}" in "{2}"' -f $match, $replace, $path);
}
process {
  $content = ((Get-Content -Path $path) | Foreach-Object { $_ -replace $match, $replace });
  [System.IO.File]::WriteAllLines($path, $content, (New-Object -TypeName 'System.Text.UTF8Encoding' -ArgumentList $false));
  Get-Content -Path $path;
}
end {
  Write-Host ('end: replace "{0}" with "{1}" in "{2}"' -f $match, $replace, $path);
}