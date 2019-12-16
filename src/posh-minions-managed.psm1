function Write-Log {
  <#
  .SYNOPSIS
    Write a log message to the windows event log and powershell verbose stream

  .DESCRIPTION
    This function takes a log message and writes it to the windows event log as well as the powershell verbose stream.
    If the specified logName or source are missing from the windows event log, they are created.

  .PARAMETER  message
    The message parameter is the log message to be recorded to the event log

  .PARAMETER  severity
    The logging severity is the severity rating for the message being recorded.
    There are five ratings:
    - trace: verbose messages about state observations for tracing purposes
    - debug: verbose messages about state observations for debugging purposes
    - info: normal messages about state changes
    - warn: messages about unexpected occurences or observations that are not fatal to the running of the application
    - error: messages about failure of a critical logic path in the application

  .PARAMETER  source
    The optional source parameter maps directly to the required event log source.
    This should be set to the name of the application being logged.

  .PARAMETER  logName
    The optional logName parameter maps directly to the required event log logName.
    Most logs should go to the 'Application' pool

  .EXAMPLE
    These examples show how to call the Write-Log function with named parameters.
    PS C:\> Write-Log -message 'look at the rainbow!.' -severity 'trace' -source 'AmazingDaysApp'
    PS C:\> Write-Log -message 'the sun is shining, the weather is sweet.' -severity 'debug' -source 'AmazingDaysApp'
    PS C:\> Write-Log -message 'it has started to rain. an umbrella has been provided.' -severity 'info' -source 'AmazingDaysApp'
    PS C:\> Write-Log -message 'thunder and lightning, very, very frightening.' -severity 'warn' -source 'AmazingDaysApp'
    PS C:\> Write-Log -message 'you are snowed in. the door is jammed shut.' -severity 'error' -source 'AmazingDaysApp'

  .NOTES

  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string] $message,

    [ValidateSet('trace', 'debug', 'info', 'warn', 'error')]
    [string] $severity = 'debug',

    [ValidateRange(1, 65535)]
    [int] $eventId = $(
      switch ($severity) {
        'trace' {
          13371
        }
        'debug' {
          13373
        }
        'info' {
          13375
        }
        'warn' {
          13377
        }
        'error' {
          13379
        }
      }
    ),

    [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
    [string] $entryType = $(
      switch ($severity) {
        'trace' {
          'SuccessAudit'
        }
        'debug' {
          'SuccessAudit'
        }
        'info' {
          'Information'
        }
        'warn' {
          'FailureAudit'
        }
        'error' {
          'Error'
        }
      }
    ),

    [string] $source = 'posh-minions-managed',

    [string] $logName = 'Application'
  )
  begin {
    $platformSupported = $true;
    try {
      if ((-not ([System.Diagnostics.EventLog]::Exists($logName))) -or (-not ([System.Diagnostics.EventLog]::SourceExists($source)))) {
        try {
          New-EventLog -LogName $logName -Source $source
        } catch {
          Write-Error -Exception $_.Exception -message ('failed to create event log source: {0}/{1}' -f $logName, $source)
        }
      }
    } catch [PlatformNotSupportedException] {
      $platformSupported = $false;
    } catch [System.Security.SecurityException] {
      try {
        New-EventLog -LogName $logName -Source $source
      } catch {
      }
    }
  }
  process {
    if ($platformSupported) {
      try {
        Write-EventLog -LogName $logName -Source $source -EntryType $entryType -EventId $eventId -Message $message
        Write-Output -InputObject ('[{0} {1}] {2}' -f $severity, (Get-Date).ToUniversalTime(), $message);
      } catch {
        Write-Verbose -Message ('failed to write to event log source: {0}/{1}. the log message was: {2}. the exception message was: {3}' -f $logName, $source, $message, $_.Exception.Message)
      }
    } else {
      Write-Host -object ('[{0} {1}] {2}' -f $severity, (Get-Date).ToUniversalTime(), $message) -ForegroundColor @{ 'info' = 'White'; 'error' = 'Red'; 'warn' = 'DarkYellow'; 'debug' = 'DarkGray'; 'trace' = 'DarkGray' }[$severity]
    }
  }
  end {
    Write-Verbose -Message $message
  }
}