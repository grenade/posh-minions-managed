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

    # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-useraccounts-administratorpassword
    [string] $administratorPassword = (New-Password),
    [string] $encodedAdministratorPassword = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes([string]::Join('', @([char[]]('{0}AdministratorPassword' -f $administratorPassword) | % { '{0}{1}' -f $_, [char]0x00 })))),

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

    [Parameter(Mandatory = $true)]
    [ValidateSet('Windows 7', 'Windows 10', 'Windows Server 1903', 'Windows Server 1909', 'Windows Server 2012 R2', 'Windows Server 2016', 'Windows Server 2019')]
    [string] $os,

    [switch] $obfuscatePassword = $false,

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
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="$processorArchitecture" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <AutoLogon>
        <Password>
          <Value>$(if ($obfuscatePassword) { $encodedAdministratorPassword } else { $administratorPassword })</Value>
          <PlainText>$(if ($obfuscatePassword) { 'false' } else { 'true' })</PlainText>
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
      <ShowWindowsLive>$(if ($showWindowsLive) { 'true' } else { 'false' })</ShowWindowsLive>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$(if ($obfuscatePassword) { $encodedAdministratorPassword } else { $administratorPassword })</Value>
          <PlainText>$(if ($obfuscatePassword) { 'false' } else { 'true' })</PlainText>
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

      $nsmgr = New-Object System.Xml.XmlNamespaceManager($unattend.NameTable);
      $nsmgr.AddNamespace('ns', 'urn:schemas-microsoft-com:unattend');
      $oobeSystemMicrosoftWindowsShellSetup = $unattend.SelectSingleNode("//ns:settings[@pass='oobeSystem']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr);
      $specializeMicrosoftWindowsShellSetup = $unattend.SelectSingleNode("//ns:settings[@pass='specialize']/ns:component[@name='Microsoft-Windows-Shell-Setup']", $nsmgr);

      $order = 0;
      $flc = $unattend.CreateElement('FirstLogonCommands', $unattend.DocumentElement.NamespaceURI);
      foreach ($command in $commands) {
        $sc = $unattend.CreateElement('SynchronousCommand', $unattend.DocumentElement.NamespaceURI);
        $sc.SetAttribute('action', 'http://schemas.microsoft.com/WMIConfig/2002/State', 'add') | Out-Null;
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
          $se.AppendChild($unattend.CreateTextNode($scSub['value'])) | Out-Null;
          $sc.AppendChild($se) | Out-Null;
        }
        $flc.AppendChild($sc) | Out-Null;
      }
      $oobeSystemMicrosoftWindowsShellSetup.AppendChild($flc) | Out-Null;
      if ($os -eq 'Windows 7') {
        $oobeNode = $oobeSystemMicrosoftWindowsShellSetup.SelectSingleNode('./ns:OOBE', $nsmgr);
        $oobeNode.RemoveChild($oobeNode.SelectSingleNode('./ns:HideOEMRegistrationScreen', $nsmgr)) | Out-Null;
        $oobeNode.RemoveChild($oobeNode.SelectSingleNode('./ns:HideOnlineAccountScreens', $nsmgr)) | Out-Null;
        $oobeSystemMicrosoftWindowsShellSetup.RemoveChild($oobeSystemMicrosoftWindowsShellSetup.SelectSingleNode('./ns:DisableAutoDaylightTimeSet', $nsmgr)) | Out-Null;
      } else {
        $oobeSystemMicrosoftWindowsShellSetup.RemoveChild($oobeSystemMicrosoftWindowsShellSetup.SelectSingleNode('./ns:ShowWindowsLive', $nsmgr)) | Out-Null;
      }
      if (($os -ne 'Windows 7') -or (($os -eq 'Windows 7') -and (-not $enableRDP))) {
        $specializeSettingsPass = $unattend.SelectSingleNode("//ns:settings[@pass='specialize']", $nsmgr);
        $specializeSettingsPass.RemoveChild($specializeSettingsPass.SelectSingleNode("./ns:component[@name='Microsoft-Windows-TerminalServices-LocalSessionManager']", $nsmgr)) | Out-Null;
        $specializeSettingsPass.RemoveChild($specializeSettingsPass.SelectSingleNode("./ns:component[@name='Microsoft-Windows-TerminalServices-RDP-WinStationExtensions']", $nsmgr)) | Out-Null;
        $specializeSettingsPass.RemoveChild($specializeSettingsPass.SelectSingleNode("./ns:component[@name='Networking-MPSSVC-Svc']", $nsmgr)) | Out-Null;
      }
      if (-not $computerName) {
        $specializeMicrosoftWindowsShellSetup.RemoveChild($specializeMicrosoftWindowsShellSetup.SelectSingleNode('./ns:ComputerName', $nsmgr)) | Out-Null;
      }
      if (-not $productKey) {
        $specializeMicrosoftWindowsShellSetup.RemoveChild($specializeMicrosoftWindowsShellSetup.SelectSingleNode('./ns:ProductKey', $nsmgr)) | Out-Null;
      }
      if (-not $timeZone) {
        $specializeMicrosoftWindowsShellSetup.RemoveChild($specializeMicrosoftWindowsShellSetup.SelectSingleNode('./ns:TimeZone', $nsmgr)) | Out-Null;
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