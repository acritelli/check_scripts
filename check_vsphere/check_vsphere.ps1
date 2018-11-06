<#

.SYNOPSIS

This script checks and displays CPU and memory information about VMWare clusters and hosts.

.DESCRIPTION

check_vsphere checks and displays information about CPU and memory information in either a vSphere cluster or individual host. It is designed to be used with monitoring systems such as Nagios. The checks performed by this script provide Nagios compliant outputs.

.PARAMETER Cluster

The name of the cluster to gather performance information about. Only necessary if -Mode is set to Cluster (the default).

.PARAMETER CredentialFile

The path to a file that contains a secure string encrypted password for vCenter credentials. Used with -Username

This can be created using the following command:
Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File C:\mycredentials.txt

.PARAMETER Critical

The critical threshold

.PARAMETER Metric

The metric to collect and check (CPU or Memory)

.PARAMETER Mode

Indicates whether performance data is collected for a cluster or a host. Defaults to cluster. If cluster (the default) is specified, then -Cluster must be specified. If host is specified, then -VMHost must be specified.

.PARAMETER Password

A password for connecting to vCenter

.PARAMETER Server

Mandatory. The vCenter server to connect to.

.PARAMETER ShowPercentUsed

Controls whether percent used performance data is printed.

.PARAMETER ShowPercentFree

Controls whether percent free performance data is printed.

.PARAMETER ShowRawUsed

Controls whether raw used performance data is printed.

.PARAMETER ShowRawFree

Controls whether raw free performance data is printed.

.PARAMETER ThresholdType

The type of threshold to check (percent used/free, raw used/free). Defaults to percent used.

.PARAMETER Username

The username for vCenter credentials. Used with -CredentialFile

.PARAMETER VMHost
The name of the host to gather performance information about. Only necessary if -Mode is set to Host.

.PARAMETER Warning

The warning threshold

#>
param(
  [string]$Cluster,
  [string]$CredentialFile,
  [string]$Critical = 75,
  [ValidateSet("CPU", "Memory")][string]$Metric = 'CPU',
  [ValidateSet("Cluster","Host")][string]$Mode = 'Cluster',
  [string]$Password, # Included for compatibility with Powershell on Linux
  [Parameter(Mandatory=$true)][string]$Server,
  [boolean]$ShowPercentUsed = $true,
  [boolean]$ShowPercentFree = $true,
  [boolean]$ShowRawUsed = $true,
  [boolean]$ShowRawFree = $true,
  [ValidateSet("PercentUsed","PercentFree","RawUsed","RawFree")][string]$ThresholdType = 'PercentUsed',
  [string]$Username,
  [string]$VMHost,
  [string]$Warning = 60
)

$totalCPU
$usedCPU
$totalMemory
$usedMemory


# Connect using provided credentials, else assume that we're binding with logged in user
if($Username -and $CredentialFile) {
  $password = Get-Content $CredentialFile | ConvertTo-SecureString
  $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $password
  Connect-VIServer -Server $Server -Credential $Credential | Out-Null
} elseif($Username -and $Password) {
  Connect-VIServer -Server $Server -Username $Username -Password $Password | Out-Null
} else {
  Connect-VIServer -Server $Server | Out-Null
}

if($Mode -eq 'Cluster' -and -not $Cluster) {
  Write-Error "The name of the cluster must be specified with the -Cluster parameter."
  Exit 3
} elseif($Mode -eq 'Host' -and -not $VMHost) {
  Write-Error "The name of the host must be specified with the -VMHost parameter."
  Exit 3
}

Switch($Mode) {

  'Cluster' {
    Get-VMHost -Location $Cluster | ForEach-Object -Process {
      $totalCPU += $_.CpuTotalMhz
      $usedCPU += $_.CpuUsageMhz
      $totalMemory += $_.MemoryTotalGB
      $usedMemory += $_.MemoryUsageGB
    }
  }

  'Host' {
    $esxHost = Get-VMHost -Name $VMHost
    $totalCPU = $esxHost.CpuTotalMhz
    $usedCPU = $esxHost.CpuUsageMhz
    $totalMemory = $esxHost.MemoryTotalGB
    $usedMemory = $esxHost.MemoryUsageGB
  }

}

