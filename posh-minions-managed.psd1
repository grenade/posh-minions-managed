@{

  # Script module or binary module file associated with this manifest
  RootModule = 'src/posh-minions-managed.psm1'

  # Version number of this module.
  ModuleVersion = '0.0.0'

  # ID used to uniquely identify this module
  GUID = 'f11f38c0-b9f6-4314-8f00-e277872fed72'

  # Author of this module
  Author = 'Rob Thijssen (https://grenade.github.io)'

  # Company or vendor of this module
  CompanyName = ''

  # Copyright statement for this module
  Copyright = '(c) 2019 Rob Thijssen. All rights reserved.'

  # Description of the functionality provided by this module
  Description = 'a powershell library for spawning, manipulating and slaughtering cloud minions'

  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '2.0'

  # Name of the Windows PowerShell host required by this module
  # PowerShellHostName = ''

  # Minimum version of the Windows PowerShell host required by this module
  # PowerShellHostVersion = ''

  # Minimum version of the .NET Framework required by this module
  DotNetFrameworkVersion = '2.0'

  # Minimum version of the common language runtime (CLR) required by this module
  CLRVersion = '2.0.50727'

  # Processor architecture (None, X86, Amd64) required by this module
  # ProcessorArchitecture = ''

  # Modules that must be imported into the global environment prior to importing this module
  RequiredModules = @(
    @{
      ModuleName='AWS.Tools.S3';
      ModuleVersion='4.0.1.1';
      GUID='b4e504bd-3d14-4563-918a-91025140eba4'
    },
    @{
      ModuleName='Azure.Storage';
      ModuleVersion='4.6.1';
      GUID='00612bca-fa22-401d-a671-9cc48b010e3b'
    },
    @{
      ModuleName='GoogleCloud';
      ModuleVersion='1.0.1.10';
      GUID='e74637e6-7a4e-422d-bb9c-ca50809d78bb'
    }
  )

  # Assemblies that must be loaded prior to importing this module
  # RequiredAssemblies = @()

  # Script files (.ps1) that are run in the caller's environment prior to importing this module
  # ScriptsToProcess = @()

  # Type files (.ps1xml) to be loaded when importing this module
  # TypesToProcess = @()

  # Format files (.ps1xml) to be loaded when importing this module
  # FormatsToProcess = @()

  # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
  NestedModules = @()

  # Functions to export from this module and nested modules
  FunctionsToExport = @(
    # src/posh-minions-managed.psm1
    'Write-Log',

    # src/cloud.psm1
    'Get-CloudPlatform',
    'Get-CloudBucketResource',

    # src/sysprep.psm1
    'Convert-WindowsImage',
    'New-UnattendFile',
    'New-Password'
  )

  # Cmdlets to export from this module
  CmdletsToExport = @()

  # Variables to export from this module
  VariablesToExport = @()

  # Aliases to export from this module
  AliasesToExport = @()

  # List of all modules packaged with this module
  # ModuleList = @()

  # List of all files packaged with this module
  FileList = @(
    # Test-ModuleManifest is broken on linux (directory separator) and will throw exceptions when it can't cope with finding these files
    #'posh-minions-managed.psd1',
    #'src/posh-minions-managed.psm1',
    #'src/cloud.psm1',
    #'src/sysprep.psm1'
  )

  # Private data to pass to the module specified in RootModule/ModuleToProcess
  PrivateData = @{
    PSData = @{     
      # Tags applied to this module. These help with module discovery in online galleries.
      Tags = @(
        'ami',
        'aws',
        'azure',
        'cloud',
        'ec2',
        'gcloud',
        'image',
        'iso',
        'password',
        'platform',
        'sysprep',
        'vhd'
        'unattend',
        'vhd'
      )
      
      # A URL to the license for this module.
      LicenseUri = 'https://opensource.org/licenses/MIT'
      
      # A URL to the main website for this project.
      ProjectUri = 'https://github.com/grenade/posh-minions-managed'
    }
  }

  # HelpInfo URI of this module
  # HelpInfoURI = ''

  # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
  # DefaultCommandPrefix = ''

}