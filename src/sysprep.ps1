function New-UnattendFile {
  <#
  .SYNOPSIS
    Creates a Windows Unattend file
  .DESCRIPTION

  .EXAMPLE
    These examples show how to call the New-UnattendFile function with named parameters.
    # linux:
    PS C:\> New-UnattendFile -destinationPath 'unattend.xml' -productKey 'W269N-WFGWX-YVC9B-4J6C9-T83GX' -registeredOwner 'RelOps Mozilla' -registeredOrganization 'Mozilla Corporation' -administratorPassword $(openssl rand -base64 12)
    # windows:
    PS C:\> New-UnattendFile -destinationPath 'unattend.xml' -productKey 'W269N-WFGWX-YVC9B-4J6C9-T83GX' -registeredOwner 'RelOps Mozilla' -registeredOrganization 'Mozilla Corporation' -administratorPassword (New-Password)
  #>
  [CmdletBinding()]
  param (
    [ValidateNotNullOrEmpty()]
    [string] $destinationPath,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/component-settings-and-properties-reference
    [ValidateSet('amd64', 'arm', 'arm64', 'ia64', 'x86')]
    [string] $processorArchitecture = 'amd64',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-computername
    [string] $computerName = '*',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-useraccounts-administratorpassword
    [string] $administratorPassword,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-productkey
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-userdata-productkey
    [ValidateNotNullOrEmpty()]
    [string] $productKey,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-registeredorganization
    [string] $registeredOrganization = '',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-registeredowner
    [string] $registeredOwner = '',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-uilanguage
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-winpe-uilanguage
    [string] $uiLanguage = 'en-US',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-uilanguagefallback
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-winpe-uilanguagefallback
    [string] $uiLanguageFallback = 'en-US',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-inputlocale
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-winpe-inputlocale
    [string] $inputLocale = $uiLanguage,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-systemlocale
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-winpe-systemlocale
    [string] $systemLocale = $uiLanguage,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-userlocale
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-international-core-winpe-userlocale
    [string] $userLocale = $uiLanguage,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-timezone
    # https://support.microsoft.com/en-us/help/973627/microsoft-time-zone-index-values (use string value of column with header "Name of Time Zone')
    [string] $timeZone = 'UTC',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-diagnostics-optin
    [bool] $diagnosticsOptIn = $false,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-dynamicupdate-enable
    [bool] $dynamicUpdateEnable = $false,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-dynamicupdate-willshowui
    [ValidateSet('Always', 'OnError', 'Never')]
    [string] $dynamicUpdateWillShowUI = 'Never',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-userdata-accepteula
    [bool] $acceptEula = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-userdata-fullname
    [string] $fullName = $registeredOwner,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-userdata-organization
    [string] $organization = $registeredOrganization,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-lua-settings-enablelua
    [bool] $enableLUA = $false,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-security-spp-skiprearm
    [ValidateRange(0, 1)]
    [int] $skipRearm = 1,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-security-spp-ux-skipautoactivation
    [bool] $skipAutoActivation = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-sqmapi-ceipenabled
    [ValidateRange(0, 1)]
    [int] $ceipEnabled = 0,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-hideeulapage
    [bool] $hideEULAPage = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-hideoemregistrationscreen
    [bool] $hideOEMRegistrationScreen = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-hideonlineaccountscreens
    [bool] $hideOnlineAccountScreens = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-hidewirelesssetupinoobe
    [bool] $hideWirelessSetupInOOBE = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-networklocation
    [ValidateSet('Home', 'Work', 'Other')]
    [string] $networkLocation = 'Other',

    # deprecated after 1709
    [bool] $skipMachineOOBE = $true,

    # deprecated after 1709
    [bool] $skipUserOOBE = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc
    [ValidateRange(1, 3)]
    [int] $protectYourPC = 3,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-disableautodaylighttimeset
    [bool] $disableAutoDaylightTimeSet = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands
    [hashtable[]] $commands = @(
      @{
        'Description' = 'say hello';
        'CommandLine' = 'echo "hello beautiful world"'
      },
      @{
        'Description' = 'say goodbye';
        'CommandLine' = 'echo "goodbye cruel world"'
      }
    ),

    [xml] $template = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SetupUILanguage>
        <UILanguage>$uiLanguage</UILanguage>
      </SetupUILanguage>
      <InputLocale>$inputLocale</InputLocale>
      <SystemLocale>$systemLocale</SystemLocale>
      <UILanguage>$uiLanguage</UILanguage>
      <UILanguageFallback>$uiLanguageFallback</UILanguageFallback>
      <UserLocale>$userLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Diagnostics>
        <OptIn>$(if ($diagnosticsOptIn) { 'true' } else { 'false' })</OptIn>
      </Diagnostics>
      <DynamicUpdate>
        <Enable>$(if ($dynamicUpdateEnable) { 'true' } else { 'false' })</Enable>
        <WillShowUI>$dynamicUpdateWillShowUI</WillShowUI>
      </DynamicUpdate>
      <DiskConfiguration>
        <Disk wcm:action="add">
          <CreatePartitions>
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Type>Primary</Type>
              <Size>100</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Extend>true</Extend>
              <Order>2</Order>
              <Type>Primary</Type>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Active>true</Active>
              <Format>NTFS</Format>
              <Label>System Reserved</Label>
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <TypeID>0x27</TypeID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Active>true</Active>
              <Format>NTFS</Format>
              <Label>os</Label>
              <Letter>C</Letter>
              <Order>2</Order>
              <PartitionID>2</PartitionID>
            </ModifyPartition>
          </ModifyPartitions>
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>2</PartitionID>
          </InstallTo>
          <InstallToAvailablePartition>false</InstallToAvailablePartition>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>$(if ($acceptEula) { 'true' } else { 'false' })</AcceptEula>
        <FullName>$fullName</FullName>
        <Organization>$organization</Organization>
        <ProductKey>
          <Key>$productKey</Key>
        </ProductKey>
      </UserData>
    </component>
  </settings>
  <settings pass="offlineServicing">
    <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <EnableLUA>$(if ($enableLUA) { 'true' } else { 'false' })</EnableLUA>
    </component>
  </settings>
  <settings pass="generalize">
    <component name="Microsoft-Windows-Security-SPP" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SkipRearm>$skipRearm</SkipRearm>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>$inputLocale</InputLocale>
      <SystemLocale>$systemLocale</SystemLocale>
      <UILanguage>$uiLanguage</UILanguage>
      <UILanguageFallback>$uiLanguageFallback</UILanguageFallback>
      <UserLocale>$userLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <SkipAutoActivation>$(if ($skipAutoActivation) { 'true' } else { 'false' })</SkipAutoActivation>
    </component>
    <component name="Microsoft-Windows-SQMApi" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <CEIPEnabled>$ceipEnabled</CEIPEnabled>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ComputerName>$computerName</ComputerName>
      <ProductKey>$productKey</ProductKey>
      <TimeZone>$timeZone</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <AutoLogon>
        <Password>
          <Value>$administratorPassword</Value>
          <PlainText>true</PlainText>
        </Password>
        <Enabled>true</Enabled>
        <Username>Administrator</Username>
      </AutoLogon>
      <OOBE>
        <HideEULAPage>$(if ($hideEULAPage) { 'true' } else { 'false' })</HideEULAPage>
        <HideOEMRegistrationScreen>$(if ($hideOEMRegistrationScreen) { 'true' } else { 'false' })</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>$(if ($hideOnlineAccountScreens) { 'true' } else { 'false' })</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>$(if ($hideWirelessSetupInOOBE) { 'true' } else { 'false' })</HideWirelessSetupInOOBE>
        <NetworkLocation>$networkLocation</NetworkLocation>
        <SkipUserOOBE>$(if ($skipUserOOBE) { 'true' } else { 'false' })</SkipUserOOBE>
        <SkipMachineOOBE>$(if ($skipMachineOOBE) { 'true' } else { 'false' })</SkipMachineOOBE>
        <ProtectYourPC>$protectYourPC</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$administratorPassword</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <RegisteredOrganization>$registeredOrganization</RegisteredOrganization>
      <RegisteredOwner>$registeredOwner</RegisteredOwner>
      <DisableAutoDaylightTimeSet>$(if ($disableAutoDaylightTimeSet) { 'true' } else { 'false' })</DisableAutoDaylightTimeSet>
    </component>
  </settings>
</unattend>
"@
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    try {
      $unattend = $template.Clone();
      $order = 0;
      $flc = $unattend.CreateElement('FirstLogonCommands', $unattend.DocumentElement.NamespaceURI);
      foreach ($command in $commands) {
        $sc = $unattend.CreateElement('SynchronousCommand');
        $sc.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add');
        $scSubs = @(
          @{
            'name' = 'Order';
            'value' = ++$order
          },
          @{
            'name' = 'Description';
            'value' = $command['Description']
          },
          @{
            'name' = 'CommandLine';
            'value' = $command['CommandLine']
          },
          @{
            'name' = 'RequiresUserInput';
            'value' = 'false'
          }
        );
        foreach ($scSub in $scSubs) {
          $se = $unattend.CreateElement($scSub['name']);
          $se.AppendChild($unattend.CreateTextNode($scSub['value']));
          $sc.AppendChild($se);
        }
        $flc.AppendChild($sc);
      }
      $flcComponent = ($unattend.unattend.settings | Where-Object -Property 'pass' -eq -Value 'oobeSystem' | Select-Object -ExpandProperty 'component' | Where-Object -Property name -eq -Value 'Microsoft-Windows-Shell-Setup');
      $flcComponent.AppendChild($flc);
      $unattend.Save($destinationPath);
    } catch {
      Write-Log -message ('{0} :: exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.Message) -severity 'warn';
      if ($_.Exception.InnerException) {
        Write-Log -message ('{0} :: inner exception: {1}' -f $($MyInvocation.MyCommand.Name), $_.Exception.InnerException.Message) -severity 'warn';
      }
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function New-Password {
  <#
  .SYNOPSIS
    Creates a new random password
  .DESCRIPTION
  #>
  [CmdletBinding()]
  param (
    [int] $length = 12,
    [int] $nonAlphaChars = 3
  )
  begin {
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
  process {
    try {
      Add-Type -AssemblyName 'System.Web';
      return ([System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars));
    } catch {
      return (& openssl @('rand', '-base64', $length));
    }
  }
  end {
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace';
  }
}

function Convert-WindowsImage {
  <#
    Convert-WindowsImage was originally written by Microsoft staff.
    This version is adapted to handle use cases at Mozilla.

    .NOTES
        Use of this sample source code is subject to the terms of the Microsoft
        license agreement under which you licensed this sample source code. If
        you did not accept the terms of the license agreement, you are not
        authorized to use this sample source code. For the terms of the license,
        please see the license agreement between you and Microsoft or, if applicable,
        see the LICENSE.RTF on your install media or the root of your tools installation.
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS', WITH NO WARRANTIES.

    .SYNOPSIS
        Creates a bootable VHD(X) based on Windows 7 or Windows 8 installation media.

    .DESCRIPTION
        Creates a bootable VHD(X) based on Windows 7 or Windows 8 installation media.

    .PARAMETER SourcePath
        The complete path to the WIM or ISO file that will be converted to a Virtual Hard Disk.
        The ISO file must be valid Windows installation media to be recognized successfully.

    .PARAMETER CacheSource
        If the source WIM/ISO was copied locally, we delete it by default.
        Pass $true to cache the source image from the temp directory.

    .PARAMETER VHDPath
        The name and path of the Virtual Hard Disk to create.
        Omitting this parameter will create the Virtual Hard Disk is the current directory, (or,
        if specified by the -WorkingDirectory parameter, the working directory) and will automatically
        name the file in the following format:

        <build>.<revision>.<architecture>.<branch>.<timestamp>_<skufamily>_<sku>_<language>.<extension>
        i.e.:
        9200.0.amd64fre.winmain_win8rtm.120725-1247_client_professional_en-us.vhd(x)

    .PARAMETER WorkingDirectory
        Specifies the directory where the VHD(X) file should be generated.
        If specified along with -VHDPath, the -WorkingDirectory value is ignored.
        The default value is the current directory ($pwd).

    .PARAMETER TempDirectory
        Specifies the directory where the logs and ISO files should be placed.
        The default value is the temp directory ($env:Temp).

    .PARAMETER SizeBytes
        The size of the Virtual Hard Disk to create.
        For fixed disks, the VHD(X) file will be allocated all of this space immediately.
        For dynamic disks, this will be the maximum size that the VHD(X) can grow to.
        The default value is 40GB.

    .PARAMETER VhdFormat
        Specifies whether to create a VHD or VHDX formatted Virtual Hard Disk.
        The default is AUTO, which will create a VHD if using the BIOS disk layout or
        VHDX if using UEFI or WindowsToGo layouts.

    .PARAMETER DiskLayout
        Specifies whether to build the image for BIOS (MBR), UEFI (GPT), or WindowsToGo (MBR).
        Generation 1 VMs require BIOS (MBR) images.  Generation 2 VMs require UEFI (GPT) images.
        Windows To Go images will boot in UEFI or BIOS but are not technically supported (upgrade
        doesn't work)

    .PARAMETER UnattendPath
        The complete path to an unattend.xml file that can be injected into the VHD(X).

    .PARAMETER Edition
        The name or image index of the image to apply from the WIM.

    .PARAMETER Passthru
        Specifies that the full path to the VHD(X) that is created should be
        returned on the pipeline.

    .PARAMETER BCDBoot
        By default, the version of BCDBOOT.EXE that is present in \Windows\System32
        is used by Convert-WindowsImage.  If you need to specify an alternate version,
        use this parameter to do so.

    .PARAMETER MergeFolder
        Specifies additional MergeFolder path to be added to the root of the VHD(X)

    .PARAMETER BCDinVHD
        Specifies the purpose of the VHD(x). Use NativeBoot to skip cration of BCD store
        inside the VHD(x). Use VirtualMachine (or do not specify this option) to ensure
        the BCD store is created inside the VHD(x).

    .PARAMETER Driver
        Full path to driver(s) (.inf files) to inject to the OS inside the VHD(x).

    .PARAMETER ExpandOnNativeBoot
        Specifies whether to expand the VHD(x) to its maximum suze upon native boot.
        The default is True. Set to False to disable expansion.

    .PARAMETER RemoteDesktopEnable
        Enable Remote Desktop to connect to the OS inside the VHD(x) upon provisioning.
        Does not include Windows Firewall rules (firewall exceptions). The default is False.

    .PARAMETER DisableWindowsService
        List of Windows Services to disable.
        The default is an empty list.

    .PARAMETER DisableNotificationCenter
        Disable Windows Notification Center in the default user registry hive.
        The default is False.

    .PARAMETER Feature
        Enables specified Windows Feature(s). Note that you need to specify the Internal names
        understood by DISM and DISM CMDLets (e.g. NetFx3) instead of the "Friendly" names
        from Server Manager CMDLets (e.g. NET-Framework-Core).

    .PARAMETER Package
        Injects specified Windows Package(s). Accepts path to either a directory or individual
        CAB or MSU file.

    .PARAMETER ShowUI
        Specifies that the Graphical User Interface should be displayed.

    .PARAMETER EnableDebugger
        Configures kernel debugging for the VHD(X) being created.
        EnableDebugger takes a single argument which specifies the debugging transport to use.
        Valid transports are: None, Serial, 1394, USB, Network, Local.

        Depending on the type of transport selected, additional configuration parameters will become
        available.

        Serial:
            -ComPort   - The COM port number to use while communicating with the debugger.
                         The default value is 1 (indicating COM1).
            -BaudRate  - The baud rate (in bps) to use while communicating with the debugger.
                         The default value is 115200, valid values are:
                         9600, 19200, 38400, 56700, 115200

        1394:
            -Channel   - The 1394 channel used to communicate with the debugger.
                         The default value is 10.

        USB:
            -Target    - The target name used for USB debugging.
                         The default value is "debugging".

        Network:
            -IPAddress - The IP address of the debugging host computer.
            -Port      - The port on which to connect to the debugging host.
                         The default value is 50000, with a minimum value of 49152.
            -Key       - The key used to encrypt the connection.  Only [0-9] and [a-z] are allowed.
            -nodhcp    - Prevents the use of DHCP to obtain the target IP address.
            -newkey    - Specifies that a new encryption key should be generated for the connection.

    .PARAMETER DismPath
        Full Path to an alternative version of the Dism.exe tool. The default is the current OS version.

    .PARAMETER ApplyEA
        Specifies that any EAs captured in the WIM should be applied to the VHD.
        The default is False.

    .EXAMPLE
        .\Convert-WindowsImage.ps1 -SourcePath D:\foo\install.wim -Edition Professional -WorkingDirectory D:\foo

        This command will create a 40GB dynamically expanding VHD in the D:\foo folder.
        The VHD will be based on the Professional edition from D:\foo\install.wim,
        and will be named automatically.

    .EXAMPLE
        .\Convert-WindowsImage.ps1 -SourcePath D:\foo\Win7SP1.iso -Edition Ultimate -VHDPath D:\foo\Win7_Ultimate_SP1.vhd

        This command will parse the ISO file D:\foo\Win7SP1.iso and try to locate
        \sources\install.wim.  If that file is found, it will be used to create a
        dynamically-expanding 40GB VHD containing the Ultimate SKU, and will be
        named D:\foo\Win7_Ultimate_SP1.vhd

    .EXAMPLE
        .\Convert-WindowsImage.ps1 -SourcePath D:\foo\install.wim -Edition Professional -EnableDebugger Serial -ComPort 2 -BaudRate 38400

        This command will create a VHD from D:\foo\install.wim of the Professional SKU.
        Serial debugging will be enabled in the VHD via COM2 at a baud rate of 38400bps.

    .OUTPUTS
        System.IO.FileInfo
  #>
  [CmdletBinding(DefaultParameterSetName = 'DiskLayout', HelpURI = 'https://github.com/Microsoft/Virtualization-Documentation/tree/master/hyperv-tools/Convert-WindowsImage')]
  param(
    [Parameter(ParameterSetName  = 'DiskLayout', Mandatory = $true, ValueFromPipeline = $true)]
    [Parameter(ParameterSetName = 'PartitionStyle', Mandatory = $true, ValueFromPipeline = $true)]
    [Alias('WIM')]
    [ValidateNotNullOrEmpty()]
    # This helps to work around the issue when PowerShell does not immediately recognize newly mounted drives
    [ValidateScript({ $Drive = Get-PSDrive; Test-Path -Path ( Resolve-Path -Path $PSItem ).Path })]
    [string] $SourcePath,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [switch] $CacheSource = $false,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('SKU')]
    [ValidateNotNullOrEmpty()]
    [string[]] $Edition = 1,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('WorkDir')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $PSItem })]
    [string] $WorkingDirectory = $pwd,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('TempDir')]
    [ValidateNotNullOrEmpty()]
    [string] $TempDirectory = $env:Temp,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('VHD')]
    [ValidateNotNullOrEmpty()]
    [string] $VhdPath,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('Size')]
    [ValidateNotNullOrEmpty()]
    [ValidateRange( 512MB, 64TB )]
    [UInt64] $SizeBytes = 25GB,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('Format')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('VHD', 'VHDX', 'AUTO')]
    [string] $VhdFormat = 'AUTO',

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('DiskType')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Dynamic', 'Fixed')]
    [string] $VhdType = 'Dynamic',

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('MergeFolder')]
    [ValidateNotNullOrEmpty()]
    [string] $MergeFolderPath = '',

    [Parameter(ParameterSetName = 'DiskLayout', Mandatory = $true )]
    [Alias('Layout')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('BIOS', 'UEFI', 'WindowsToGo')]
    [string] $DiskLayout,

    [Parameter(ParameterSetName = 'PartitionStyle', Mandatory = $true )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MBR', 'GPT', 'MBRforWindowsToGo')]
    [string] $VhdPartitionStyle,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('NativeBoot', 'VirtualMachine')]
    [string] $BcdInVhd = 'VirtualMachine',

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Parameter(ParameterSetName = 'UI')]
    [string] $BcdBoot = 'bcdboot.exe',

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Parameter(ParameterSetName = 'UI')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('None', 'Serial', '1394', 'USB', 'Local', 'Network')]
    [string] $EnableDebugger = 'None',

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [ValidateNotNullOrEmpty()]
    [string[]] $Feature,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path ( Resolve-Path -Path $PSItem ).Path })]
    [string[]] $Driver,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path ( Resolve-Path -Path $PSItem ).Path } )]
    [string[]] $Package,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [switch] $ExpandOnNativeBoot = $true,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [switch] $RemoteDesktopEnable = $false,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [string[]] $DisableWindowsService = @(),

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [switch] $DisableNotificationCenter = $false,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Alias('Unattend')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path ( Resolve-Path -Path $PSItem ).Path })]
    [string] $UnattendPath,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [Parameter(ParameterSetName = 'UI')]
    [switch] $Passthru,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path ( Resolve-Path -Path $PSItem ).Path })]
    [string] $DismPath,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [switch] $ApplyEA = $false,

    [Parameter(ParameterSetName = 'UI')]
    [switch] $ShowUI,

    [Parameter(ParameterSetName = 'DiskLayout')]
    [Parameter(ParameterSetName = 'PartitionStyle')]
    [ValidateNotNullOrEmpty()]
    [System.Globalization.CultureInfo] $BcdLocale
  )
  # Create the parameters for the various types of debugging.
  dynamicParam {
    # Set up the dynamic parameters.
    # Dynamic parameters are only available if certain conditions are met, so they'll only show up
    # as valid parameters when those conditions apply.  Here, the conditions are based on the value of
    # the EnableDebugger parameter.  Depending on which of a set of values is the specified argument
    # for EnableDebugger, different parameters will light up, as outlined below.

    $parameterDictionary = New-Object -TypeName 'System.Management.Automation.RuntimeDefinedParameterDictionary'
    if (Test-Path -Path 'Variable:\EnableDebugger') {
      switch ($EnableDebugger) {
        'Serial' {
          #region ComPort

          $ComPortAttr                   = New-Object System.Management.Automation.ParameterAttribute
          $ComPortAttr.ParameterSetName  = '__AllParameterSets'
          $ComPortAttr.Mandatory         = $false

          $ComPortValidator              = New-Object System.Management.Automation.ValidateRangeAttribute(1, 10)

          $ComPortNotNull                = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $ComPortAttrCollection         = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $ComPortAttrCollection.Add($ComPortAttr)
          $ComPortAttrCollection.Add($ComPortValidator)
          $ComPortAttrCollection.Add($ComPortNotNull)

          $ComPort                       = New-Object System.Management.Automation.RuntimeDefinedParameter('ComPort', [UInt16], $ComPortAttrCollection)

          # By default, use COM1
          $ComPort.Value                 = 1
          $parameterDictionary.Add('ComPort', $ComPort)
          #endregion ComPort

          #region BaudRate
          $BaudRateAttr                  = New-Object System.Management.Automation.ParameterAttribute
          $BaudRateAttr.ParameterSetName = '__AllParameterSets'
          $BaudRateAttr.Mandatory        = $false

          $BaudRateValidator             = New-Object System.Management.Automation.ValidateSetAttribute(9600, 19200,38400, 57600, 115200)

          $BaudRateNotNull               = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $BaudRateAttrCollection        = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $BaudRateAttrCollection.Add($BaudRateAttr)
          $BaudRateAttrCollection.Add($BaudRateValidator)
          $BaudRateAttrCollection.Add($BaudRateNotNull)

          $BaudRate                      = New-Object System.Management.Automation.RuntimeDefinedParameter('BaudRate', [UInt32], $BaudRateAttrCollection)

          # By default, use 115,200.
          $BaudRate.Value                = 115200
          $parameterDictionary.Add('BaudRate', $BaudRate)
          #endregion BaudRate

          break
        }
        '1394' {
          $ChannelAttr                   = New-Object System.Management.Automation.ParameterAttribute
          $ChannelAttr.ParameterSetName  = '__AllParameterSets'
          $ChannelAttr.Mandatory         = $false

          $ChannelValidator              = New-Object System.Management.Automation.ValidateRangeAttribute(0, 62)

          $ChannelNotNull                = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $ChannelAttrCollection         = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $ChannelAttrCollection.Add($ChannelAttr)
          $ChannelAttrCollection.Add($ChannelValidator)
          $ChannelAttrCollection.Add($ChannelNotNull)

          $Channel                       = New-Object System.Management.Automation.RuntimeDefinedParameter('Channel', [UInt16], $ChannelAttrCollection)

          # By default, use channel 10
          $Channel.Value                 = 10
          $parameterDictionary.Add('Channel', $Channel)
          break
        }

        'USB' {
          $TargetAttr                    = New-Object System.Management.Automation.ParameterAttribute
          $TargetAttr.ParameterSetName   = '__AllParameterSets'
          $TargetAttr.Mandatory          = $false

          $TargetNotNull                 = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $TargetAttrCollection          = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $TargetAttrCollection.Add($TargetAttr)
          $TargetAttrCollection.Add($TargetNotNull)

          $Target                        = New-Object System.Management.Automation.RuntimeDefinedParameter('Target', [string], $TargetAttrCollection)

          # By default, use target = "debugging"
          $Target.Value                  = 'Debugging'
          $parameterDictionary.Add('Target', $Target)
          break
        }

        'Network' {
          #region IP
          $IpAttr                        = New-Object System.Management.Automation.ParameterAttribute
          $IpAttr.ParameterSetName       = '__AllParameterSets'
          $IpAttr.Mandatory              = $true

          $IpValidator                   = New-Object System.Management.Automation.ValidatePatternAttribute('\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b')
          $IpNotNull                     = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $IpAttrCollection              = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $IpAttrCollection.Add($IpAttr)
          $IpAttrCollection.Add($IpValidator)
          $IpAttrCollection.Add($IpNotNull)

          $IP                            = New-Object System.Management.Automation.RuntimeDefinedParameter('IPAddress', [string], $IpAttrCollection)

          # There's no good way to set a default value for this.
          $parameterDictionary.Add('IPAddress', $IP)
          #endregion IP

          #region Port
          $PortAttr                      = New-Object System.Management.Automation.ParameterAttribute
          $PortAttr.ParameterSetName     = '__AllParameterSets'
          $PortAttr.Mandatory            = $false

          $PortValidator                 = New-Object System.Management.Automation.ValidateRangeAttribute(49152, 50039)

          $PortNotNull                   = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $PortAttrCollection            = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $PortAttrCollection.Add($PortAttr)
          $PortAttrCollection.Add($PortValidator)
          $PortAttrCollection.Add($PortNotNull)


          $Port                          = New-Object System.Management.Automation.RuntimeDefinedParameter('Port', [UInt16], $PortAttrCollection)

          # By default, use port 50000
          $Port.Value                    = 50000
          $parameterDictionary.Add('Port', $Port)
          #endregion Port

          #region Key
          $KeyAttr                       = New-Object System.Management.Automation.ParameterAttribute
          $KeyAttr.ParameterSetName      = '__AllParameterSets'
          $KeyAttr.Mandatory             = $true

          $KeyValidator                  = New-Object System.Management.Automation.ValidatePatternAttribute('\b([A-Z0-9]+).([A-Z0-9]+).([A-Z0-9]+).([A-Z0-9]+)\b')

          $KeyNotNull                    = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute

          $KeyAttrCollection             = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $KeyAttrCollection.Add($KeyAttr)
          $KeyAttrCollection.Add($KeyValidator)
          $KeyAttrCollection.Add($KeyNotNull)

          $Key                           = New-Object System.Management.Automation.RuntimeDefinedParameter('Key', [string], $KeyAttrCollection)

          # Don't set a default key.
          $parameterDictionary.Add('Key', $Key)
          #endregion Key

          #region NoDHCP
          $NoDHCPAttr                    = New-Object System.Management.Automation.ParameterAttribute
          $NoDHCPAttr.ParameterSetName   = '__AllParameterSets'
          $NoDHCPAttr.Mandatory          = $false

          $NoDHCPAttrCollection          = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $NoDHCPAttrCollection.Add($NoDHCPAttr)

          $NoDHCP                        = New-Object System.Management.Automation.RuntimeDefinedParameter('NoDHCP', [switch], $NoDHCPAttrCollection)

          $parameterDictionary.Add('NoDHCP', $NoDHCP)
          #endregion NoDHCP

          #region NewKey
          $NewKeyAttr                    = New-Object System.Management.Automation.ParameterAttribute
          $NewKeyAttr.ParameterSetName   = '__AllParameterSets'
          $NewKeyAttr.Mandatory          = $false

          $NewKeyAttrCollection          = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
          $NewKeyAttrCollection.Add($NewKeyAttr)

          $NewKey                        = New-Object System.Management.Automation.RuntimeDefinedParameter('NewKey', [switch], $NewKeyAttrCollection)

          # Don't set a default key.
          $parameterDictionary.Add('NewKey', $NewKey)
          #endregion NewKey

          break
        }

        # There's nothing to do for local debugging.
        # Synthetic debugging is not yet implemented.

        default {
          break
        }
      }
    }
    return $parameterDictionary
  }
  begin {
    Set-StrictMode -version 3
    $Module = Import-ModuleEx -Name 'Dism'
    $Module = Import-ModuleEx -Name 'Storage'

    #region Constants and Pseudo-Constants
        
    # Name of the script, obviously.
    $scriptName             = 'Convert-WindowsImage'

    # Session key, used for keeping records unique between multiple runs.
    $sessionKey             = [Guid]::NewGuid().ToString()

    # Log folder path.
    $logFolder              = [io.path]::Combine( $TempDirectory, $scriptName, $sessionKey )

    # Maximum size for VHD is ~2040GB.
    $vhdMaxSize             = 2040GB

    # Maximum size for VHDX is ~64TB.
    $vhdxMaxSize            = 64TB

    # The lowest supported *image* version; making sure we don't run against Vista/2k8.
    $lowestSupportedVersion = New-Object -TypeName 'Version' -ArgumentList '6.1'

    # Keeps track on whether the script itself enabled Transcript
    # (vs. it was enabled by user)
    $Transcripting          = $false

    # Since we use the VhdFormat in output, make it uppercase.
    # We'll make it lowercase again when we use it as a file extension.
    $VhdFormat              = $VhdFormat.ToUpper()

    if (Test-Path -Path 'Variable:\VhdPartitionStyle') {
      switch ($VhdPartitionStyle) {
        'MBR' {
          $DiskLayout = 'Bios'
        }
        'GPT' {
          $DiskLayout = 'Uefi'
        }
        'MBRforWindowsToGo' {
          $DiskLayout = 'WindowsToGo'
        }
      }
    }
    if (Get-Command -Name 'Get-WindowsOptionalFeature' -ErrorAction 'SilentlyContinue') {
      try {
        $hyperVEnabled  =
          [bool]( Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Services" -Verbose:$false ).State -and
          [bool]( Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-PowerShell" -Verbose:$false ).State
      }
      catch {
        # WinPE DISM does not support online queries.  This will throw on non-WinPE machines
        $winpeVersion = (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinPE').Version
        Write-Verbose -Message "Running WinPE version $winpeVersion"
        $hyperVEnabled = $false
      }
    } else {
      $hyperVEnabled = $false
    }
    #endregion Constants and Pseudo-Constants

    #region Here Strings
    # Banner text displayed during each run.
    $Header    = @"
Windows(R) Image to Virtual Hard Disk Converter for Windows(R)
Copyright (C) Microsoft Corporation.  All rights reserved.

"@
    # Text used as the banner in the UI.
    $UiHeader  = @"
You can use the fields below to configure the VHD or VHDX that you want to create!
"@
    #endregion Here Strings
  }
  process {
    $disk           = $null
    $openWim        = $null
    $openIso        = $null
    $openImage      = $null
    $vhdFinalName   = $null
    $vhdFinalPath   = $null
    $mountedHive    = $null
    $IsoPath        = $null
    $tempSource     = $null
    $vhd            = @()
    Write-Information -MessageData $header
    try {
      #region Prepare variables

      # Create log folder
      if (Test-Path -Path $logFolder) {
        $Item = Remove-Item -Path $logFolder -Force -Recurse
      }
      $Item = New-Item -Path $logFolder -ItemType "Directory" -Force

      # try to start transcripting.  If it's already running, we'll get an exception and swallow it.
      try {
        $TranscriptPath = Join-Path -Path $logFolder -ChildPath "Convert-WindowsImageTranscript.txt"
        $Transcript     = Start-Transcript -Path $TranscriptPath -Force -ErrorAction "SilentlyContinue"
        $Transcripting  = $true
      } catch {
        Write-Warning -Message "Transcription is already running.  No Convert-WindowsImage-specific transcript will be created."
        $Transcripting  = $false
      }

      # Add types
      Add-WindowsImageTypes

      # Check to make sure we're running as Admin.
      if (-not ( Test-Admin )) {
        throw "Images can only be applied by an administrator.  Please launch PowerShell elevated and run this script again."
      }

      if (Get-WindowsBuildNumber -lt 9200) {
        Write-Warning -Message "This Windows build is unsupported."
        #throw "$scriptName requires Windows 8 Consumer Preview or higher.  Please use WIM2VHD.WSF (http://code.msdn.microsoft.com/wim2vhd) if you need to create VHDs from Windows 7."
      }

      # Resolve the path for the unattend file.
      if (-not [string]::IsNullOrEmpty( $UnattendPath )) {
        $UnattendPath = ( Resolve-Path -Path $UnattendPath ).Path
      }

      if ($VhdFormat -ilike 'AUTO') {
        if ($DiskLayout -eq 'Bios') {
          $VhdFormat = 'VHD'
        } else {
          $VhdFormat = 'VHDX'
        }
      }

      # Choose smallest supported block size for dynamic VHD(X)
      $BlockSizeBytes = 1MB

      # There's a difference between the maximum sizes for VHDs and VHDXs.  Make sure we follow it.
      if ('VHD' -ilike $VhdFormat) {
        if ($SizeBytes -gt $vhdMaxSize) {
          Write-Warning -Message "For the VHD file format, the maximum file size is ~2040GB.  We're automatically setting the size to 2040GB for you."
          $SizeBytes = 2040GB
        }
        $BlockSizeBytes = 512KB
      }

      # Check if -VHDPath and -WorkingDirectory were both specified.
      if (-not [String]::IsNullOrEmpty( $VhdPath ) -and
          -not [String]::IsNullOrEmpty( $WorkingDirectory )) {
        if ($WorkingDirectory -ne $pwd) {
          # If the WorkingDirectory is anything besides $pwd, tell people that the WorkingDirectory is being ignored.
          Write-Warning -Message "Specifying -VHDPath and -WorkingDirectory at the same time is contradictory."
          Write-Warning -Message "Ignoring the WorkingDirectory specification."
          $WorkingDirectory = Split-Path $VhdPath -Parent
        }
      }
      if ($VhdPath) {
        # Check to see if there's a conflict between the specified file extension and the VhdFormat being used.
        $Ext = ( [IO.FileInfo]$VhdPath ).Extension
        if (-not ( $Ext -ilike ".$( $VhdFormat )" )) {
          throw "There is a mismatch between the VHDPath file extension ($($ext.ToUpper())), and the VhdFormat (.$($VhdFormat)).  Please ensure that these match and try again."
        }
      }

      # Create a temporary name for the VHD(x).  We'll name it properly at the end of the script.
      if ([String]::IsNullOrEmpty( $VhdPath )) {
        $vhdNameTemp  = [string]( $sessionKey + "." + $VhdFormat.ToLower() )
        $VhdPath      = Join-Path -Path $WorkingDirectory -ChildPath $vhdNameTemp
      } else {
        # Since we can't do Resolve-Path against a file that doesn't exist, we need to get creative in determining
        # the full path that the user specified (or meant to specify if they gave us a relative path).
        # Check to see if the path has a root specified.  If it doesn't, use the working directory.
        if (-not [IO.Path]::IsPathRooted( $VhdPath )) {
          $VhdPath  = Join-Path -Path $WorkingDirectory -ChildPath $VhdPath
        }

        $vhdFinalName = Split-Path -Path $VhdPath -Leaf
        $VhdPath      = Split-Path -Path $VhdPath -Parent
        $vhdNameTemp  = [string]( $sessionKey + "." + $VhdFormat.ToLower() )
        $VhdPath      = Join-Path  -Path $VhdPath -ChildPath $vhdNameTemp
      }
      Write-Debug -Message "  Temporary $VhdFormat path is: `"$VhdPath`""
      #endregion Prepare variables

      #region Mount source images

      # If we're using an ISO, mount it and get the path to the WIM file.
      if (( [IO.FileInfo]$SourcePath ).Extension -ilike '.ISO') {
        # If the ISO isn't local, copy it down so we don't have to worry about resource contention
        # or about network latency.
        if (Test-IsNetworkLocation -Path $SourcePath) {
          $IsoFileName = Split-Path -Path $SourcePath -Leaf
          Write-Verbose -Message "Copying ISO `"$IsoFileName`" to temp folder..."
          # Robocopy.exe $(Split-Path $SourcePath -Parent) $TempDirectory $(Split-Path $SourcePath -Leaf) | Out-Null
          $Item = Copy-Item -Path $SourcePath -Destination $TempDirectory -PassThru
          $SourcePath = Join-Path -Path $TempDirectory -ChildPath $IsoFileName
          $tempSource = $SourcePath
        }

        $IsoPath     = ( Resolve-Path $SourcePath ).Path
        $IsoFileName = Split-Path $IsoPath -Leaf

        Write-Verbose -Message "Opening ISO `"$IsoFileName`"..."
        $openIso     = Mount-DiskImage -ImagePath $IsoPath -StorageType "ISO" -PassThru

        # Refresh the DiskImage object so we can get the real information about it.  I assume this is a bug.
        $openIso     = Get-DiskImage -ImagePath $IsoPath
        $driveLetter = ( Get-Volume -DiskImage $openIso ).DriveLetter
        $SourcePath  = "$($driveLetter):\sources\install.wim"

        # Check to see if there's a WIM file we can muck about with.
        Write-Verbose -Message "Looking for `"$SourcePath`"..."

        if (-not ( Test-Path -Path $SourcePath )) {
          throw "The specified ISO does not appear to be valid Windows installation media."
        }
      }

      # Check to see if the WIM is local, or on a network location.  If the latter, copy it locally.
      if (Test-IsNetworkLocation -Path $SourcePath) {
        $WimFileName = Split-Path -Path $SourcePath -Leaf
        Write-Verbose -Message "Copying WIM $WimFileName to temp folder..."
        # robocopy $(Split-Path $SourcePath -Parent) $TempDirectory $(Split-Path $SourcePath -Leaf) | Out-Null
        $Item = Copy-Item -Path $SourcePath -Destination $TempDirectory -PassThru
        $SourcePath = Join-Path -Path $TempDirectory -ChildPath $WimFileName
        $tempSource = $SourcePath
      }
      $SourcePath  = ( Resolve-Path $SourcePath ).Path

      # QUERY WIM INFORMATION AND EXTRACT THE INDEX OF TARGETED IMAGE
      Write-Verbose -Message "Looking for the requested Windows image in the WIM file"
      $WindowsImage = Get-WindowsImage -ImagePath $SourcePath -Verbose:$false

      # We're good.  Open the WIM container.

      # NOTE: this is only required because we want to get the XML-based meta-data at the end.  Is there a better way?
      # If we can get this information from DISM cmdlets, we can remove the openWim constructs
      $openWim   = New-Object -TypeName "WIM2VHD.WimFile" -ArgumentList $SourcePath

      #endregion Mount source images

      $Edition | ForEach-Object -Process {

        #region Select Image
        $Edition = $PSItem

        # WIM may have multiple images.  Filter on Edition (can be index or name) and try to find a unique image

        Write-Verbose -Message ( [string]::Empty )

        $EditionIndex = 0;

        if ([Int32]::tryParse( $Edition, [ref]$EditionIndex )) {
          $WindowsImage = Get-WindowsImage -ImagePath $SourcePath -Index $EditionIndex -Verbose:$false
        } else {
          $WindowsImage = Get-WindowsImage -ImagePath $SourcePath -Verbose:$false | Where-Object { $PSItem.ImageName -ilike "*$($Edition)" }
        }

        if (-not $WindowsImage) {
          throw "Requested windows Image was not found on the WIM file!"
        }

        if ($WindowsImage -is [System.Array]) {
          $ImageCount = $($WindowsImage.Count)

          Write-Verbose -Message "WIM file has the following $ImageCount images that match filter *$Edition"
          Get-WindowsImage -ImagePath $SourcePath -Verbose:$false

          Write-Error -Message "You must specify an Edition or SKU index, since the WIM has more than one image."
          throw "There are more than one images that match ImageName filter *$Edition"
        }

        $ImageIndex = $WindowsImage[0].ImageIndex

        $openImage = $openWim[[Int32]$ImageIndex]

        if ($null -eq $openImage) {
          Write-Error -Message "The specified edition does not appear to exist in the specified WIM."
          Write-Error -Message "Valid edition names are:"

          $openWim.Images | ForEach-Object -Process { Write-Error -Message "$PSItem.ImageFlags" }
          throw
        }

        $OpenImageIndex   = $openImage.ImageIndex
        $OpenImageFlags   = $openImage.ImageFlags
        $OpenImageVersion = $openImage.ImageVersion

        Write-Verbose -Message "Image $OpenImageIndex selected: `"$OpenImageFlags`"..."

        # Check to make sure that the image we're applying is Windows 7 or greater.
        if ($OpenImageVersion -lt $lowestSupportedVersion) {
          if ($OpenImageVersion -eq '0.0.0.0') {
            Write-Warning -Message "The specified WIM does not encode the Windows version."
          } else {
            throw "Convert-WindowsImage only supports Windows 7 and Windows 8 WIM files.  The specified image (version $OpenImageVersion) does not appear to contain one of those operating systems."
          }
        }
        #endregion Select Image

        #region Create and partition VHD
        if ($hyperVEnabled) {
          Write-Verbose -Message "Creating sparse disk..."
          $NewVhdParam = @{
            Path           = $VhdPath
            SizeBytes      = $SizeBytes
            BlockSizeBytes = $BlockSizeBytes
          }

          switch ($VhdType) {
            'Dynamic' {
              $NewVhdParam.Add('Dynamic', $true)
            }
            'Fixed' {}
          }
          $newVhd = New-Vhd @NewVhdParam

          Write-Verbose -Message "Mounting $VhdFormat..."
          $disk = $newVhd | Mount-VHD -PassThru | Get-Disk
        } else {
          <#
            Create the VHD using the VirtDisk Win32 API. So, why not use the New-VHD cmdlet here?
            New-VHD depends on the Hyper-V Cmdlets, which aren't installed by default.
            Installing those cmdlets isn't a big deal, but they depend on the Hyper-V WMI
            APIs, which in turn depend on Hyper-V.  In order to prevent Convert-WindowsImage
            from being dependent on Hyper-V (and thus, x64 systems only), we're using the
            VirtDisk APIs directly.
          #>
          switch ($VhdType) {
            'Dynamic' {
              Write-Verbose -Message "Creating sparse disk..."
              [WIM2VHD.VirtualHardDisk]::CreateSparseDisk($VhdFormat, $VhdPath, $SizeBytes, $true)
            }
            'Fixed' {
              Write-Verbose -Message "Creating fixed disk..."
              [WIM2VHD.VirtualHardDisk]::CreateFixedDisk($VhdFormat, $VhdPath, $SizeBytes, $true)
            }
          }
          # Attach the VHD.
          Write-Verbose -Message "Attaching $VhdFormat..."
          $disk = Mount-DiskImage -ImagePath $VhdPath -PassThru | Get-DiskImage | Get-Disk
        }

        switch ($DiskLayout) {
          'BIOS' {
            Write-Verbose -Message "Initializing disk..."
            Initialize-Disk -Number $disk.Number -PartitionStyle MBR

            # Create the Windows/system partition
            Write-Verbose -Message "Creating single partition..."

            $systemPartition  = New-Partition -DiskNumber $disk.Number -UseMaximumSize -MbrType IFS -IsActive
            $windowsPartition = $systemPartition

            Write-Verbose -Message "Formatting windows volume..."

            $systemVolume  = Format-Volume -Partition $systemPartition -FileSystem NTFS -Force -Confirm:$false
            $windowsVolume = $systemVolume
          }

          'UEFI' {
            Write-Verbose -Message "Initializing disk..."
            Initialize-Disk -Number $disk.Number -PartitionStyle GPT

            if ($BcdInVhd -eq 'VirtualMachine') {
              if (( Get-WindowsBuildNumber ) -ge 10240) {
                # Create the system partition.  Create a data partition so we can format it, then change to ESP
                # Size should be at least 260 MB to accomodate for Native 4K drives.
                Write-Verbose -Message "Creating EFI System partition (ESP)..."
                $systemPartition = New-Partition -DiskNumber $disk.Number -Size 260MB -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'

                Write-Verbose -Message "  Formatting System volume..."
                $systemVolume = Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false

                Write-Verbose -Message "  Setting partition type to ESP..."
                $systemPartition | Set-Partition -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
                $systemPartition | Add-PartitionAccessPath -AssignDriveLetter
              } else {
                # Create the system partition
                Write-Verbose -Message "Creating EFI system partition (ESP)..."
                $systemPartition = New-Partition -DiskNumber $disk.Number -Size 260MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -AssignDriveLetter

                Write-Verbose -Message "  Formatting ESP..."
                $formatArgs = @(
                  "$($systemPartition.DriveLetter):", # Partition drive letter
                  '/FS:FAT32',                        # File system
                  '/Q',                               # Quick format
                  '/Y'                                # Suppress prompt
                )
                Start-Executable -Executable format -Arguments $formatArgs
              }
            } else {
              Write-Verbose -Message "The disk is intended for Native Boot. There will be no EFI System partition (ESP)."
            }

            # Create the Windows partition
            Write-Verbose -Message "Creating Boot (`"Windows`') partition..."
            $windowsPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'

            Write-Verbose -Message "  Formatting Boot (`"Windows`') volume..."
            $windowsVolume = Format-Volume -Partition $windowsPartition -FileSystem NTFS -Force -Confirm:$false
          }

          'WindowsToGo' {
            Write-Verbose -Message "Initializing disk..."
            Initialize-Disk -Number $disk.Number -PartitionStyle MBR

            # Create the system partition
            Write-Verbose -Message "Creating system partition..."
            $systemPartition = New-Partition -DiskNumber $disk.Number -Size 260MB -MbrType FAT32 -IsActive

            Write-Verbose -Message "  Formatting system volume..."
            $systemVolume    = Format-Volume -Partition $systemPartition -FileSystem FAT32 -Force -Confirm:$false

            # Create the Windows partition
            Write-Verbose -Message "Creating windows partition..."
            $windowsPartition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -MbrType IFS

            Write-Verbose -Message "  Formatting windows volume..."
            $windowsVolume    = Format-Volume -Partition $windowsPartition -FileSystem NTFS -Force -Confirm:$false
          }
        }

        if (( $DiskLayout -eq 'UEFI' -and $BcdInVhd -eq 'VirtualMachine' ) -or
          $DiskLayout -eq 'WindowsToGo' -or
          $DiskLayout -eq 'BIOS') {
          # Retreive access path for System partition.
          $systemPartition = Get-Partition -UniqueId $systemPartition.UniqueId
          $systemDrive = $systemPartition.AccessPaths[0].trimend('\').replace('\?', '??')
          Write-Verbose -Message "System volume path: `"$systemDrive`""
        }

        # Assign drive letter to Boot partition.  This is required for bcdboot
        $attempts = 1
        $assigned = $false

        do {
          $windowsPartition | Add-PartitionAccessPath -AssignDriveLetter
          $windowsPartition = $windowsPartition | Get-Partition

          if ($windowsPartition.DriveLetter -ne 0) {
            $assigned = $true
          } else {
            # sleep for up to 10 seconds and retry
            Get-Random -Minimum 1 -Maximum 10 | Start-Sleep
            $attempts++
          }
        } While ($attempts -le 100 -and -not $assigned)

        if (-not $assigned) {
          throw "Unable to get Partition after retry"
        }

        $windowsDrive = ( Get-Partition -Volume $windowsVolume ).AccessPaths[0].substring(0,2)

        # This is to workaround "No such drive exists" error in PowerShell
        $Drive = Get-psDrive

        $windowsDrive = ( Resolve-Path -Path $windowsDrive ).Path

        Write-Verbose -Message "Boot volume path: `"$windowsDrive`". (Took $attempts attempt(s) to assign.)"
        #endregion Create and partition VHD

        #region APPLY IMAGE FROM WIM TO THE NEW VHD
        Write-Verbose -Message "Applying image to $VhdFormat. This could take a while..."
        if (( Get-Command -Name "Expand-WindowsImage" -ErrorAction "SilentlyContinue" ) -and
          ( -not $ApplyEA -and [string]::IsNullOrEmpty( $DismPath ) )) {
          Expand-WindowsImage -ApplyPath $windowsDrive -ImagePath $SourcePath -Index $ImageIndex -LogPath "$($logFolder)\DismLogs.log" -Verbose:$false | Out-Null
        } else {
          if ([string]::IsNullOrEmpty( $DismPath )) {
            $DismPath = Join-Path -Path $env:windir -ChildPath "system32\dism.exe"
          }

          $applyImage = "/Apply-Image"

          if ($ApplyEA) {
            $applyImage = $applyImage + " /EA"
          }

          $dismArgs = @('$applyImage /ImageFile:`"$SourcePath`" /Index:$ImageIndex /ApplyDir:$windowsDrive /LogPath:`"$($logFolder)\DismLogs.log`"')

          Write-Verbose -Message "Applying image: $dismPath $dismArgs"

          $process = Start-Process -Passthru -Wait -NoNewWindow -FilePath $dismPath -ArgumentList $dismArgs

          if ($process.ExitCode -ne 0) {
            throw "Image Apply failed! See DismImageApply logs for details"
          }
        }
        Write-Verbose -Message "Image was applied successfully. "

        # Here we copy in the unattend file (if specified by the command line)
        if (-not [string]::IsNullOrEmpty( $UnattendPath )) {
          Write-Verbose -Message "Applying unattend file ($(Split-Path $UnattendPath -Leaf))..."
          $UnattendDestination = Join-Path -Path $windowsDrive -ChildPath "unattend.xml"
          Copy-Item -Path $UnattendPath -Destination $UnattendDestination -Force
        }

        # Added to handle merge folders
        if (-not [string]::IsNullOrEmpty( $MergeFolderPath )) {
          Write-Verbose -Message "Applying merge folder ($MergeFolderPath)..."
          $MergeSourcePath = Join-Path -Path $MergeFolderPath -ChildPath "*"
          Copy-Item -Recurse -Path $MergeFolderPath -Destination $windowsDrive -Force
        }
        #endregion APPLY IMAGE FROM WIM TO THE NEW VHD

        #region BCD manipulation
        if (( $openImage.ImageArchitecture -ne 'ARM' ) -and       # No virtualization platform for ARM images
          ( $openImage.ImageArchitecture -ne 'ARM64' ) -and     # No virtualization platform for ARM64 images
          ( $BcdInVhd -ne 'NativeBoot' ))                       # User asked for a non-bootable image
        {
          if (Test-Path -Path "$($systemDrive)\boot\bcd") {
            Write-Verbose -Message "Image already has BIOS BCD store..."
          } elseif (Test-Path -Path "$($systemDrive)\efi\microsoft\boot\bcd") {
            Write-Verbose -Message "Image already has EFI BCD store..."
          }
          else {
            Write-Verbose -Message "Making image bootable..."

            $WindowsPath = Join-Path -Path $windowsDrive -ChildPath "Windows"

            $bcdBootArgs = @(
              "$WindowsPath",             # Path to the \Windows on the VHD
              '/s',
              "$systemDrive",             # Specifies the volume letter of the drive to create the \BOOT folder on.
              '/v'                        # Enabled verbose logging.
            )
            $bcdPath = @()
            switch ($DiskLayout) {
              'BIOS' {
                $bcdBootArgs += "/f BIOS"   # Specifies the firmware type of the target system partition
                $bcdPath     += Join-Path -Path $systemDrive -ChildPath "boot\bcd"
              }
              'UEFI' {
                $bcdBootArgs += "/f UEFI"   # Specifies the firmware type of the target system partition
                $bcdPath     += Join-Path -Path $systemDrive -ChildPath "efi\microsoft\boot\bcd"
              }

              'WindowsToGo' {
                # Create entries for both UEFI and BIOS if possible
                if (Test-Path -Path "$($windowsDrive)\Windows\boot\EFI\bootmgfw.efi") {
                  $bcdBootArgs += "/f ALL"
                  $bcdPath     += Join-Path -Path $systemDrive -ChildPath "boot\bcd"
                  $bcdPath     += Join-Path -Path $systemDrive -ChildPath "efi\microsoft\boot\bcd"
                } else {
                  $bcdBootArgs += "/f BIOS"   # Specifies the firmware type of the target system partition
                  $bcdPath     += Join-Path -Path $systemDrive -ChildPath "boot\bcd"
                }
              }
            }
            if (Test-Path -Path 'Variable:\BcdLocale') {
              $bcdBootArgs += "/l $BcdLocale.Name"
            }
            Start-Executable -Executable $BCDBoot -Arguments $bcdBootArgs

            # The following is added to mitigate the VMM diff disk handling
            # We're going to change from MBRBootOption to LocateBootOption.

            Write-Verbose -Message "Fixing the Device ID in the BCD store on $($VhdFormat)..."
            $bcdPath | ForEach-Object -Process {
              Start-Executable -Executable 'bcdedit.exe' -Arguments @(
                "/store $PSItem",
                "/set `{bootmgr`} device locate"
              )
              Start-Executable -Executable 'bcdedit.exe' -Arguments @(
                "/store $PSItem",
                "/set `{default`} device locate"
              )
              Start-Executable -Executable 'bcdedit.exe' -Arguments @(
                "/store $PSItem",
                "/set `{default`} osdevice locate"
              )
            }
          }
          Write-Verbose -Message "Drive is bootable."

          # Are we turning the debugger on?
          if ($EnableDebugger -inotlike 'None') {
            $bcdEditArgs = $null;

            # Configure the specified debugging transport and other settings.
            switch ($EnableDebugger) {
              'Serial' {
                $bcdEditArgs = @(
                  '/dbgsettings SERIAL',
                  "DEBUGPORT:$($ComPort.Value)",
                  "BAUDRATE:$($BaudRate.Value)"
                )
              }
              '1394' {
                $bcdEditArgs = @(
                  '/dbgsettings 1394',
                  "CHANNEL:$($Channel.Value)"
                )
              }
              'USB' {
                $bcdEditArgs = @(
                  '/dbgsettings USB',
                  "TARGETNAME:$($Target.Value)"
                )
              }
              'Local' {
                $bcdEditArgs = @(
                  '/dbgsettings LOCAL'
                )
              }
              'Network' {
                $bcdEditArgs = @(
                  '/dbgsettings NET',
                  "HOSTIP:$($IP.Value)",
                  "PORT:$($Port.Value)",
                  "KEY:$($Key.Value)"
                )
              }
            }
            $bcdStores = @(
              "$($systemDrive)\boot\bcd",
              "$($systemDrive)\efi\microsoft\boot\bcd"
            )
            foreach ($bcdStore In $bcdStores) {
              if (Test-Path -Path $bcdStore) {
                Write-Verbose -Message "Turning kernel debugging on in the $VhdFormat for $bcdStore..."
                Start-Executable -Executable 'bcdedit.exe' -Arguments @(
                    "/store $($bcdStore)",
                    "/set `{default`} debug on"
                )
                $bcdEditArguments = @('/store $($bcdStore)') + $bcdEditArgs
                Start-Executable -Executable 'bcdedit.exe' -Arguments $bcdEditArguments
              }
            }
          }
        } else {
          # Don't bother to check on debugging.  We can't boot WoA VHDs in VMs, and
          # if we're native booting, the changes need to be made to the BCD store on the
          # physical computer's boot volume.
          Write-Verbose -Message "Image applied. It is not bootable."
        }
        #endregion BCD manipulation

        #region Additional image enhancements
        if ($RemoteDesktopEnable -or -not $ExpandOnNativeBoot) {
          $hivePath = Join-Path -Path $windowsDrive -ChildPath 'Windows\System32\Config\System'
          $hive = Mount-RegistryHive -Hive $hivePath

          if ($RemoteDesktopEnable) {
            Write-Verbose -Message "Enabling Remote Desktop"
            Set-ItemProperty -Path "HKLM:\$($hive)\ControlSet001\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
          }

          if (-not $ExpandOnNativeBoot) {
            Write-Verbose -Message "Disabling automatic $VhdFormat expansion for Native Boot"
            Set-ItemProperty -Path "HKLM:\$($hive)\ControlSet001\Services\FsDepends\Parameters" -Name "VirtualDiskExpandOnMount" -Value 4
          }
          Dismount-RegistryHive -HiveMountPoint $hive
        }

        if ($DisableWindowsService.Length -gt 0) {
          $hivePath = Join-Path -Path $windowsDrive -ChildPath 'Windows\System32\Config\System'
          $hive = Mount-RegistryHive -Hive $hivePath
          foreach ($svc in $DisableWindowsService) {
            Write-Verbose -Message "Disabling Windows service $($svc)"
            Set-ItemProperty -Path "HKLM:\$($hive)\ControlSet001\Services\$($svc)" -Name "Start" -Value 0x4 -Type DWord
          }
          Dismount-RegistryHive -HiveMountPoint $hive
        }

        if ($DisableNotificationCenter) {
          $hivePath = Join-Path -Path $windowsDrive -ChildPath 'Users\Default\NTUSER.DAT'
          $hive = Mount-RegistryHive -Hive $hivePath
          Write-Verbose -Message "Disabling Windows Notification Center in default user registry hive"
          Set-ItemProperty -Path "HKLM:\$($hive)\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 0x1 -Type DWord
          Dismount-RegistryHive -HiveMountPoint $hive
        }

        if ($Driver) {
          Write-Verbose -Message "Adding Windows Drivers to the Image"
          $Driver | ForEach-Object -Process {
            Write-Verbose -Message "Driver path: $PSItem"
            Add-WindowsDriver -Path $windowsDrive -Recurse -Driver $PSItem -Verbose:$false | Out-Null
          }
        }

        if ($Feature) {
          Write-Verbose -Message "Installing Windows Feature(s) $Feature to the Image"
          $FeatureSourcePath = Join-Path -Path "$($driveLetter):" -ChildPath "sources\sxs"
          Write-Verbose -Message "From $FeatureSourcePath"
          Enable-WindowsOptionalFeature -FeatureName $Feature -Source $FeatureSourcePath -Path $windowsDrive -All -Verbose:$false | Out-Null
        }

        if ($Package) {
          Write-Verbose -Message "Adding Windows Packages to the Image"
          $Package | ForEach-Object -Process {
            Write-Verbose -Message "Package path: $PSItem"
            Add-WindowsPackage -Path $windowsDrive -PackagePath $PSItem -Verbose:$false | Out-Null
          }
        }
        #endregion Additional image enhancements

        #region Dispose paths and dismount VHD
        # Remove system partition access path, if necessary
        if ($DiskLayout -eq 'UEFI' -and $BcdInVhd -eq 'VirtualMachine') {
            Remove-PartitionAccessPath -InputObject $systemPartition -AccessPath $systemPartition.AccessPaths[0] -PassThru | Out-Null
        }

        if ([String]::IsNullOrEmpty( $vhdFinalName )) {
          # We need to generate a file name.
          Write-Verbose -Message "Generating name for $VhdFormat..."

          $HivePath = Join-Path -Path $windowsDrive -ChildPath "Windows\System32\Config\Software"

          $hive         = Mount-RegistryHive -Hive $hivePath

          $buildLabEx   = ( Get-ItemProperty "HKLM:\$($hive)\Microsoft\Windows NT\CurrentVersion" ).BuildLabEx
          $installType  = ( Get-ItemProperty "HKLM:\$($hive)\Microsoft\Windows NT\CurrentVersion" ).InstallationType
          $editionId    = ( Get-ItemProperty "HKLM:\$($hive)\Microsoft\Windows NT\CurrentVersion" ).EditionID
          $skuFamily    = $null

          Dismount-RegistryHive -HiveMountPoint $hive

          # Is this ServerCore?
          # Since we're only doing this string comparison against the InstallType key, we won't get
          # false positives with the Core SKU.
          if ($installType.ToUpper().Contains('CORE')) {
            $editionId += 'Core'
          }

          # What type of SKU are we?
          if ($installType.ToUpper().Contains('SERVER')) {
            $skuFamily = 'Server'
          }
          elseif ($installType.ToUpper().Contains('CLIENT')) {
            $skuFamily = 'Client'
          } else {
            $skuFamily = 'Unknown'
          }

          # ISSUE - do we want VL here?
          $vhdFinalName = "$($buildLabEx)_$($skuFamily)_$($editionId)_$($openImage.ImageDefaultLanguage).$($VhdFormat.ToLower())"
          Write-Debug -Message "    $VhdFormat final name is: `"$vhdFinalName`""
        }

        if ($hyperVEnabled) {
          Write-Verbose -Message "Dismounting $VhdFormat..."
          Dismount-VHD -Path $VhdPath
        } else {
          Write-Verbose -Message "Closing $VhdFormat..."
          $DismountDiskImage = Dismount-DiskImage -ImagePath $VhdPath -PassThru
        }
        $vhdParentPath = Split-Path -Path $VhdPath -Parent
        $vhdFinalPath  = Join-Path  -Path $vhdParentPath -ChildPath $vhdFinalName

        Write-Debug -Message "    $VhdFormat final path is: `"$vhdFinalPath`""

        if (Test-Path -Path $vhdFinalPath) {
          $VhdNameOld = Split-Path -Path $vhdFinalPath -Leaf
          Write-Verbose -Message "Deleting pre-existing $($VhdFormat): `"$VhdNameOld`"..."
          Remove-Item -Path $vhdFinalPath -Force
        }
        Write-Debug -Message "    Renaming $VhdFormat at `"$VhdPath`"."
        $VhdPathFull = ( Resolve-Path -Path $VhdPath ).Path
        $RenameItem = Rename-Item -Path $VhdPathFull -NewName $vhdFinalName -Force -PassThru
        $vhd += Get-DiskImage -ImagePath $vhdFinalPath
        $vhdFinalName = $null
        #endregion Dispose paths and dismount images
      }
    } catch {
      Write-Verbose -Message ( [string]::Empty )
      Write-Error   -Message $PSItem
      Write-Verbose -Message "Log folder is `"$logFolder`""
    } finally {
      Write-Verbose -Message ( [string]::Empty )
      # If we still have a WIM image open, close it.
      if ($openWim -ne $null) {
        Write-Verbose -Message "Closing Windows image..."
        $openWim.Close()
      }

      # If we still have a registry hive mounted, dismount it.
      if ($mountedHive -ne $null) {
        Write-Verbose -Message "Closing registry hive..."
        Dismount-RegistryHive -HiveMountPoint $mountedHive
      }

      # If VHD is mounted, unmount it
      if (Test-Path -Path $VhdPath) {
        if ($hyperVEnabled) {
          if (( Get-VHD -Path $VhdPath ).Attached) {
            Dismount-VHD -Path $VhdPath
          }
        } else {
          $DismountDiskImage = Dismount-DiskImage -ImagePath $VhdPath -PassThru
        }
      }

      # If we still have an ISO open, close it.
      if ($openIso -ne $null) {
        Write-Verbose -Message "Closing ISO..."
        $DismountDiskImage = Dismount-DiskImage -ImagePath $IsoPath -PassThru
      }

      if (-not $CacheSource) {
        if ($tempSource -and ( Test-Path -Path $tempSource )) {
          $Item = Remove-Item -Path $tempSource -Force
        }
      }

      # Close out the transcript and tell the user we're done.
      Write-Verbose -Message "Done."
      if ($transcripting) {
        $null = Stop-Transcript
      }
    }
  }
  end {
    if ($Passthru) {
        return $vhd
    }
  }
}

# Helper functions. Not intended to be called outside of Convert-WindowsImage.

function Add-WindowsImageTypes {
    $Code = @"
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Win32.SafeHandles;

namespace WIM2VHD {
  /// <summary>
  /// P/Invoke methods and associated enums, flags, and structs.
  /// </summary>
  public class NativeMethods {
    #region Delegates and Callbacks
    #region WIMGAPI

    ///<summary>
    ///User-defined function used with the RegisterMessageCallback or UnregisterMessageCallback function.
    ///</summary>
    ///<param name="MessageId">Specifies the message being sent.</param>
    ///<param name="wParam">Specifies additional message information. The contents of this parameter depend on the value of the
    ///MessageId parameter.</param>
    ///<param name="lParam">Specifies additional message information. The contents of this parameter depend on the value of the
    ///MessageId parameter.</param>
    ///<param name="UserData">Specifies the user-defined value passed to RegisterCallback.</param>
    ///<returns>
    ///To indicate success and to enable other subscribers to process the message return WIM_MSG_SUCCESS.
    ///To prevent other subscribers from receiving the message, return WIM_MSG_DONE.
    ///To cancel an image apply or capture, return WIM_MSG_ABORT_IMAGE when handling the WIM_MSG_PROCESS message.
    ///</returns>
    public delegate uint WimMessageCallback(uint   MessageId, IntPtr wParam, IntPtr lParam, IntPtr UserData);

    public static void RegisterMessageCallback(WimFileHandle hWim, WimMessageCallback callback) {
      uint _callback = NativeMethods.WimRegisterMessageCallback(hWim, callback, IntPtr.Zero);
      int rc = Marshal.GetLastWin32Error();
      if (0 != rc) {
        // throw an exception if something bad happened on the Win32 end.
        throw new InvalidOperationException(string.Format(CultureInfo.CurrentCulture, "Unable to register message callback."));
      }
    }

    public static void UnregisterMessageCallback(WimFileHandle hWim, WimMessageCallback registeredCallback) {
      bool status = NativeMethods.WimUnregisterMessageCallback(hWim, registeredCallback);
      int rc = Marshal.GetLastWin32Error();
      if (!status) {
        throw new InvalidOperationException(string.Format(CultureInfo.CurrentCulture, "Unable to unregister message callback."));
      }
    }

    #endregion WIMGAPI
    #endregion Delegates and Callbacks

    #region Constants

    #region VDiskInterop

    /// <summary>
    /// The default depth in a VHD parent chain that this library will search through.
    /// If you want to go more than one disk deep into the parent chain, provide a different value.
    /// </summary>
    public   const uint  OPEN_VIRTUAL_DISK_RW_DEFAULT_DEPTH   = 0x00000001;

    public   const uint  DEFAULT_BLOCK_SIZE                   = 0x00080000;
    public   const uint  DISK_SECTOR_SIZE                     = 0x00000200;

    internal const uint  ERROR_VIRTDISK_NOT_VIRTUAL_DISK      = 0xC03A0015;
    internal const uint  ERROR_NOT_FOUND                      = 0x00000490;
    internal const uint  ERROR_IO_PENDING                     = 0x000003E5;
    internal const uint  ERROR_INSUFFICIENT_BUFFER            = 0x0000007A;
    internal const uint  ERROR_ERROR_DEV_NOT_EXIST            = 0x00000037;
    internal const uint  ERROR_BAD_COMMAND                    = 0x00000016;
    internal const uint  ERROR_SUCCESS                        = 0x00000000;

    public   const uint  GENERIC_READ                         = 0x80000000;
    public   const uint  GENERIC_WRITE                        = 0x40000000;
    public   const short FILE_ATTRIBUTE_NORMAL                = 0x00000080;
    public   const uint  CREATE_NEW                           = 0x00000001;
    public   const uint  CREATE_ALWAYS                        = 0x00000002;
    public   const uint  OPEN_EXISTING                        = 0x00000003;
    public   const short INVALID_HANDLE_VALUE                 = -1;

    internal static Guid VirtualStorageTypeVendorUnknown      = new Guid('00000000-0000-0000-0000-000000000000');
    internal static Guid VirtualStorageTypeVendorMicrosoft    = new Guid('EC984AEC-A0F9-47e9-901F-71415A66345B');

    #endregion VDiskInterop

    #region WIMGAPI

    public   const uint  WIM_FLAG_VERIFY                      = 0x00000002;
    public   const uint  WIM_FLAG_INDEX                       = 0x00000004;

    public   const uint  WM_APP                               = 0x00008000;

    #endregion WIMGAPI

    #endregion Constants

    #region Enums and Flags

    #region VDiskInterop

    /// <summary>
    /// Indicates the version of the virtual disk to create.
    /// </summary>
    public enum CreateVirtualDiskVersion : int {
      VersionUnspecified         = 0x00000000,
      Version1                   = 0x00000001,
      Version2                   = 0x00000002
    }

    public enum OpenVirtualDiskVersion : int {
      VersionUnspecified         = 0x00000000,
      Version1                   = 0x00000001,
      Version2                   = 0x00000002
    }

    /// <summary>
    /// Contains the version of the virtual hard disk (VHD) ATTACH_VIRTUAL_DISK_PARAMETERS structure to use in calls to VHD functions.
    /// </summary>
    public enum AttachVirtualDiskVersion : int {
      VersionUnspecified         = 0x00000000,
      Version1                   = 0x00000001,
      Version2                   = 0x00000002
    }

    public enum CompactVirtualDiskVersion : int {
      VersionUnspecified         = 0x00000000,
      Version1                   = 0x00000001
    }

    /// <summary>
    /// Contains the type and provider (vendor) of the virtual storage device.
    /// </summary>
    public enum VirtualStorageDeviceType : int {
      /// <summary>
      /// The storage type is unknown or not valid.
      /// </summary>
      Unknown                    = 0x00000000,
      /// <summary>
      /// For internal use only.  This type is not supported.
      /// </summary>
      ISO                        = 0x00000001,
      /// <summary>
      /// Virtual Hard Disk device type.
      /// </summary>
      VHD                        = 0x00000002,
      /// <summary>
      /// Virtual Hard Disk v2 device type.
      /// </summary>
      VHDX                       = 0x00000003
    }

    /// <summary>
    /// Contains virtual hard disk (VHD) open request flags.
    /// </summary>
    [Flags]
    public enum OpenVirtualDiskFlags {
      /// <summary>
      /// No flags. Use system defaults.
      /// </summary>
      None                       = 0x00000000,
      /// <summary>
      /// Open the VHD file (backing store) without opening any differencing-chain parents. Used to correct broken parent links.
      /// </summary>
      NoParents                  = 0x00000001,
      /// <summary>
      /// Reserved.
      /// </summary>
      BlankFile                  = 0x00000002,
      /// <summary>
      /// Reserved.
      /// </summary>
      BootDrive                  = 0x00000004,
    }

    /// <summary>
    /// Contains the bit mask for specifying access rights to a virtual hard disk (VHD).
    /// </summary>
    [Flags]
    public enum VirtualDiskAccessMask {
      /// <summary>
      /// Only Version2 of OpenVirtualDisk API accepts this parameter
      /// </summary>
      None                       = 0x00000000,
      /// <summary>
      /// Open the virtual disk for read-only attach access. The caller must have READ access to the virtual disk image file.
      /// </summary>
      /// <remarks>
      /// If used in a request to open a virtual disk that is already open, the other handles must be limited to either
      /// VIRTUAL_DISK_ACCESS_DETACH or VIRTUAL_DISK_ACCESS_GET_INFO access, otherwise the open request with this flag will fail.
      /// </remarks>
      AttachReadOnly             = 0x00010000,
      /// <summary>
      /// Open the virtual disk for read-write attaching access. The caller must have (READ | WRITE) access to the virtual disk image file.
      /// </summary>
      /// <remarks>
      /// If used in a request to open a virtual disk that is already open, the other handles must be limited to either
      /// VIRTUAL_DISK_ACCESS_DETACH or VIRTUAL_DISK_ACCESS_GET_INFO access, otherwise the open request with this flag will fail.
      /// If the virtual disk is part of a differencing chain, the disk for this request cannot be less than the readWriteDepth specified
      /// during the prior open request for that differencing chain.
      /// </remarks>
      AttachReadWrite            = 0x00020000,
      /// <summary>
      /// Open the virtual disk to allow detaching of an attached virtual disk. The caller must have
      /// (FILE_READ_ATTRIBUTES | FILE_READ_DATA) access to the virtual disk image file.
      /// </summary>
      Detach                     = 0x00040000,
      /// <summary>
      /// Information retrieval access to the virtual disk. The caller must have READ access to the virtual disk image file.
      /// </summary>
      GetInfo                    = 0x00080000,
      /// <summary>
      /// Virtual disk creation access.
      /// </summary>
      Create                     = 0x00100000,
      /// <summary>
      /// Open the virtual disk to perform offline meta-operations. The caller must have (READ | WRITE) access to the virtual
      /// disk image file, up to readWriteDepth if working with a differencing chain.
      /// </summary>
      /// <remarks>
      /// If the virtual disk is part of a differencing chain, the backing store (host volume) is opened in RW exclusive mode up to readWriteDepth.
      /// </remarks>
      MetaOperations             = 0x00200000,
      /// <summary>
      /// Reserved.
      /// </summary>
      Read                       = 0x000D0000,
      /// <summary>
      /// Allows unrestricted access to the virtual disk. The caller must have unrestricted access rights to the virtual disk image file.
      /// </summary>
      All                        = 0x003F0000,
      /// <summary>
      /// Reserved.
      /// </summary>
      Writable                   = 0x00320000
    }

    /// <summary>
    /// Contains virtual hard disk (VHD) creation flags.
    /// </summary>
    [Flags]
    public enum CreateVirtualDiskFlags {
      /// <summary>
      /// Contains virtual hard disk (VHD) creation flags.
      /// </summary>
      None                       = 0x00000000,
      /// <summary>
      /// Pre-allocate all physical space necessary for the size of the virtual disk.
      /// </summary>
      /// <remarks>
      /// The CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION flag is used for the creation of a fixed VHD.
      /// </remarks>
      FullPhysicalAllocation     = 0x00000001
    }

    /// <summary>
    /// Contains virtual disk attach request flags.
    /// </summary>
    [Flags]
    public enum AttachVirtualDiskFlags {
      /// <summary>
      /// No flags. Use system defaults.
      /// </summary>
      None                       = 0x00000000,
      /// <summary>
      /// Attach the virtual disk as read-only.
      /// </summary>
      ReadOnly                   = 0x00000001,
      /// <summary>
      /// No drive letters are assigned to the disk's volumes.
      /// </summary>
      /// <remarks>Oddly enough, this doesn't apply to NTFS mount points.</remarks>
      NoDriveLetter              = 0x00000002,
      /// <summary>
      /// Will decouple the virtual disk lifetime from that of the VirtualDiskHandle.
      /// The virtual disk will be attached until the Detach() function is called, even if all open handles to the virtual disk are closed.
      /// </summary>
      PermanentLifetime          = 0x00000004,
      /// <summary>
      /// Reserved.
      /// </summary>
      NoLocalHost                = 0x00000008
    }

    [Flags]
    public enum DetachVirtualDiskFlag {
      None                       = 0x00000000
    }

    [Flags]
    public enum CompactVirtualDiskFlags {
      None                       = 0x00000000,
      NoZeroScan                 = 0x00000001,
      NoBlockMoves               = 0x00000002
    }

    #endregion VDiskInterop

    #region WIMGAPI

    [FlagsAttribute]
    internal enum
    WimCreateFileDesiredAccess : uint {
      WimQuery                   = 0x00000000,
      WimGenericRead             = 0x80000000
    }

    public enum WimMessage : uint {
      WIM_MSG                    = WM_APP + 0x1476,
      WIM_MSG_TEXT,
      ///<summary>
      ///Indicates an update in the progress of an image application.
      ///</summary>
      WIM_MSG_PROGRESS,
      ///<summary>
      ///Enables the caller to prevent a file or a directory from being captured or applied.
      ///</summary>
      WIM_MSG_PROCESS,
      ///<summary>
      ///Indicates that volume information is being gathered during an image capture.
      ///</summary>
      WIM_MSG_SCANNING,
      ///<summary>
      ///Indicates the number of files that will be captured or applied.
      ///</summary>
      WIM_MSG_SETRANGE,
      ///<summary>
      ///Indicates the number of files that have been captured or applied.
      ///</summary>
      WIM_MSG_SETPOS,
      ///<summary>
      ///Indicates that a file has been either captured or applied.
      ///</summary>
      WIM_MSG_STEPIT,
      ///<summary>
      ///Enables the caller to prevent a file resource from being compressed during a capture.
      ///</summary>
      WIM_MSG_COMPRESS,
      ///<summary>
      ///Alerts the caller that an error has occurred while capturing or applying an image.
      ///</summary>
      WIM_MSG_ERROR,
      ///<summary>
      ///Enables the caller to align a file resource on a particular alignment boundary.
      ///</summary>
      WIM_MSG_ALIGNMENT,
      WIM_MSG_RETRY,
      ///<summary>
      ///Enables the caller to align a file resource on a particular alignment boundary.
      ///</summary>
      WIM_MSG_SPLIT,
      WIM_MSG_SUCCESS            = 0x00000000,
      WIM_MSG_ABORT_IMAGE        = 0xFFFFFFFF
    }

    internal enum
    WimCreationDisposition : uint {
      WimOpenExisting            = 0x00000003,
    }

    internal enum
    WimActionFlags : uint {
      WimIgnored                 = 0x00000000
    }

    internal enum
    WimCompressionType : uint {
      WimIgnored                 = 0x00000000
    }

    internal enum
    WimCreationResult : uint {
      WimCreatedNew              = 0x00000000,
      WimOpenedExisting          = 0x00000001
    }

    #endregion WIMGAPI

    #endregion Enums and Flags

    #region Structs

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CreateVirtualDiskParameters {
      /// <summary>
      /// A CREATE_VIRTUAL_DISK_VERSION enumeration that specifies the version of the CREATE_VIRTUAL_DISK_PARAMETERS structure being passed to or from the virtual hard disk (VHD) functions.
      /// </summary>
      public CreateVirtualDiskVersion Version;

      /// <summary>
      /// Unique identifier to assign to the virtual disk object. If this member is set to zero, a unique identifier is created by the system.
      /// </summary>
      public Guid UniqueId;

      /// <summary>
      /// The maximum virtual size of the virtual disk object. Must be a multiple of 512.
      /// If a ParentPath is specified, this value must be zero.
      /// If a SourcePath is specified, this value can be zero to specify the size of the source VHD to be used, otherwise the size specified must be greater than or equal to the size of the source disk.
      /// </summary>
      public ulong MaximumSize;

      /// <summary>
      /// Internal size of the virtual disk object blocks.
      /// The following are predefined block sizes and their behaviors. For a fixed VHD type, this parameter must be zero.
      /// </summary>
      public uint BlockSizeInBytes;

      /// <summary>
      /// Internal size of the virtual disk object sectors. Must be set to 512.
      /// </summary>
      public uint SectorSizeInBytes;

      /// <summary>
      /// Optional path to a parent virtual disk object. Associates the new virtual disk with an existing virtual disk.
      /// If this parameter is not NULL, SourcePath must be NULL.
      /// </summary>
      public string ParentPath;

      /// <summary>
      /// Optional path to pre-populate the new virtual disk object with block data from an existing disk. This path may refer to a VHD or a physical disk.
      /// If this parameter is not NULL, ParentPath must be NULL.
      /// </summary>
      public string SourcePath;

      /// <summary>
      /// Flags for opening the VHD
      /// </summary>
      public OpenVirtualDiskFlags OpenFlags;

      /// <summary>
      /// GetInfoOnly flag for V2 handles
      /// </summary>
      public bool GetInfoOnly;

      /// <summary>
      /// Virtual Storage Type of the parent disk
      /// </summary>
      public VirtualStorageType ParentVirtualStorageType;

      /// <summary>
      /// Virtual Storage Type of the source disk
      /// </summary>
      public VirtualStorageType SourceVirtualStorageType;

      /// <summary>
      /// A GUID to use for fallback resiliency over SMB.
      /// </summary>
      public Guid ResiliencyGuid;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct VirtualStorageType
    {
      public VirtualStorageDeviceType DeviceId;
      public Guid VendorId;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SecurityDescriptor
    {
      public byte revision;
      public byte size;
      public short control;
      public IntPtr owner;
      public IntPtr group;
      public IntPtr sacl;
      public IntPtr dacl;
    }

    #endregion Structs

    #region VirtDisk.DLL P/Invoke

    [DllImport('virtdisk.dll', CharSet = CharSet.Unicode)]
    public static extern uint
    CreateVirtualDisk(
      [In, Out] ref VirtualStorageType VirtualStorageType,
      [In]          string Path,
      [In]          VirtualDiskAccessMask VirtualDiskAccessMask,
      [In, Out] ref SecurityDescriptor SecurityDescriptor,
      [In]          CreateVirtualDiskFlags Flags,
      [In]          uint ProviderSpecificFlags,
      [In, Out] ref CreateVirtualDiskParameters Parameters,
      [In]          IntPtr Overlapped,
      [Out]     out SafeFileHandle Handle);

    #endregion VirtDisk.DLL P/Invoke

    #region Win32 P/Invoke

    [DllImport('advapi32', SetLastError = true)]
    public static extern bool InitializeSecurityDescriptor(
      [Out]     out SecurityDescriptor pSecurityDescriptor,
      [In]          uint dwRevision);

    #endregion Win32 P/Invoke

    #region WIMGAPI P/Invoke

    #region SafeHandle wrappers for WimFileHandle and WimImageHandle

    public sealed class WimFileHandle : SafeHandle {
        public WimFileHandle(string wimPath) : base(IntPtr.Zero, true) {
            if (String.IsNullOrEmpty(wimPath)) {
              throw new ArgumentNullException('wimPath');
            }
            if (!File.Exists(Path.GetFullPath(wimPath))) {
              throw new FileNotFoundException((new FileNotFoundException()).Message, wimPath);
            }

            NativeMethods.WimCreationResult creationResult;

            this.handle = NativeMethods.WimCreateFile(
              wimPath,
              NativeMethods.WimCreateFileDesiredAccess.WimGenericRead,
              NativeMethods.WimCreationDisposition.WimOpenExisting,
              NativeMethods.WimActionFlags.WimIgnored,
              NativeMethods.WimCompressionType.WimIgnored,
              out creationResult
            );

            // Check results.
            if (creationResult != NativeMethods.WimCreationResult.WimOpenedExisting)
            {
                throw new Win32Exception();
            }

            if (this.handle == IntPtr.Zero)
            {
                throw new Win32Exception();
            }

            // Set the temporary path.
            NativeMethods.WimSetTemporaryPath(
                this,
                Environment.ExpandEnvironmentVariables('%TEMP%')
            );
        }

        protected override bool ReleaseHandle()
        {
            return NativeMethods.WimCloseHandle(this.handle);
        }

        public override bool IsInvalid
        {
            get { return this.handle == IntPtr.Zero; }
        }
    }

    public sealed class WimImageHandle : SafeHandle
    {
        public WimImageHandle(
            WimFile Container,
            uint ImageIndex)
            : base(IntPtr.Zero, true)
            {

            if (null == Container)
            {
                throw new ArgumentNullException('Container');
            }

            if ((Container.Handle.IsClosed) || (Container.Handle.IsInvalid))
            {
                throw new ArgumentNullException('The handle to the WIM file has already been closed, or is invalid.', 'Container');
            }

            if (ImageIndex > Container.ImageCount)
            {
                throw new ArgumentOutOfRangeException('ImageIndex', 'The index does not exist in the specified WIM file.');
            }

            this.handle = NativeMethods.WimLoadImage(
                Container.Handle.DangerousGetHandle(),
                ImageIndex);
        }

        protected override bool ReleaseHandle()
        {
            return NativeMethods.WimCloseHandle(this.handle);
        }

        public override bool IsInvalid
        {
            get { return this.handle == IntPtr.Zero; }
        }
    }

    #endregion SafeHandle wrappers for WimFileHandle and WimImageHandle

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMCreateFile')]
    internal static extern IntPtr
    WimCreateFile(
        [In, MarshalAs(UnmanagedType.LPWStr)] string WimPath,
        [In]    WimCreateFileDesiredAccess DesiredAccess,
        [In]    WimCreationDisposition CreationDisposition,
        [In]    WimActionFlags FlagsAndAttributes,
        [In]    WimCompressionType CompressionType,
        [Out, Optional] out WimCreationResult CreationResult
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMCloseHandle')]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool
    WimCloseHandle(
        [In]    IntPtr Handle
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMLoadImage')]
    internal static extern IntPtr
    WimLoadImage(
        [In]    IntPtr Handle,
        [In]    uint ImageIndex
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMGetImageCount')]
    internal static extern uint
    WimGetImageCount(
        [In]    WimFileHandle Handle
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMGetImageInformation')]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool
    WimGetImageInformation(
        [In]        SafeHandle Handle,
        [Out]   out StringBuilder ImageInfo,
        [Out]   out uint SizeOfImageInfo
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMSetTemporaryPath')]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool
    WimSetTemporaryPath(
        [In]    WimFileHandle Handle,
        [In]    string TempPath
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMRegisterMessageCallback', CallingConvention = CallingConvention.StdCall)]
    internal static extern uint
    WimRegisterMessageCallback(
        [In, Optional] WimFileHandle      hWim,
        [In]           WimMessageCallback MessageProc,
        [In, Optional] IntPtr             ImageInfo
    );

    [DllImport('Wimgapi.dll', CharSet = CharSet.Unicode, SetLastError = true, EntryPoint = "WIMUnregisterMessageCallback', CallingConvention = CallingConvention.StdCall)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool
    WimUnregisterMessageCallback(
        [In, Optional] WimFileHandle      hWim,
        [In]           WimMessageCallback MessageProc
    );


    #endregion WIMGAPI P/Invoke
  }

  #region WIM Interop

  public class WimFile {
    internal XDocument m_xmlInfo;
    internal List<WimImage> m_imageList;

    private static NativeMethods.WimMessageCallback wimMessageCallback;

    #region Events

    /// <summary>
    /// DefaultImageEvent handler
    /// </summary>
    public delegate void DefaultImageEventHandler(object sender, DefaultImageEventArgs e);

    ///<summary>
    ///ProcessFileEvent handler
    ///</summary>
    public delegate void ProcessFileEventHandler(object sender, ProcessFileEventArgs e);

    ///<summary>
    ///Enable the caller to prevent a file resource from being compressed during a capture.
    ///</summary>
    public event ProcessFileEventHandler ProcessFileEvent;

    ///<summary>
    ///Indicate an update in the progress of an image application.
    ///</summary>
    public event DefaultImageEventHandler ProgressEvent;

    ///<summary>
    ///Alert the caller that an error has occurred while capturing or applying an image.
    ///</summary>
    public event DefaultImageEventHandler ErrorEvent;

    ///<summary>
    ///Indicate that a file has been either captured or applied.
    ///</summary>
    public event DefaultImageEventHandler StepItEvent;

    ///<summary>
    ///Indicate the number of files that will be captured or applied.
    ///</summary>
    public event DefaultImageEventHandler SetRangeEvent;

    ///<summary>
    ///Indicate the number of files that have been captured or applied.
    ///</summary>
    public event DefaultImageEventHandler SetPosEvent;

    #endregion Events

    private enum ImageEventMessage : uint {
      ///<summary>
      ///Enables the caller to prevent a file or a directory from being captured or applied.
      ///</summary>
      Progress = NativeMethods.WimMessage.WIM_MSG_PROGRESS,
      ///<summary>
      ///Notification sent to enable the caller to prevent a file or a directory from being captured or applied.
      ///To prevent a file or a directory from being captured or applied, call WindowsImageContainer.SkipFile().
      ///</summary>
      Process = NativeMethods.WimMessage.WIM_MSG_PROCESS,
      ///<summary>
      ///Enables the caller to prevent a file resource from being compressed during a capture.
      ///</summary>
      Compress = NativeMethods.WimMessage.WIM_MSG_COMPRESS,
      ///<summary>
      ///Alerts the caller that an error has occurred while capturing or applying an image.
      ///</summary>
      Error = NativeMethods.WimMessage.WIM_MSG_ERROR,
      ///<summary>
      ///Enables the caller to align a file resource on a particular alignment boundary.
      ///</summary>
      Alignment = NativeMethods.WimMessage.WIM_MSG_ALIGNMENT,
      ///<summary>
      ///Enables the caller to align a file resource on a particular alignment boundary.
      ///</summary>
      Split = NativeMethods.WimMessage.WIM_MSG_SPLIT,
      ///<summary>
      ///Indicates that volume information is being gathered during an image capture.
      ///</summary>
      Scanning = NativeMethods.WimMessage.WIM_MSG_SCANNING,
      ///<summary>
      ///Indicates the number of files that will be captured or applied.
      ///</summary>
      SetRange = NativeMethods.WimMessage.WIM_MSG_SETRANGE,
      ///<summary>
      ///Indicates the number of files that have been captured or applied.
      /// </summary>
      SetPos = NativeMethods.WimMessage.WIM_MSG_SETPOS,
      ///<summary>
      ///Indicates that a file has been either captured or applied.
      ///</summary>
      StepIt = NativeMethods.WimMessage.WIM_MSG_STEPIT,
      ///<summary>
      ///Success.
      ///</summary>
      Success = NativeMethods.WimMessage.WIM_MSG_SUCCESS,
      ///<summary>
      ///Abort.
      ///</summary>
      Abort = NativeMethods.WimMessage.WIM_MSG_ABORT_IMAGE
    }

    ///<summary>
    ///Event callback to the Wimgapi events
    ///</summary>
    private uint ImageEventMessagePump (uint MessageId, IntPtr wParam, IntPtr lParam, IntPtr UserData) {
      uint status = (uint) NativeMethods.WimMessage.WIM_MSG_SUCCESS;

      DefaultImageEventArgs eventArgs = new DefaultImageEventArgs(wParam, lParam, UserData);

      switch ((ImageEventMessage)MessageId) {
        case ImageEventMessage.Progress:
          ProgressEvent(this, eventArgs);
          break;

        case ImageEventMessage.Process:
          if (null != ProcessFileEvent)
          {
              string fileToImage = Marshal.PtrToStringUni(wParam);
              ProcessFileEventArgs fileToProcess = new ProcessFileEventArgs(fileToImage, lParam);
              ProcessFileEvent(this, fileToProcess);

              if (fileToProcess.Abort == true)
              {
                  status = (uint)ImageEventMessage.Abort;
              }
          }
          break;

        case ImageEventMessage.Error:
          if (null != ErrorEvent) {
            ErrorEvent(this, eventArgs);
          }
          break;

        case ImageEventMessage.SetRange:
          if (null != SetRangeEvent) {
              SetRangeEvent(this, eventArgs);
          }
          break;

        case ImageEventMessage.SetPos:
          if (null != SetPosEvent) {
            SetPosEvent(this, eventArgs);
          }
          break;

        case ImageEventMessage.StepIt:
          if (null != StepItEvent) {
            StepItEvent(this, eventArgs);
          }
          break;

        default:
          break;
      }
      return status;
    }

    /// <summary>
    /// Constructor.
    /// </summary>
    /// <param name="wimPath">Path to the WIM container.</param>
    public WimFile(string wimPath) {
      if (string.IsNullOrEmpty(wimPath)) {
        throw new ArgumentNullException('wimPath');
      }
      if (!File.Exists(Path.GetFullPath(wimPath))) {
        throw new FileNotFoundException((new FileNotFoundException()).Message, wimPath);
      }
      Handle = new NativeMethods.WimFileHandle(wimPath);
      // Hook up the events before we return.
      //wimMessageCallback = new NativeMethods.WimMessageCallback(ImageEventMessagePump);
      //NativeMethods.RegisterMessageCallback(this.Handle, wimMessageCallback);
    }

    /// <summary>
    /// Closes the WIM file.
    /// </summary>
    public void Close() {
      foreach (WimImage image in Images) {
        image.Close();
      }
      if (null != wimMessageCallback) {
        NativeMethods.UnregisterMessageCallback(this.Handle, wimMessageCallback);
        wimMessageCallback = null;
      }
      if ((!Handle.IsClosed) && (!Handle.IsInvalid)) {
        Handle.Close();
      }
    }

    /// <summary>
    /// Provides a list of WimImage objects, representing the images in the WIM container file.
    /// </summary>
    public List<WimImage> Images {
      get {
        if (null == m_imageList) {
          int imageCount = (int)ImageCount;
          m_imageList = new List<WimImage>(imageCount);
          for (int i = 0; i < imageCount; i++) {
            // Load up each image so it's ready for us.
            m_imageList.Add(new WimImage(this, (uint)i + 1));
          }
        }
        return m_imageList;
      }
    }

    /// <summary>
    /// Provides a list of names of the images in the specified WIM container file.
    /// </summary>
    public List<string> ImageNames {
      get {
        List<string> nameList = new List<string>();
        foreach (WimImage image in Images) {
          nameList.Add(image.ImageName);
        }
        return nameList;
      }
    }

    /// <summary>
    /// Indexer for WIM images inside the WIM container, indexed by the image number.
    /// The list of Images is 0-based, but the WIM container is 1-based, so we automatically compensate for that.
    /// this[1] returns the 0th image in the WIM container.
    /// </summary>
    /// <param name="ImageIndex">The 1-based index of the image to retrieve.</param>
    /// <returns>WinImage object.</returns>
    public WimImage this[int ImageIndex]
    {
      get {
        return Images[ImageIndex - 1];
      }
    }

    /// <summary>
    /// Indexer for WIM images inside the WIM container, indexed by the image name.
    /// WIMs created by different processes sometimes contain different information - including the name.
    /// Some images have their name stored in the Name field, some in the Flags field, and some in the EditionID field.
    /// We take all of those into account in while searching the WIM.
    /// </summary>
    /// <param name="ImageName"></param>
    /// <returns></returns>
    public WimImage this[string ImageName] {
      get {
        return Images.Where(i => (i.ImageName.ToUpper()  == ImageName.ToUpper() || i.ImageFlags.ToUpper() == ImageName.ToUpper() )).DefaultIfEmpty(null).FirstOrDefault<WimImage>();
      }
    }

    /// <summary>
    /// returns the number of images in the WIM container.
    /// </summary>
    internal uint ImageCount {
      get { return NativeMethods.WimGetImageCount(Handle); }
    }

    /// <summary>
    /// returns an XDocument representation of the XML metadata for the WIM container and associated images.
    /// </summary>
    internal XDocument XmlInfo {
      get {
        if (null == m_xmlInfo) {
          StringBuilder builder;
          uint bytes;
          if (!NativeMethods.WimGetImageInformation(Handle, out builder, out bytes)) {
            throw new Win32Exception();
          }

          // Ensure the length of the returned bytes to avoid garbage characters at the end.
          int charCount = (int)bytes / sizeof(char);
          if (null != builder) {
            // Get rid of the unicode file marker at the beginning of the XML.
            builder.Remove(0, 1);
            builder.EnsureCapacity(charCount - 1);
            builder.Length = charCount - 1;

            // This isn't likely to change while we have the image open, so cache it.
            m_xmlInfo = XDocument.Parse(builder.ToString().Trim());
          } else {
            m_xmlInfo = null;
          }
        }
        return m_xmlInfo;
      }
    }

    public NativeMethods.WimFileHandle Handle {
      get;
      private set;
    }
  }

  public class WimImage {
    internal XDocument m_xmlInfo;

    public WimImage(WimFile Container, uint ImageIndex) {
      if (null == Container) {
        throw new ArgumentNullException("Container");
      }
      if ((Container.Handle.IsClosed) || (Container.Handle.IsInvalid)) {
        throw new ArgumentNullException("The handle to the WIM file has already been closed, or is invalid.", "Container");
      }
      if (ImageIndex > Container.ImageCount) {
        throw new ArgumentOutOfRangeException("ImageIndex", "The index does not exist in the specified WIM file.");
      }
      Handle = new NativeMethods.WimImageHandle(Container, ImageIndex);
    }

    public enum Architectures : uint {
      x86   = 0x0,
      ARM   = 0x5,
      IA64  = 0x6,
      AMD64 = 0x9,
      ARM64 = 0xC
    }

    public void Close() {
      if ((!Handle.IsClosed) && (!Handle.IsInvalid)) {
        Handle.Close();
      }
    }

    public NativeMethods.WimImageHandle Handle {
      get;
      private set;
    }

    internal XDocument XmlInfo {
      get {
        if (null == m_xmlInfo) {
          StringBuilder builder;
          uint bytes;
          if (!NativeMethods.WimGetImageInformation(Handle, out builder, out bytes)) {
            throw new Win32Exception();
          }

          // Ensure the length of the returned bytes to avoid garbage characters at the end.
          int charCount = (int)bytes / sizeof(char);
          if (null != builder) {
            // Get rid of the unicode file marker at the beginning of the XML.
            builder.Remove(0, 1);
            builder.EnsureCapacity(charCount - 1);
            builder.Length = charCount - 1;

            // This isn't likely to change while we have the image open, so cache it.
            m_xmlInfo = XDocument.Parse(builder.ToString().Trim());
          } else {
            m_xmlInfo = null;
          }
        }
        return m_xmlInfo;
      }
    }

    public string ImageIndex {
      get {
        return XmlInfo.Element("IMAGE").Attribute("INDEX").Value;
      }
    }

    public string ImageName {
      get {
        return XmlInfo.XPathSelectElement("/IMAGE/NAME").Value;
      }
    }

    public string ImageEditionId {
      get { return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/EDITIONID").Value; }
    }

    public string ImageFlags {
      get {
        string flagValue = String.Empty;

        try {
          flagValue = XmlInfo.XPathSelectElement("/IMAGE/FLAGS").Value;
        } catch {
          // Some WIM files don't contain a FLAGS element in the metadata.
          // In an effort to support those WIMs too, inherit the EditionId if there
          // are no Flags.

          if (String.IsNullOrEmpty(flagValue)) {
            flagValue = this.ImageEditionId;

            // Check to see if the EditionId is "ServerHyper".  If so,
            // tweak it to be "ServerHyperCore" instead.

            if (0 == String.Compare('serverhyper', flagValue, true)) {
              flagValue = "ServerHyperCore";
            }
          }
        }
        return flagValue;
      }
    }

    public string ImageProductType {
      get {
        return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/PRODUCTTYPE").Value;
      }
    }

    public string ImageInstallationType {
      get {
        return XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/INSTALLATIONTYPE").Value;
      }
    }

    public string ImageDescription {
      get {
        return XmlInfo.XPathSelectElement("/IMAGE/DESCRIPTION").Value;
      }
    }

    public ulong ImageSize {
      get {
        return ulong.Parse(XmlInfo.XPathSelectElement("/IMAGE/TOTALBYTES").Value);
      }
    }

    public Architectures ImageArchitecture {
      get {
        int arch = -1;
        try {
          arch = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/ARCH").Value);
        }
        catch { }
        return (Architectures)arch;
      }
    }

    public string ImageDefaultLanguage {
      get {
        string lang = null;
        try {
          lang = XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/LANGUAGES/DEFAULT").Value;
        } catch { }
        return lang;
      }
    }

    public Version ImageVersion {
      get {
        int major = 0;
        int minor = 0;
        int build = 0;
        int revision = 0;
        try {
          major = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/MAJOR").Value);
          minor = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/MINOR").Value);
          build = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/BUILD").Value);
          revision = int.Parse(XmlInfo.XPathSelectElement("/IMAGE/WINDOWS/VERSION/SPBUILD").Value);
        } catch { }
        return (new Version(major, minor, build, revision));
      }
    }

    public string ImageDisplayName {
      get {
        return XmlInfo.XPathSelectElement("/IMAGE/DISPLAYNAME").Value;
      }
    }

    public string ImageDisplayDescription {
      get {
        return XmlInfo.XPathSelectElement("/IMAGE/DISPLAYDESCRIPTION").Value;
      }
    }
  }

  ///<summary>
  ///Describes the file that is being processed for the ProcessFileEvent.
  ///</summary>
  public class DefaultImageEventArgs : EventArgs {
    ///<summary>
    ///Default constructor.
    ///</summary>
    public DefaultImageEventArgs(IntPtr wideParameter, IntPtr leftParameter, IntPtr userData) {
      WideParameter = wideParameter;
      LeftParameter = leftParameter;
      UserData      = userData;
    }

    ///<summary>
    ///wParam
    ///</summary>
    public IntPtr WideParameter {
      get;
      private set;
    }

    ///<summary>
    ///lParam
    ///</summary>
    public IntPtr LeftParameter {
      get;
      private set;
    }

    ///<summary>
    ///UserData
    ///</summary>
    public IntPtr UserData {
      get;
      private set;
    }
  }

  ///<summary>
  ///Describes the file that is being processed for the ProcessFileEvent.
  ///</summary>
  public class ProcessFileEventArgs : EventArgs {
    ///<summary>
    ///Default constructor.
    ///</summary>
    ///<param name="file">Fully qualified path and file name. For example: c:\file.sys.</param>
    ///<param name="skipFileFlag">Default is false - skip file and continue.
    ///Set to true to abort the entire image capture.</param>
    public ProcessFileEventArgs(string file, IntPtr skipFileFlag) {
      m_FilePath = file;
      m_SkipFileFlag = skipFileFlag;
    }

    ///<summary>
    ///Skip file from being imaged.
    ///</summary>
    public void SkipFile() {
      byte[] byteBuffer = {0};
      int byteBufferSize = byteBuffer.Length;
      Marshal.Copy(byteBuffer, 0, m_SkipFileFlag, byteBufferSize);
    }

    ///<summary>
    ///Fully qualified path and file name.
    ///</summary>
    public string FilePath {
      get {
        string stringToreturn = "";
        if (m_FilePath != null) {
          stringToreturn = m_FilePath;
        }
        return stringToreturn;
      }
    }

    ///<summary>
    ///Flag to indicate if the entire image capture should be aborted.
    ///Default is false - skip file and continue. Setting to true will
    ///abort the entire image capture.
    ///</summary>
    public bool Abort {
        set {
          m_Abort = value;
        }
        get {
          return m_Abort;
        }
    }

    private string m_FilePath;
    private bool m_Abort;
    private IntPtr m_SkipFileFlag;
  }
  #endregion WIM Interop

  #region VHD Interop
  // Based on code written by the Hyper-V Test team.
  /// <summary>
  /// The Virtual Hard Disk class provides methods for creating and manipulating Virtual Hard Disk files.
  /// </summary>
  public class VirtualHardDisk {
    #region Static Methods

    #region Sparse Disks

    /// <summary>
    /// Abbreviated signature of CreateSparseDisk so it's easier to use from WIM2VHD.
    /// </summary>
    /// <param name="virtualStorageDeviceType">The type of disk to create, VHD or VHDX.</param>
    /// <param name="path">The path of the disk to create.</param>
    /// <param name="size">The maximum size of the disk to create.</param>
    /// <param name="overwrite">Overwrite the VHD if it already exists.</param>
    public static void
    CreateSparseDisk(NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType, string path, ulong size, bool overwrite) {
      CreateSparseDisk(
        path,
        size,
        overwrite,
        null,
        IntPtr.Zero,
        (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
          ? NativeMethods.DEFAULT_BLOCK_SIZE
          : 0,
        virtualStorageDeviceType,
        NativeMethods.DISK_SECTOR_SIZE);
    }

    /// <summary>
    /// Creates a new sparse (dynamically expanding) virtual hard disk (.vhd). Supports both sync and async modes.
    /// The VHD image file uses only as much space on the backing store as needed to store the actual data the VHD currently contains.
    /// </summary>
    /// <param name="path">The path and name of the VHD to create.</param>
    /// <param name="size">The size of the VHD to create in bytes.
    /// When creating this type of VHD, the VHD API does not test for free space on the physical backing store based on the maximum size requested,
    /// therefore it is possible to successfully create a dynamic VHD with a maximum size larger than the available physical disk free space.
    /// The maximum size of a dynamic VHD is 2,040 GB.  The minimum size is 3 MB.</param>
    /// <param name="source">Optional path to pre-populate the new virtual disk object with block data from an existing disk
    /// This path may refer to a VHD or a physical disk.  Use NULL if you don't want a source.</param>
    /// <param name="overwrite">If the VHD exists, setting this parameter to 'True' will delete it and create a new one.</param>
    /// <param name="overlapped">If not null, the operation runs in async mode</param>
    /// <param name="blockSizeInBytes">Block size for the VHD.</param>
    /// <param name="virtualStorageDeviceType">VHD format version (VHD1 or VHD2)</param>
    /// <param name="sectorSizeInBytes">Sector size for the VHD.</param>
    /// <exception cref="ArgumentOutOfRangeException">thrown when an invalid size is specified</exception>
    /// <exception cref="FileNotFoundException">thrown when source VHD is not found.</exception>
    /// <exception cref="SecurityException">thrown when there was an error while creating the default security descriptor.</exception>
    /// <exception cref="Win32Exception">thrown when an error occurred while creating the VHD.</exception>
    public static void CreateSparseDisk(string path, ulong size, bool overwrite, string source, IntPtr overlapped, uint blockSizeInBytes, NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType, uint sectorSizeInBytes) {

      // Validate the virtualStorageDeviceType
      if (virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHD && virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHDX) {
        throw (new ArgumentOutOfRangeException("virtualStorageDeviceType", virtualStorageDeviceType, "VirtualStorageDeviceType must be VHD or VHDX."));
      }

      // Validate size.  It needs to be a multiple of DISK_SECTOR_SIZE (512)...
      if ((size % NativeMethods.DISK_SECTOR_SIZE) != 0) {
        throw (new ArgumentOutOfRangeException("size", size, "The size of the virtual disk must be a multiple of 512."));
      }

      if ((!String.IsNullOrEmpty(source)) && (!System.IO.File.Exists(source))) {
        throw (new System.IO.FileNotFoundException( "Unable to find the source file.", source));
      }

      if ((overwrite) && (System.IO.File.Exists(path))) {
        System.IO.File.Delete(path);
      }

      NativeMethods.CreateVirtualDiskParameters createParams = new NativeMethods.CreateVirtualDiskParameters();

      // Select the correct version.
      createParams.Version = (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
        ? NativeMethods.CreateVirtualDiskVersion.Version1
        : NativeMethods.CreateVirtualDiskVersion.Version2;

      createParams.UniqueId                 = Guid.NewGuid();
      createParams.MaximumSize              = size;
      createParams.BlockSizeInBytes         = blockSizeInBytes;
      createParams.SectorSizeInBytes        = sectorSizeInBytes;
      createParams.ParentPath               = null;
      createParams.SourcePath               = source;
      createParams.OpenFlags                = NativeMethods.OpenVirtualDiskFlags.None;
      createParams.GetInfoOnly              = false;
      createParams.ParentVirtualStorageType = new NativeMethods.VirtualStorageType();
      createParams.SourceVirtualStorageType = new NativeMethods.VirtualStorageType();

      //
      // Create and init a security descriptor.
      // Since we're creating an essentially blank SD to use with CreateVirtualDisk
      // the VHD will take on the security values from the parent directory.
      //

      NativeMethods.SecurityDescriptor securityDescriptor;
      if (!NativeMethods.InitializeSecurityDescriptor(out securityDescriptor, 1)) {
        throw (new SecurityException("Unable to initialize the security descriptor for the virtual disk."));
      }

      NativeMethods.VirtualStorageType virtualStorageType = new NativeMethods.VirtualStorageType();
      virtualStorageType.DeviceId = virtualStorageDeviceType;
      virtualStorageType.VendorId = NativeMethods.VirtualStorageTypeVendorMicrosoft;

      SafeFileHandle vhdHandle;

      uint returnCode = NativeMethods.CreateVirtualDisk(
        ref virtualStorageType,
        path,
        (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
          ? NativeMethods.VirtualDiskAccessMask.All
          : NativeMethods.VirtualDiskAccessMask.None,
        ref securityDescriptor,
        NativeMethods.CreateVirtualDiskFlags.None,
        0,
        ref createParams,
        overlapped,
        out vhdHandle);

      vhdHandle.Close();

      if (NativeMethods.ERROR_SUCCESS != returnCode && NativeMethods.ERROR_IO_PENDING != returnCode) {
        throw (new Win32Exception((int)returnCode));
      }
    }
    #endregion Sparse Disks

    #region Fixed Disks

    /// <summary>
    /// Abbreviated signature of CreateFixedDisk so it's easier to use from WIM2VHD.
    /// </summary>
    /// <param name="virtualStorageDeviceType">The type of disk to create, VHD or VHDX.</param>
    /// <param name="path">The path of the disk to create.</param>
    /// <param name="size">The maximum size of the disk to create.</param>
    /// <param name="overwrite">Overwrite the VHD if it already exists.</param>
    public static void
    CreateFixedDisk(NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType, string path, ulong size, bool overwrite) {
      CreateFixedDisk(path, size, overwrite, null, IntPtr.Zero, 0, virtualStorageDeviceType, NativeMethods.DISK_SECTOR_SIZE);
    }

    /// <summary>
    /// Creates a fixed-size Virtual Hard Disk. Supports both sync and async modes. This methods always calls the V2 version of the
    /// CreateVirtualDisk API, and creates VHD2.
    /// </summary>
    /// <param name="path">The path and name of the VHD to create.</param>
    /// <param name="size">The size of the VHD to create in bytes.
    /// The VHD image file is pre-allocated on the backing store for the maximum size requested.
    /// The maximum size of a dynamic VHD is 2,040 GB.  The minimum size is 3 MB.</param>
    /// <param name="source">Optional path to pre-populate the new virtual disk object with block data from an existing disk
    /// This path may refer to a VHD or a physical disk.  Use NULL if you don't want a source.</param>
    /// <param name="overwrite">If the VHD exists, setting this parameter to 'True' will delete it and create a new one.</param>
    /// <param name="overlapped">If not null, the operation runs in async mode</param>
    /// <param name="blockSizeInBytes">Block size for the VHD.</param>
    /// <param name="virtualStorageDeviceType">Virtual storage device type: VHD1 or VHD2.</param>
    /// <param name="sectorSizeInBytes">Sector size for the VHD.</param>
    /// <remarks>Creating a fixed disk can be a time consuming process!</remarks>
    /// <exception cref="ArgumentOutOfRangeException">thrown when an invalid size or wrong virtual storage device type is specified.</exception>
    /// <exception cref="FileNotFoundException">thrown when source VHD is not found.</exception>
    /// <exception cref="SecurityException">thrown when there was an error while creating the default security descriptor.</exception>
    /// <exception cref="Win32Exception">thrown when an error occurred while creating the VHD.</exception>
    public static void CreateFixedDisk(string path, ulong size, bool overwrite, string source, IntPtr overlapped, uint blockSizeInBytes, NativeMethods.VirtualStorageDeviceType virtualStorageDeviceType, uint sectorSizeInBytes) {
      // Validate the virtualStorageDeviceType
      if (virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHD && virtualStorageDeviceType != NativeMethods.VirtualStorageDeviceType.VHDX) {
        throw (new ArgumentOutOfRangeException("virtualStorageDeviceType", virtualStorageDeviceType, "VirtualStorageDeviceType must be VHD or VHDX."));
      }

      // Validate size.  It needs to be a multiple of DISK_SECTOR_SIZE (512)...
      if ((size % NativeMethods.DISK_SECTOR_SIZE) != 0) {
        throw (new ArgumentOutOfRangeException("size", size, "The size of the virtual disk must be a multiple of 512."));
      }

      if ((!String.IsNullOrEmpty(source)) && (!System.IO.File.Exists(source))) {
        throw (new System.IO.FileNotFoundException("Unable to find the source file.', source));
      }

      if ((overwrite) && (System.IO.File.Exists(path))) {
        System.IO.File.Delete(path);
      }

      NativeMethods.CreateVirtualDiskParameters createParams = new NativeMethods.CreateVirtualDiskParameters();

      // Select the correct version.
      createParams.Version = (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
        ? NativeMethods.CreateVirtualDiskVersion.Version1
        : NativeMethods.CreateVirtualDiskVersion.Version2;

      createParams.UniqueId = Guid.NewGuid();
      createParams.MaximumSize = size;
      createParams.BlockSizeInBytes = blockSizeInBytes;
      createParams.SectorSizeInBytes = sectorSizeInBytes;
      createParams.ParentPath = null;
      createParams.SourcePath = source;
      createParams.OpenFlags = NativeMethods.OpenVirtualDiskFlags.None;
      createParams.GetInfoOnly = false;
      createParams.ParentVirtualStorageType = new NativeMethods.VirtualStorageType();
      createParams.SourceVirtualStorageType = new NativeMethods.VirtualStorageType();

      //
      // Create and init a security descriptor.
      // Since we're creating an essentially blank SD to use with CreateVirtualDisk
      // the VHD will take on the security values from the parent directory.
      //

      NativeMethods.SecurityDescriptor securityDescriptor;
      if (!NativeMethods.InitializeSecurityDescriptor(out securityDescriptor, 1)) {
        throw (new SecurityException("Unable to initialize the security descriptor for the virtual disk."));
      }

      NativeMethods.VirtualStorageType virtualStorageType = new NativeMethods.VirtualStorageType();
      virtualStorageType.DeviceId = virtualStorageDeviceType;
      virtualStorageType.VendorId = NativeMethods.VirtualStorageTypeVendorMicrosoft;

      SafeFileHandle vhdHandle;

      uint returnCode = NativeMethods.CreateVirtualDisk(
        ref virtualStorageType,
        path,
        (virtualStorageDeviceType == NativeMethods.VirtualStorageDeviceType.VHD)
          ? NativeMethods.VirtualDiskAccessMask.All
          : NativeMethods.VirtualDiskAccessMask.None,
        ref securityDescriptor,
        NativeMethods.CreateVirtualDiskFlags.FullPhysicalAllocation,
        0,
        ref createParams,
        overlapped,
        out vhdHandle);

      vhdHandle.Close();
      if (NativeMethods.ERROR_SUCCESS != returnCode && NativeMethods.ERROR_IO_PENDING != returnCode) {
        throw (new Win32Exception((int)returnCode));
      }
    }
    #endregion Fixed Disks
    #endregion Static Methods
  }
  #endregion VHD Interop
}
"@
  Add-Type -TypeDefinition $code -ReferencedAssemblies @('System.Xml', 'System.Linq', 'System.Xml.Linq') -ErrorAction SilentlyContinue
}

# This is required for renewed "Mount-RegistryHive" and "Dismount-RegistryHive"
# functions using Windows API. Code borrowed from
# http://www.leeholmes.com/blog/2010/09/24/adjusting-token-privileges-in-powershell/

function Set-TokenPrivilege {
  param(
    # The privilege to adjust. This set is taken from
    # http://msdn.microsoft.com/library/bb530716
    [ValidateSet(
      'SeAssignPrimaryTokenPrivilege',
      'SeAuditPrivilege',
      'SeBackupPrivilege',
      'SeChangeNotifyPrivilege',
      'SeCreateGlobalPrivilege',
      'SeCreatePagefilePrivilege',
      'SeCreatePermanentPrivilege',
      'SeCreateSymbolicLinkPrivilege',
      'SeCreateTokenPrivilege',
      'SeDebugPrivilege',
      'SeEnableDelegationPrivilege',
      'SeImpersonatePrivilege',
      'SeIncreaseBasePriorityPrivilege',
      'SeIncreaseQuotaPrivilege',
      'SeIncreaseWorkingSetPrivilege',
      'SeLoadDriverPrivilege',
      'SeLockMemoryPrivilege',
      'SeMachineAccountPrivilege',
      'SeManageVolumePrivilege',
      'SeProfileSingleProcessPrivilege',
      'SeRelabelPrivilege',
      'SeRemoteShutdownPrivilege',
      'SeRestorePrivilege',
      'SeSecurityPrivilege',
      'SeShutdownPrivilege',
      'SeSyncAgentPrivilege',
      'SeSystemEnvironmentPrivilege',
      'SeSystemProfilePrivilege',
      'SeSystemtimePrivilege',
      'SeTakeOwnershipPrivilege',
      'SeTcbPrivilege',
      'SeTimeZonePrivilege',
      'SeTrustedCredManAccessPrivilege',
      'SeUndockPrivilege',
      'SeUnsolicitedInputPrivilege'
    )]
    $Privilege,

    # The process on which to adjust the privilege. Defaults to the current process.
    $ProcessId = $pid,

    # Switch to disable the privilege, rather than enable it.
    [Switch] $Disable
  )

  # Taken from P/Invoke.NET with minor adjustments.
  $Definition = @'
using System;

using System.Runtime.InteropServices;
public class AdjPriv {
  [DllImport('advapi32.dll', ExactSpelling = true, SetLastError = true)]

  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,

  ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport('advapi32.dll', ExactSpelling = true, SetLastError = true)]

  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport('advapi32.dll', SetLastError = true)]

  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]

  internal struct TokPriv1Luid {
    public int Count;
    public long Luid;
    public int Attr;
  }

  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;

  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable) {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = new IntPtr(processHandle);
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    if(disable) {
      tp.Attr = SE_PRIVILEGE_DISABLED;
    } else {
      tp.Attr = SE_PRIVILEGE_ENABLED;
    }
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
  }
}
'@
  $processHandle = ( Get-Process -id $ProcessId ).Handle
  $Type = Add-Type -TypeDefinition $Definition -PassThru
  $Type[0]::EnablePrivilege( $ProcessHandle, $Privilege, $Disable )
}

# In version 10.0.14300.1000, the below two functions were changed from leveraging
# reg.exe to native Windows API.

function Mount-RegistryHive {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_.Exists })]
    [System.IO.FileInfo] $Hive
  )
  $mountKey = [System.Guid]::NewGuid().ToString()
  try {
    $Definition = @"
[DllImport("advapi32.dll", SetLastError=true)]
public static extern long RegLoadKey(int hKey, String lpSubKey, String lpFile);
"@
    $TokenPrivilege = Set-TokenPrivilege -Privilege 'SeBackupPrivilege'
    $TokenPrivilege = Set-TokenPrivilege -Privilege 'SeRestorePrivilege'
    $HKLM = 0x80000002
    $Reg = Add-Type -MemberDefinition $Definition -Name "ClassLoad" -Namespace "Win32functions" -PassThru
    $Result = $Reg::RegLoadKey( $HKLM, $mountKey, $Hive )
  } catch {
    throw
  }

  # Set a global variable containing the name of the mounted registry key
  # so we can unmount it if there's an error.
  $global:mountedHive = $mountKey
  return $mountKey
}

function Dismount-RegistryHive {
  [CmdletBinding()]
  param(
      [Parameter(
          Mandatory = $true,
          ValueFromPipeline = $true,
          Position          = 0
      )]
      [string]
      [ValidateNotNullOrEmpty()]
      $HiveMountPoint
  )

  try
  {
    $Definition = @"
[DllImport('advapi32.dll', SetLastError=true)]
public static extern int RegUnLoadKey(Int32 hKey,string lpSubKey);
"@
    $TokenPrivilege = Set-TokenPrivilege -Privilege 'SeBackupPrivilege'
    $TokenPrivilege = Set-TokenPrivilege -Privilege 'SeRestorePrivilege'
    $HKLM = 0x80000002
    $Reg = Add-Type -MemberDefinition $Definition -Name "ClassUnload" -Namespace "Win32functions" -PassThru
    $Result = $Reg::RegUnLoadKey( $HKLM, $HiveMountPoint )
  } catch {
    throw
  }
  $global:mountedHive = $null
}

function Test-Admin {
  <#
    .SYNOPSIS
        Short function to determine whether the logged-on user is an administrator.

    .EXAMPLE
        Do you honestly need one?  There are no parameters!

    .OUTPUTS
        $true if user is admin.
        $false if user is not an admin.
  #>
  [CmdletBinding()]
  param()
  $currentUser = New-Object -TypeName "Security.Principal.WindowsPrincipal" -ArgumentList $( [Security.Principal.WindowsIdentity]::GetCurrent() )
  $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  Write-Debug -Message "  is current user Admin?    $isAdmin"
  return $isAdmin
}

function Get-WindowsBuildNumber {
  $os = Get-CimInstance -ClassName "Win32_OperatingSystem" -Verbose:$false
  return [int]($os.BuildNumber)
}


function Start-Executable {
  <#
    .SYNOPSIS
        Runs an external executable file, and validates the error level.

    .PARAMETER Executable
        The path to the executable to run and monitor.

    .PARAMETER Arguments
        An array of arguments to pass to the executable when it's executed.

    .PARAMETER SuccessfulErrorCode
        The error code that means the executable ran successfully.
        The default value is 0.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Executable,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $Arguments,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [int] $SuccessfulErrorCode = 0
  )
  Write-Debug -Message "    Running `"$Executable`" with parameters: `"$Arguments`""

  $StartProcessParam = @{
    FilePath               = $Executable
    ArgumentList           = $Arguments
    NoNewWindow            = $true
    Wait                   = $true
    RedirectStandardOutput = [io.path]::combine( $TempDirectory, $scriptName, $sessionKey, "$Executable-StandardOutput.txt" )
    RedirectStandardError  = [io.path]::combine( $TempDirectory, $scriptName, $sessionKey, "$Executable-StandardError.txt" )
    Passthru               = $true
  }
  $ret = Start-Process @StartProcessParam
  Write-Debug -Message "    return code was $($ret.ExitCode)."
  if ($ret.ExitCode -ne $SuccessfulErrorCode) {
    throw "$Executable failed with code $($ret.ExitCode)!"
  }
}

function Test-IsNetworkLocation {
  <#
    .SYNOPSIS
        Determines whether or not a given path is a network location or a local drive.

    .DESCRIPTION
        function to determine whether or not a specified path is a local path, a UNC path,
        or a mapped network drive.

    .PARAMETER Path
        The path that we need to figure stuff out about,
  #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeLine = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Path
  )
  $Result = $false
  if ([Bool]( [URI]$Path ).IsUNC) {
    $Result = $true
  } else {
    $driveInfo = [IO.DriveInfo]( ( Resolve-Path -Path $Path ).Path )
    if ($driveInfo.DriveType -eq 'Network') {
      $Result = $true
    }
  }
  return $Result
}

# Import module silently
function Import-ModuleEx {
  [CmdletBinding()]
  param (
    [parameter(ParameterSetName = 'Name', Mandatory = $true)]
    [string] $Name,

    [parameter(ParameterSetName = 'ModuleInfo', Mandatory = $true)]
    [System.Management.Automation.PSModuleInfo] $ModuleInfo
  )
  # When we have $VerbosePreference defined as "Continue" and import
  # a module (either implicitly, by firt use, or explictily, calling
  # "Import-Module'), there's a lot of Verbose output listing every cmdlet
  # and every function. This output provides no value, thus we need
  # to suppress it. Unfortunately, even if we pass "-Verobse:$false"
  # to "Import-Module', it only helps to swallow the list of cmdlets.
  # The list of functions is still thrown to output. (This is probably
  # a bug). Thus, we need to temporary change $VerbosePreference.
  $VerbosePreferenceCurrent = $VerbosePreference
  $global:VerbosePreference = "SilentlyContinue"
  if (Test-Path -Path 'Variable:\ModuleInternal') {
    # $Item = Remove-Item -Path "Variable:\ModuleInternal" -Confirm:$false
    # Remove-Variable -Name "Module" -Scope "Global"
    # Remove-Variable -Name "Module" -Scope "Local"
    Remove-Variable -Name "Module" -Scope "Script"
  }
  switch ($PsCmdlet.ParameterSetName) {
    'Name' {
      if (( Get-Module -Name $Name -ListAvailable ) -or ( Test-Path  -Path $Name )) {
        $ModuleInternal = Import-Module -Name $Name -PassThru -WarningAction Ignore
      }
    }
    'ModuleInfo' {
      $ModuleInternal = Import-Module -ModuleInfo $ModuleInfo -PassThru -WarningAction Ignore
    }
  }
  $global:VerbosePreference = $VerbosePreferenceCurrent
  if (Test-Path -Path 'Variable:\ModuleInternal') {
    return $ModuleInternal
  }
}