$metricRawTotal
$metricRawUsed
$metricRawFree
$metricPercentFree
$metricPercentUsed
$metricUnit

Switch($Metric) {

  'CPU' {
    $Metric = 'CPU' # Fix case insensitivity
    $metricRawTotal = $totalCPU
    $metricRawUsed = $usedCPU
    $metricUnit = 'GHz'
  }

  'Memory' {
    $Metric = 'Memory' # Fix case insensitivity
    $metricRawTotal = $totalMemory
    $metricRawUsed = $usedMemory
    $metricUnit = "GB"
  }

}

$metricRawFree = $metricRawTotal - $metricRawUsed
$metricPercentUsed = $metricRawUsed / $metricRawTotal * 100
$metricPercentFree = ($metricRawTotal - $metricRawUsed) / $metricRawTotal * 100

$outputMessage = 'OK' # Printed to stdout, OK is overridden if needed
$exitCode # Script exit code

#TODO: handle ranges
Switch($ThresholdType) {
  'PercentUsed' {

    if($metricPercentUsed -ge $Critical) {
      $outputMessage = "CRITICAL: $metricPercentUsed% $Metric Used"
      $exitCode = 2
    } elseif ($metricPercentUsed -ge $Warning) {
      $outputMessage = "WARNING: $metricPercentUsed% $Metric Used"
      $exitCode = 1
    }

  }

  'PercentFree' {

    if($metricPercentFree -le $Critical) {
      $outputMessage = "CRITICAL: $metricPercentFree% $Metric Free"
      $exitCode = 2
    } elseif($metricPercentFree -le $Warning) {
      $outputMessage = "WARNING: $metricPercentFree% $Metric Free"
      $exitCode = 1
    }

  }

  'RawUsed' {

    if($metricRawUsed -ge $Critical) {
      $outputMessage = "CRITICAL: $metricRawUsed$metricUnit $Metric Used"
      $exitCode = 2
    } elseif ($metricRawUsed -ge $Warning) {
      $outputMessage = "WARNING: $metricRawUsed$metricUnit $Metric Used"
      $exitCode = 1
    }

  }

  'RawFree' {

    if($metricRawFree -le $Critical) {
      $outputMessage = "CRITICAL: $metricRawFree$metricUnit $Metric Free"
      $exitCode = 2
    } elseif ($metricRawFree -le $Warning) {
      $outputMessage = "WARNING: $metricRawFree$metricUnit $Metric Free"
      $exitCode = 1
    }

  }

}

$outputMessage += ' | ' # Append the separator for performance data

# Output performance data based on command flags
if($ShowRawUsed){
  if($ThresholdType -eq 'RawUsed') {
    $outputMessage += "'$Metric Used'=$metricRawUsed$metricUnit;$Warning;$Critical;0;$metricRawTotal "
  } else {
    $outputMessage += "'$Metric Used'=$metricRawUsed$metricUnit;;;0;$metricRawTotal "
  }
}

if($ShowRawFree){
  if($ThresholdType -eq 'RawFree') {
    $outputMessage += "'$Metric Free'=$metricRawFree$metricUnit;$Warning;$Critical;0;$metricRawTotal "
  } else {
    $outputMessage += "'$Metric Free'=$metricRawFree$metricUnit;;;0;$metricRawTotal "
  }
}

if($ShowPercentUsed) {
  if($ThresholdType -eq 'PercentUsed') {
    $outputMessage += "'$Metric Pct Used'=$metricPercentUsed%;$Warning;$Critical;0;100 "
  } else {
    $outputMessage += "'$Metric Pct Used'=$metricPercentUsed%;;;0;100 "
  }
}

if($ShowPercentFree) {
  if($ThresholdType -eq 'PercentFree') {
    $outputMessage += "'$Metric Pct Free'=$metricPercentFree%;$Warning;$Critical;0;100 "
  } else {
    $outputMessage += "'$Metric Pct Free'=$metricPercentFree%;;;0;100 "
  }
}

Write-Host $outputMessage
Exit $exitCode