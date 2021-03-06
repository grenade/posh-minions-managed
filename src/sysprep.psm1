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
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $destinationPath,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/component-settings-and-properties-reference
    [ValidateSet('amd64', 'arm', 'arm64', 'ia64', 'x86')]
    [string] $processorArchitecture = 'amd64',

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-computername
    [string] $computerName = '*',
    [string] $auditComputerName = $computerName,

    [bool] $auditComputerNameMustReboot = ($auditComputerName -ne $computerName),
    [bool] $extendOsPartition = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-useraccounts-administratorpassword
    [string] $administratorPassword = (New-Password),
    [string] $encodedAdministratorPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(('{0}AdministratorPassword' -f $administratorPassword))),

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount
    [int] $autoLogonCount = 2,
    [switch] $autoLogonEnabled = ($autoLogonCount -gt 0),
    [string] $autoLogonUsername = 'Administrator',
    [string] $autoLogonDomain = $null,
    [string] $autoLogonPassword = $administratorPassword,
    [string] $encodedAutoLogonPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(('{0}Password' -f $autoLogonPassword))),

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-productkey
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-userdata-productkey
    [Parameter(Mandatory = $true)]
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

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-dns-client-dnsdomain
    [string] $dnsDomain = $null,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-dns-client-dnssuffixsearchorder
    [string[]] $dnsSuffixSearchOrder = $null,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-dns-client-usedomainnamedevolution
    [nullable[bool]] $dnsUseDomainNameDevolution = $null,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-dns-client-interfaces
    [hashtable[]] $networkInterfaces = @(
      @{
        'alias' = 'Local Area Connection';
        'dns' = @{
          'domain' = $dnsDomain;
          'dynamic' = $null;
          'register' = $null;
          'search' = @('1.1.1.1', '1.0.0.1', '8.8.8.8', '8.8.4.4')
        }
      }
    ),

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-diskconfiguration
    [hashtable[]] $disks = @(
      @{
        'id' = 0;
        'wipe' = $true;
        'partitions' = @(
          @{
            'id' = 1;
            'type' = @{
              'name' = 'Primary';
              'id' = '0x27'
            };
            'size' = 100;
            'active' = $true;
            'format' = 'NTFS';
            'label' = 'System Reserved'
          },
          @{
            'id' = 2;
            'type' = @{
              'name' = 'Primary'
            };
            'extend' = $true;
            'active' = $true;
            'format' = 'NTFS';
            'label' = 'os';
            'letter' = 'C'
          }
        )
      }
    ),

    [int] $osDiskId = 0,
    [int] $osPartitionId = 2,

    # deprecated after 1709
    [bool] $skipMachineOOBE = $true,

    # deprecated after 1709
    [bool] $skipUserOOBE = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-oobe-protectyourpc
    [ValidateRange(1, 3)]
    [int] $protectYourPC = 3,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-disableautodaylighttimeset
    [bool] $disableAutoDaylightTimeSet = $true,

    [bool] $showWindowsLive = $false,

    # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/enable-remote-desktop-by-using-an-answer-file
    [bool] $enableRDP = $false,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runasynchronous
    [hashtable[]] $commands = @(
      @{
        'Description'   = 'say hello in FirstLogonCommands';
        'CommandLine'   = 'echo "hello beautiful world"';
        'Pass'          = 'oobeSystem';
        'Synchronicity' = 'Synchronous';
        'Priority'      = 500
      },
      @{
        'Description'   = 'say goodbye in FirstLogonCommands';
        'CommandLine'   = 'echo "goodbye cruel world"';
        'Pass'          = 'oobeSystem';
        'Synchronicity' = 'Synchronous';
        'Priority'      = 501
      }
    ),

    [Parameter(Mandatory = $true)]
    [ValidateSet('Windows 7', 'Windows 10', 'Windows Server 1903', 'Windows Server 1909', 'Windows Server 2012 R2', 'Windows Server 2016', 'Windows Server 2019')]
    [string] $os,

    [switch] $obfuscatePassword = $false,

    [ValidateSet('Audit', 'OOBE')]
    [string] $generalizeMode = 'OOBE',
    [switch] $generalizeShutdown = $false,
    [bool] $generalizeOmit = $true,

    [ValidateSet('Audit', 'OOBE')]
    [string] $auditSystemResealMode = 'OOBE',
    [switch] $auditSystemResealShutdown = $false,
    [bool] $auditSystemResealOmit = $true,

    [ValidateSet('Audit', 'OOBE')]
    [string] $auditUserResealMode = 'OOBE',
    [switch] $auditUserResealShutdown = $false,
    [bool] $auditUserResealOmit = (-not $generalizeOmit),

    [ValidateSet('Audit', 'OOBE')]
    [string] $oobeSystemResealMode = 'OOBE',
    [switch] $oobeSystemResealShutdown = $false,
    [bool] $oobeSystemResealOmit = $true,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-display-colordepth
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-display-colordepth
    [ValidateSet(1, 4, 8, 15, 16, 24, 32, 48)]
    [int] $displayColorDepth = 16,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-display-horizontalresolution
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-display-horizontalresolution
    [ValidateRange(640, 1024)]
    [int] $displayHorizontalResolution = 1024,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-display-verticalresolution
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-display-verticalresolution
    [ValidateRange(480, 768)]
    [int] $displayVerticalResolution = 768,

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-display-refreshrate
    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-display-refreshrate
    [ValidateRange(60, 120)]
    [int] $displayRefreshRate = 60,

    [xml] $template = @"
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
      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>$osDiskId</DiskID>
            <PartitionID>$osPartitionId</PartitionID>
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
      <Display>
        <ColorDepth>$displayColorDepth</ColorDepth>
        <HorizontalResolution>$displayHorizontalResolution</HorizontalResolution>
        <RefreshRate>$displayRefreshRate</RefreshRate>
        <VerticalResolution>$displayVerticalResolution</VerticalResolution>
      </Display>
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
      <Display>
        <ColorDepth>$displayColorDepth</ColorDepth>
        <HorizontalResolution>$displayHorizontalResolution</HorizontalResolution>
        <RefreshRate>$displayRefreshRate</RefreshRate>
        <VerticalResolution>$displayVerticalResolution</VerticalResolution>
      </Display>
    </component>
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <fDenyTSConnections>false</fDenyTSConnections>
    </component>
    <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <UserAuthentication>0</UserAuthentication>
    </component>
    <component name="Networking-MPSSVC-Svc" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <FirewallGroups>
        <FirewallGroup wcm:action="add" wcm:keyValue="rd1">
          <Active>true</Active>
          <Group>Remote Desktop</Group>
          <Profile>all</Profile>
        </FirewallGroup>
      </FirewallGroups>
    </component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    </component>
    <component name="Microsoft-Windows-DNS-Client" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <ExtendOSPartition>
        <Extend>$(if ($extendOsPartition) { 'true' } else { 'false' })</Extend>
      </ExtendOSPartition>
      $(if (-not $oobeSystemResealOmit) { ('<Reseal><ForceShutdownNow>{0}</ForceShutdownNow><Mode>{1}</Mode></Reseal>' -f $(if ($oobeSystemResealShutdown) { 'true' } else { 'false' }), $oobeSystemResealMode) })
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <AutoLogon>
        $(if ($autoLogonDomain) { ('<Domain>{0}</Domain>' -f $autoLogonDomain) } else { '<Domain />' })
        <Username>$autoLogonUsername</Username>
        <Password>
          <Value>$(if ($obfuscatePassword) { $encodedAutoLogonPassword } else { ('<![CDATA[{0}]]>' -f $autoLogonPassword) })</Value>
          <PlainText>$(if ($obfuscatePassword) { 'false' } else { 'true' })</PlainText>
        </Password>
        <Enabled>$(if ($autoLogonEnabled) { 'true' } else { 'false' })</Enabled>
        <LogonCount>$autoLogonCount</LogonCount>
      </AutoLogon>
      <OOBE>
        <HideEULAPage>$(if ($hideEULAPage) { 'true' } else { 'false' })</HideEULAPage>
        $(if ($os -ne 'Windows 7') { ('<HideOEMRegistrationScreen>{0}</HideOEMRegistrationScreen>' -f $(if ($hideOEMRegistrationScreen) { 'true' } else { 'false' })) })
        $(if ($os -ne 'Windows 7') { ('<HideOnlineAccountScreens>{0}</HideOnlineAccountScreens>' -f $(if ($hideOnlineAccountScreens) { 'true' } else { 'false' })) })
        <HideWirelessSetupInOOBE>$(if ($hideWirelessSetupInOOBE) { 'true' } else { 'false' })</HideWirelessSetupInOOBE>
        <NetworkLocation>$networkLocation</NetworkLocation>
        <SkipUserOOBE>$(if ($skipUserOOBE) { 'true' } else { 'false' })</SkipUserOOBE>
        <SkipMachineOOBE>$(if ($skipMachineOOBE) { 'true' } else { 'false' })</SkipMachineOOBE>
        <ProtectYourPC>$protectYourPC</ProtectYourPC>
      </OOBE>
      $(if ($os -eq 'Windows 7') { ('<ShowWindowsLive>{0}</ShowWindowsLive>' -f $(if ($showWindowsLive) { 'true' } else { 'false' })) })
      <UserAccounts>
        <AdministratorPassword>
          <Value>$(if ($obfuscatePassword) { $encodedAdministratorPassword } else { ('<![CDATA[{0}]]>' -f $administratorPassword) })</Value>
          <PlainText>$(if ($obfuscatePassword) { 'false' } else { 'true' })</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <RegisteredOrganization>$registeredOrganization</RegisteredOrganization>
      <RegisteredOwner>$registeredOwner</RegisteredOwner>
      $(if ($os -ne 'Windows 7') { ('<DisableAutoDaylightTimeSet>{0}</DisableAutoDaylightTimeSet>' -f $(if ($disableAutoDaylightTimeSet) { 'true' } else { 'false' })) })
      <Display>
        <ColorDepth>$displayColorDepth</ColorDepth>
        <HorizontalResolution>$displayHorizontalResolution</HorizontalResolution>
        <RefreshRate>$displayRefreshRate</RefreshRate>
        <VerticalResolution>$displayVerticalResolution</VerticalResolution>
      </Display>
    </component>
  </settings>
  <settings pass="auditSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <AutoLogon>
        $(if ($autoLogonDomain) { ('<Domain>{0}</Domain>' -f $autoLogonDomain) } else { '<Domain />' })
        <Username>$autoLogonUsername</Username>
        <Password>
          <Value>$(if ($obfuscatePassword) { $encodedAutoLogonPassword } else { ('<![CDATA[{0}]]>' -f $autoLogonPassword) })</Value>
          <PlainText>$(if ($obfuscatePassword) { 'false' } else { 'true' })</PlainText>
        </Password>
        <Enabled>$(if ($autoLogonEnabled) { 'true' } else { 'false' })</Enabled>
        <LogonCount>$autoLogonCount</LogonCount>
      </AutoLogon>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$(if ($obfuscatePassword) { $encodedAdministratorPassword } else { ('<![CDATA[{0}]]>' -f $administratorPassword) })</Value>
          <PlainText>$(if ($obfuscatePassword) { 'false' } else { 'true' })</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      $(if ($os -ne 'Windows 7') { ('<DisableAutoDaylightTimeSet>{0}</DisableAutoDaylightTimeSet>' -f $(if ($disableAutoDaylightTimeSet) { 'true' } else { 'false' })) })
      <Display>
        <ColorDepth>$displayColorDepth</ColorDepth>
        <HorizontalResolution>$displayHorizontalResolution</HorizontalResolution>
        <RefreshRate>$displayRefreshRate</RefreshRate>
        <VerticalResolution>$displayVerticalResolution</VerticalResolution>
      </Display>
    </component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <AuditComputerName>
        <MustReboot>$(if ($auditComputerNameMustReboot) { 'true' } else { 'false' })</MustReboot>
        <Name>$auditComputerName</Name>
      </AuditComputerName>
      <ExtendOSPartition>
        <Extend>$(if ($extendOsPartition) { 'true' } else { 'false' })</Extend>
      </ExtendOSPartition>
      $(if (-not $auditSystemResealOmit) { ('<Reseal><ForceShutdownNow>{0}</ForceShutdownNow><Mode>{1}</Mode></Reseal>' -f $(if ($auditSystemResealShutdown) { 'true' } else { 'false' }), $auditSystemResealMode) })
    </component>
  </settings>
  <settings pass="auditUser">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <RegisteredOrganization>$registeredOrganization</RegisteredOrganization>
      <RegisteredOwner>$registeredOwner</RegisteredOwner>
      <Display>
        <ColorDepth>$displayColorDepth</ColorDepth>
        <HorizontalResolution>$displayHorizontalResolution</HorizontalResolution>
        <RefreshRate>$displayRefreshRate</RefreshRate>
        <VerticalResolution>$displayVerticalResolution</VerticalResolution>
      </Display>
    </component>
    <component name="Microsoft-Windows-Deployment" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      $(if (-not $auditUserResealOmit) {
        ('<Reseal><ForceShutdownNow>{0}</ForceShutdownNow><Mode>{1}</Mode></Reseal>' -f $(if ($auditUserResealShutdown) { 'true' } else { 'false' }), $auditUserResealMode)
      } elseif (-not $generalizeOmit) {
        ('<Generalize><ForceShutdownNow>{0}</ForceShutdownNow><Mode>{1}</Mode></Generalize>' -f $(if ($generalizeShutdown) { 'true' } else { 'false' }), $generalizeMode)
      })
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
      $nsmgr = New-Object System.Xml.XmlNamespaceManager($unattend.NameTable);
      $nsmgr.AddNamespace('ns', 'urn:schemas-microsoft-com:unattend');

      # dns client settings in the specialize settings pass of the Microsoft-Windows-DNS-Client component
      # DNSDomain
      if (($null -ne $dnsDomain) -and (-not [string]::IsNullOrEmpty($dnsDomain))) {
        $xmlDNSDomain = $unattend.CreateElement('DNSDomain', $unattend.DocumentElement.NamespaceURI);
        $xmlDNSDomain.AppendChild($unattend.CreateTextNode($dnsDomain)) | Out-Null;
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-DNS-Client']", $nsmgr).AppendChild($xmlDNSDomain) | Out-Null;
        Write-Log -message ('{0} :: DNSDomain set to {1} in the Microsoft-Windows-DNS-Client component of the specialize settings pass' -f $($MyInvocation.MyCommand.Name), $dnsDomain) -severity 'debug';
      } else {
        Write-Log -message ('{0} :: DNSDomain ommitted from the Microsoft-Windows-DNS-Client component of the specialize settings pass' -f $($MyInvocation.MyCommand.Name)) -severity 'debug';
      }
      # DNSSuffixSearchOrder
      if (($null -ne $dnsSuffixSearchOrder) -and ($dnsSuffixSearchOrder.Length)) {
        $xmlDNSSuffixSearchOrder = $unattend.CreateElement('DNSSuffixSearchOrder', $unattend.DocumentElement.NamespaceURI);
        $xmlDNSSuffixSearchOrderDomainNameKeyValue = 0;
        foreach ($domainName in $dnsSuffixSearchOrder) {
          $xmlDNSSuffixSearchOrderDomainName = $unattend.CreateElement('DomainName', $unattend.DocumentElement.NamespaceURI);
          $xmlDNSSuffixSearchOrderDomainName.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;
          $xmlDNSSuffixSearchOrderDomainName.SetAttribute('keyValue', 'http://schemas.microsoft.com/WMIConfig/2002/State', (++$xmlDNSSuffixSearchOrderDomainNameKeyValue)) | Out-Null;
          $xmlDNSSuffixSearchOrderDomainName.AppendChild($unattend.CreateTextNode($domainName)) | Out-Null;
          $xmlDNSSuffixSearchOrder.AppendChild($xmlDNSSuffixSearchOrderDomainName) | Out-Null;
          Write-Log -message ('{0} :: DomainName: {1} added to DNSSuffixSearchOrder' -f $($MyInvocation.MyCommand.Name), $domainName) -severity 'debug';
        }
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-DNS-Client']", $nsmgr).AppendChild($xmlDNSSuffixSearchOrder) | Out-Null;
        Write-Log -message ('{0} :: {1} domain name{2} added to the DNSSuffixSearchOrder element of the Microsoft-Windows-DNS-Client component in the specialize settings pass' -f $($MyInvocation.MyCommand.Name), $dnsSuffixSearchOrder.Length, $(if ($dnsSuffixSearchOrder.Length -gt 1) { 's' } else { '' })) -severity 'debug';
      } else {
        Write-Log -message ('{0} :: DNSSuffixSearchOrder ommitted from the Microsoft-Windows-DNS-Client component of the specialize settings pass' -f $($MyInvocation.MyCommand.Name)) -severity 'debug';
      }
      # UseDomainNameDevolution
      if ($null -ne $dnsUseDomainNameDevolution) {
        $xmlUseDomainNameDevolution = $unattend.CreateElement('UseDomainNameDevolution', $unattend.DocumentElement.NamespaceURI);
        $xmlUseDomainNameDevolution.AppendChild($unattend.CreateTextNode($(if ($dnsUseDomainNameDevolution) { 'true' } else { 'false' }))) | Out-Null;
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-DNS-Client']", $nsmgr).AppendChild($xmlUseDomainNameDevolution) | Out-Null;
        Write-Log -message ('{0} :: UseDomainNameDevolution set to {1} in the Microsoft-Windows-DNS-Client component of the specialize settings pass' -f $($MyInvocation.MyCommand.Name), $(if ($dnsUseDomainNameDevolution) { 'true' } else { 'false' })) -severity 'debug';
      } else {
        Write-Log -message ('{0} :: UseDomainNameDevolution ommitted from the Microsoft-Windows-DNS-Client component of the specialize settings pass' -f $($MyInvocation.MyCommand.Name)) -severity 'debug';
      }
      # Interfaces
      if (($null -ne $networkInterfaces) -and ($networkInterfaces.Length)) {
        $xmlInterfaces = $unattend.CreateElement('Interfaces', $unattend.DocumentElement.NamespaceURI);
        foreach ($networkInterface in $networkInterfaces) {
          # Interface
          $xmlInterface = $unattend.CreateElement('Interface', $unattend.DocumentElement.NamespaceURI);
          $xmlInterface.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;
          # Identifier
          $xmlInterfaceIdentifier = $unattend.CreateElement('Identifier', $unattend.DocumentElement.NamespaceURI);
          $xmlInterfaceIdentifier.AppendChild($unattend.CreateTextNode($networkInterface.alias)) | Out-Null;
          $xmlInterface.AppendChild($xmlInterfaceIdentifier) | Out-Null;
          Write-Log -message ('{0} :: Identifier set to: {1} for network interface: {2}' -f $($MyInvocation.MyCommand.Name), $networkInterface.alias, $networkInterface.alias) -severity 'debug';
          if ($null -ne $networkInterface.dns) {
            # DNSDomain
            if (($null -ne $networkInterface.dns.domain) -and (-not [string]::IsNullOrEmpty($networkInterface.dns.domain))) {
              $xmlInterfaceDNSDomain = $unattend.CreateElement('DNSDomain', $unattend.DocumentElement.NamespaceURI);
              $xmlInterfaceDNSDomain.AppendChild($unattend.CreateTextNode($networkInterface.dns.domain)) | Out-Null;
              $xmlInterface.AppendChild($xmlInterfaceDNSDomain) | Out-Null;
              Write-Log -message ('{0} :: DNSDomain set to: {1} for network interface: {2}' -f $($MyInvocation.MyCommand.Name), $networkInterface.dns.domain, $networkInterface.alias) -severity 'debug';
            } else {
              Write-Log -message ('{0} :: DNSDomain element omitted for network interface: {1}' -f $($MyInvocation.MyCommand.Name), $networkInterface.alias) -severity 'debug';
            }
            # DNSServerSearchOrder
            if (($null -ne $networkInterface.dns.search) -and ($networkInterface.dns.search.Length)) {
              $xmlInterfaceDNSServerSearchOrder = $unattend.CreateElement('DNSServerSearchOrder', $unattend.DocumentElement.NamespaceURI);
              # IpAddress
              $xmlInterfaceDNSServerSearchOrderIpAddressKeyValue = 0;
              foreach ($dnsIpAddress in $networkInterface.dns.search) {
                $xmlInterfaceDNSServerSearchOrderIpAddress = $unattend.CreateElement('IpAddress', $unattend.DocumentElement.NamespaceURI);
                $xmlInterfaceDNSServerSearchOrderIpAddress.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;
                $xmlInterfaceDNSServerSearchOrderIpAddress.SetAttribute('keyValue', 'http://schemas.microsoft.com/WMIConfig/2002/State', (++$xmlInterfaceDNSServerSearchOrderIpAddressKeyValue)) | Out-Null;
                $xmlInterfaceDNSServerSearchOrderIpAddress.AppendChild($unattend.CreateTextNode($dnsIpAddress)) | Out-Null;
                $xmlInterfaceDNSServerSearchOrder.AppendChild($xmlInterfaceDNSServerSearchOrderIpAddress) | Out-Null;
                Write-Log -message ('{0} :: IpAddress: {1} added with keyValue: {2} to DNSServerSearchOrder for network interface: {3}' -f $($MyInvocation.MyCommand.Name), $dnsIpAddress, $xmlInterfaceDNSServerSearchOrderIpAddressKeyValue, $networkInterface.alias) -severity 'debug';
              }
              $xmlInterface.AppendChild($xmlInterfaceDNSServerSearchOrder) | Out-Null;
              Write-Log -message ('{0} :: {1} ip address{2} added to DNSServerSearchOrder for network interface: {3}' -f $($MyInvocation.MyCommand.Name), $networkInterface.dns.search.Length, $(if ($networkInterface.dns.search.Length -gt 1) { 'es' } else { '' }), $networkInterface.alias) -severity 'debug';
            } else {
              Write-Log -message ('{0} :: DNSServerSearchOrder element omitted for network interface: {1}' -f $($MyInvocation.MyCommand.Name), $networkInterface.alias) -severity 'debug';
            }
            # EnableAdapterDomainNameRegistration
            if ($null -ne $networkInterface.dns.register) {
              $xmlInterfaceEnableAdapterDomainNameRegistration = $unattend.CreateElement('EnableAdapterDomainNameRegistration', $unattend.DocumentElement.NamespaceURI);
              $xmlInterfaceEnableAdapterDomainNameRegistration.AppendChild($unattend.CreateTextNode($(if ($networkInterface.dns.register) { 'true' } else { 'false' }))) | Out-Null;
              $xmlInterface.AppendChild($xmlInterfaceEnableAdapterDomainNameRegistration) | Out-Null;
              Write-Log -message ('{0} :: EnableAdapterDomainNameRegistration set to: {1} for network interface: {2}' -f $($MyInvocation.MyCommand.Name), $(if ($networkInterface.dns.register) { 'true' } else { 'false' }), $networkInterface.alias) -severity 'debug';
            } else {
              Write-Log -message ('{0} :: EnableAdapterDomainNameRegistration element omitted for network interface: {1}' -f $($MyInvocation.MyCommand.Name), $networkInterface.alias) -severity 'debug';
            }
            # DisableDynamicUpdate
            if ($null -ne $networkInterface.dns.dynamic) {
              $xmlInterfaceDisableDynamicUpdate = $unattend.CreateElement('DisableDynamicUpdate', $unattend.DocumentElement.NamespaceURI);
              $xmlInterfaceDisableDynamicUpdate.AppendChild($unattend.CreateTextNode($(if ($networkInterface.dns.dynamic) { 'false' } else { 'true' }))) | Out-Null;
              $xmlInterface.AppendChild($xmlInterfaceDisableDynamicUpdate) | Out-Null;
              Write-Log -message ('{0} :: DisableDynamicUpdate set to: {1} for network interface: {2}' -f $($MyInvocation.MyCommand.Name), $(if ($networkInterface.dns.dynamic) { 'false' } else { 'true' }), $networkInterface.alias) -severity 'debug';
            } else {
              Write-Log -message ('{0} :: DisableDynamicUpdate element omitted for network interface: {1}' -f $($MyInvocation.MyCommand.Name), $networkInterface.alias) -severity 'debug';
            }
          }
          $xmlInterfaces.AppendChild($xmlInterface) | Out-Null;
          Write-Log -message ('{0} :: Interface: {1} added to Interfaces' -f $($MyInvocation.MyCommand.Name), $networkInterface.alias) -severity 'debug';
        }
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-DNS-Client']", $nsmgr).AppendChild($xmlInterfaces) | Out-Null;
        Write-Log -message ('{0} :: {1} network interface configuration{2} added to Microsoft-Windows-DNS-Client component in the specialize settings pass' -f $($MyInvocation.MyCommand.Name), $networkInterfaces.Length, $(if ($networkInterfaces.Length -gt 1) { 's' } else { '' })) -severity 'debug';
      } else {
        Write-Log -message ('{0} :: network interface configuration ommitted from the Microsoft-Windows-DNS-Client component of the specialize settings pass' -f $($MyInvocation.MyCommand.Name)) -severity 'debug';
      }
      # DiskConfiguration
      if (($null -ne $disks) -and ($disks.Length)) {
        $xmlDiskConfiguration = $unattend.CreateElement('DiskConfiguration', $unattend.DocumentElement.NamespaceURI);
        foreach ($disk in $disks) {
          # DiskConfiguration/Disk
          $xmlDisk = $unattend.CreateElement('Disk', $unattend.DocumentElement.NamespaceURI);
          $xmlDisk.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;

          # DiskConfiguration/Disk/DiskID
          $xmlDiskDiskID = $unattend.CreateElement('DiskID', $unattend.DocumentElement.NamespaceURI);
          $xmlDiskDiskID.AppendChild($unattend.CreateTextNode($disk.id)) | Out-Null;
          $xmlDisk.AppendChild($xmlDiskDiskID) | Out-Null;

          # DiskConfiguration/Disk/WillWipeDisk
          $xmlDiskWillWipeDisk = $unattend.CreateElement('WillWipeDisk', $unattend.DocumentElement.NamespaceURI);
          $xmlDiskWillWipeDisk.AppendChild($unattend.CreateTextNode($(if ($disk.wipe) { 'true' } else { 'false' }))) | Out-Null;
          $xmlDisk.AppendChild($xmlDiskWillWipeDisk) | Out-Null;

          # CreatePartitions, ModifyPartitions
          if (($null -ne $disk.partitions) -and ($disk.partitions.Length)) {
            $xmlDiskCreatePartitions = $unattend.CreateElement('CreatePartitions', $unattend.DocumentElement.NamespaceURI);
            $xmlDiskModifyPartitions = $unattend.CreateElement('ModifyPartitions', $unattend.DocumentElement.NamespaceURI);
            foreach ($partition in $disk.partitions) {

              # DiskConfiguration/Disk/CreatePartitions/CreatePartition
              $xmlDiskCreatePartitionsCreatePartition = $unattend.CreateElement('CreatePartition', $unattend.DocumentElement.NamespaceURI);
              $xmlDiskCreatePartitionsCreatePartition.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition
              $xmlDiskModifyPartitionsModifyPartition = $unattend.CreateElement('ModifyPartition', $unattend.DocumentElement.NamespaceURI);
              $xmlDiskModifyPartitionsModifyPartition.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;

              # DiskConfiguration/Disk/CreatePartitions/CreatePartition/Order
              $xmlDiskCreatePartitionsCreatePartitionOrder = $unattend.CreateElement('Order', $unattend.DocumentElement.NamespaceURI);
              $xmlDiskCreatePartitionsCreatePartitionOrder.AppendChild($unattend.CreateTextNode($partition.id)) | Out-Null;
              $xmlDiskCreatePartitionsCreatePartition.AppendChild($xmlDiskCreatePartitionsCreatePartitionOrder) | Out-Null;

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/Order
              $xmlDiskModifyPartitionsModifyPartitionOrder = $unattend.CreateElement('Order', $unattend.DocumentElement.NamespaceURI);
              $xmlDiskModifyPartitionsModifyPartitionOrder.AppendChild($unattend.CreateTextNode($partition.id)) | Out-Null;
              $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskModifyPartitionsModifyPartitionOrder) | Out-Null;

              # DiskConfiguration/Disk/CreatePartitions/CreatePartition/Type
              $xmlDiskPartitionType = $unattend.CreateElement('Type', $unattend.DocumentElement.NamespaceURI);
              $xmlDiskPartitionType.AppendChild($unattend.CreateTextNode($partition.type.name)) | Out-Null;
              $xmlDiskCreatePartitionsCreatePartition.AppendChild($xmlDiskPartitionType) | Out-Null;

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/TypeID
              if ($partition.type.id) {
                $xmlDiskPartitionTypeID = $unattend.CreateElement('TypeID', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionTypeID.AppendChild($unattend.CreateTextNode($partition.type.id)) | Out-Null;
                $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskPartitionTypeID) | Out-Null;
              }

              # DiskConfiguration/Disk/CreatePartitions/CreatePartition/Size
              if ($partition.size) {
                $xmlDiskPartitionSize = $unattend.CreateElement('Size', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionSize.AppendChild($unattend.CreateTextNode($partition.size)) | Out-Null;
                $xmlDiskCreatePartitionsCreatePartition.AppendChild($xmlDiskPartitionSize) | Out-Null;
              }

              # DiskConfiguration/Disk/CreatePartitions/CreatePartition/Extend
              elseif ($partition.extend) {
                $xmlDiskPartitionExtend = $unattend.CreateElement('Extend', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionExtend.AppendChild($unattend.CreateTextNode($(if ($partition.extend) { 'true' } else { 'false' }))) | Out-Null;
                $xmlDiskCreatePartitionsCreatePartition.AppendChild($xmlDiskPartitionExtend) | Out-Null;
              }

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/PartitionID
              $xmlDiskPartitionPartitionID = $unattend.CreateElement('PartitionID', $unattend.DocumentElement.NamespaceURI);
              $xmlDiskPartitionPartitionID.AppendChild($unattend.CreateTextNode($partition.id)) | Out-Null;
              $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskPartitionPartitionID) | Out-Null;

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/Format
              if ($partition.format) {
                $xmlDiskPartitionFormat = $unattend.CreateElement('Format', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionFormat.AppendChild($unattend.CreateTextNode($partition.format)) | Out-Null;
                $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskPartitionFormat) | Out-Null;
              }

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/Label
              if ($partition.label) {
                $xmlDiskPartitionLabel = $unattend.CreateElement('Label', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionLabel.AppendChild($unattend.CreateTextNode($partition.label)) | Out-Null;
                $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskPartitionLabel) | Out-Null;
              }

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/Letter
              if ($partition.letter) {
                $xmlDiskPartitionLetter = $unattend.CreateElement('Letter', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionLetter.AppendChild($unattend.CreateTextNode($partition.letter)) | Out-Null;
                $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskPartitionLetter) | Out-Null;
              }

              # DiskConfiguration/Disk/ModifyPartitions/ModifyPartition/Active
              if ($partition.active) {
                $xmlDiskPartitionActive = $unattend.CreateElement('Active', $unattend.DocumentElement.NamespaceURI);
                $xmlDiskPartitionActive.AppendChild($unattend.CreateTextNode($(if ($partition.active) { 'true' } else { 'false' }))) | Out-Null;
                $xmlDiskModifyPartitionsModifyPartition.AppendChild($xmlDiskPartitionActive) | Out-Null;
              }

              $xmlDiskCreatePartitions.AppendChild($xmlDiskCreatePartitionsCreatePartition) | Out-Null;
              $xmlDiskModifyPartitions.AppendChild($xmlDiskModifyPartitionsModifyPartition) | Out-Null;
              Write-Log -message ('{0} :: {1} Partition added with PartitionID: {2}, to DiskID: {3}' -f $($MyInvocation.MyCommand.Name), $partition.type.name, $partition.id, $disk.id) -severity 'debug';
            }
            $xmlDisk.AppendChild($xmlDiskCreatePartitions) | Out-Null;
            $xmlDisk.AppendChild($xmlDiskModifyPartitions) | Out-Null;
          }
          $xmlDiskConfiguration.AppendChild($xmlDisk) | Out-Null;
          Write-Log -message ('{0} :: Disk added to DiskConfiguration with DiskID: {1}, WillWipeDisk: {2}' -f $($MyInvocation.MyCommand.Name), $disk.id, $(if ($disk.wipe) { 'true' } else { 'false' })) -severity 'debug';
        }
        $unattend.SelectSingleNode("//ns:settings[@pass='windowsPE']/ns:component[@name='Microsoft-Windows-Setup']", $nsmgr).AppendChild($xmlDiskConfiguration) | Out-Null;
        Write-Log -message ('{0} :: {1} disk configuration{2} added to Microsoft-Windows-DNS-Client component in the specialize settings pass' -f $($MyInvocation.MyCommand.Name), $disks.Length, $(if ($disks.Length -gt 1) { 's' } else { '' })) -severity 'debug';
      } else {
        Write-Log -message ('{0} :: disk configuration ommitted from the Microsoft-Windows-Setup component of the windowsPE settings pass' -f $($MyInvocation.MyCommand.Name)) -severity 'debug';
      }

      # unattended commands
      $commandPlacements = @(
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-firstlogoncommands-synchronouscommand
        @{
          'pass' = 'oobeSystem';
          'synchronicity' = 'synchronous';
          'commands' = @($commands | ? { $_.Pass -ieq 'oobeSystem' -and $_.Synchronicity -ieq 'synchronous' });
          'list' = 'FirstLogonCommands';
          'item' = 'SynchronousCommand';
          'command' = 'CommandLine';
          'option' = @{
            'name' = 'RequiresUserInput';
            'default' = 'false'
          };
          'parent' = $unattend.SelectSingleNode("//ns:settings[@pass='oobeSystem']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr)
        },
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-logoncommands-asynchronouscommand
        @{
          'pass' = 'oobeSystem';
          'synchronicity' = 'asynchronous';
          'commands' = @($commands | ? { $_.Pass -ieq 'oobeSystem' -and $_.Synchronicity -ieq 'asynchronous' });
          'list' = 'LogonCommands';
          'item' = 'AsynchronousCommand';
          'command' = 'CommandLine';
          'parent' = $unattend.SelectSingleNode("//ns:settings[@pass='oobeSystem']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr)
        },
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous-runsynchronouscommand
        @{
          'pass' = 'auditUser';
          'synchronicity' = 'synchronous';
          'commands' = @($commands | ? { $_.Pass -ieq 'auditUser' -and $_.Synchronicity -ieq 'synchronous' });
          'list' = 'RunSynchronous';
          'item' = 'RunSynchronousCommand';
          'command' = 'Path';
          'option' = @{
            'name' = 'WillReboot';
            'default' = 'Never'
          };
          'parent' = $unattend.SelectSingleNode("//ns:settings[@pass='auditUser']/ns:component[@name='Microsoft-Windows-Deployment']", $nsmgr)
        },
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runasynchronous-runasynchronouscommand
        @{
          'pass' = 'auditUser';
          'synchronicity' = 'asynchronous';
          'commands' = @($commands | ? { $_.Pass -ieq 'auditUser' -and $_.Synchronicity -ieq 'asynchronous' });
          'list' = 'RunAsynchronous';
          'item' = 'RunAsynchronousCommand';
          'command' = 'Path';
          'parent' = $unattend.SelectSingleNode("//ns:settings[@pass='auditUser']/ns:component[@name='Microsoft-Windows-Deployment']", $nsmgr)
        },
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous-runsynchronouscommand
        @{
          'pass' = 'specialize';
          'synchronicity' = 'synchronous';
          'commands' = @($commands | ? { $_.Pass -ieq 'specialize' -and $_.Synchronicity -ieq 'synchronous' });
          'list' = 'RunSynchronous';
          'item' = 'RunSynchronousCommand';
          'command' = 'Path';
          'option' = @{
            'name' = 'WillReboot';
            'default' = 'Never'
          };
          'parent' = $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Deployment']", $nsmgr)
        },
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runasynchronous-runasynchronouscommand
        @{
          'pass' = 'specialize';
          'synchronicity' = 'asynchronous';
          'commands' = @($commands | ? { $_.Pass -ieq 'specialize' -and $_.Synchronicity -ieq 'asynchronous' });
          'list' = 'RunAsynchronous';
          'item' = 'RunAsynchronousCommand';
          'command' = 'Path';
          'parent' = $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Deployment']", $nsmgr)
        }
      );
      foreach ($commandPlacement in $commandPlacements) {
        if ($commandPlacement.commands -and $commandPlacement.commands.Length) {
          $xmlCommandList = $unattend.CreateElement($commandPlacement.list, $unattend.DocumentElement.NamespaceURI);
          # arrays of hashtables require slightly more complex sorting definitions (see: https://stackoverflow.com/a/37034736/68115)
          $passCommands = @($commandPlacement.commands | Sort-Object -Property @{ 'Expression' = { $_.Priority }; 'Descending' = $false });
          $order = 0;
          foreach ($command in $passCommands) {
            $xmlCommandElement = $unattend.CreateElement($commandPlacement.item, $unattend.DocumentElement.NamespaceURI);
            $xmlCommandElement.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;
            $xmlCommandElementChildren = @(
              @{
                'name' = 'Order';
                'value' = ++$order
              },
              @{
                'name' = 'Description';
                'value' = $command['Description']
              },
              @{
                'name' = $commandPlacement.command;
                'value' = $command['CommandLine']
              }
            );
            if ($commandPlacement.option -and $commandPlacement.option.name -and $commandPlacement.option.default) {
              $xmlCommandElementChildren += @{
                'name' = $commandPlacement.option.name;
                'value' = $(if ($command[$commandPlacement.option.name]) { $command[$commandPlacement.option.name] } else { $commandPlacement.option.default })
              };
            }
            foreach ($xmlCommandElementChild in $xmlCommandElementChildren) {
              $xmlCommandElementChildElement = $unattend.CreateElement($xmlCommandElementChild['name'], $unattend.DocumentElement.NamespaceURI);
              $xmlCommandElementChildElement.AppendChild($unattend.CreateTextNode($xmlCommandElementChild['value'])) | Out-Null;
              $xmlCommandElement.AppendChild($xmlCommandElementChildElement) | Out-Null;
            }
            $xmlCommandList.AppendChild($xmlCommandElement) | Out-Null;
            if ($commandPlacement.option -and $commandPlacement.option.name -and $commandPlacement.option.default) {
              Write-Log -message ('{0} :: {1} command with priority {2} added to {3} settings pass ({4}/{5}[{6}] (with attribute {7}: {8})): {9}' -f $($MyInvocation.MyCommand.Name), $commandPlacement.synchronicity, $command['Priority'], $commandPlacement.pass, $commandPlacement.list, $commandPlacement.item, $order, $commandPlacement.option.name, $(if ($command[$commandPlacement.option.name]) { $command[$commandPlacement.option.name] } else { $commandPlacement.option.default }), $command['Description']) -severity 'debug';
            } else {
              Write-Log -message ('{0} :: {1} command with priority {2} added to {3} settings pass ({4}/{5}[{6}]): {7}' -f $($MyInvocation.MyCommand.Name), $commandPlacement.synchronicity, $command['Priority'], $commandPlacement.pass, $commandPlacement.list, $commandPlacement.item, $order, $command['Description']) -severity 'debug';
            }
          }
          $commandPlacement.parent.AppendChild($xmlCommandList) | Out-Null;
          Write-Log -message ('{0} :: {1} added to {2} settings pass' -f $($MyInvocation.MyCommand.Name), $commandPlacement.list, $commandPlacement.pass) -severity 'debug';
        } else {
          Write-Log -message ('{0} :: no {1} commands detected for {2} settings pass' -f $($MyInvocation.MyCommand.Name), $commandPlacement.synchronicity, $commandPlacement.pass) -severity 'debug';
        }
      }
      # todo: move logic below into template
      if (($os -ne 'Windows 7') -or (($os -eq 'Windows 7') -and (-not $enableRDP))) {
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']", $nsmgr).RemoveChild($unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-TerminalServices-LocalSessionManager']", $nsmgr)) | Out-Null;
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']", $nsmgr).RemoveChild($unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-TerminalServices-RDP-WinStationExtensions']", $nsmgr)) | Out-Null;
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']", $nsmgr).RemoveChild($unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Networking-MPSSVC-Svc']", $nsmgr)) | Out-Null;
      }
      if (-not $computerName) {
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr).RemoveChild($unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']/ns:ComputerName", $nsmgr)) | Out-Null;
      }
      if (-not $productKey) {
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr).RemoveChild($unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']/ns:ProductKey", $nsmgr)) | Out-Null;
      }
      if (-not $timeZone) {
        $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr).RemoveChild($unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']/ns:TimeZone", $nsmgr)) | Out-Null;
      }
      $unattend.Save($destinationPath) | Out-Null;
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
    Write-Log -message ('{0} :: begin - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace' -supressOutput:$true;
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
    Write-Log -message ('{0} :: end - {1:o}' -f $($MyInvocation.MyCommand.Name), (Get-Date).ToUniversalTime()) -severity 'trace' -supressOutput:$true;
  }
}