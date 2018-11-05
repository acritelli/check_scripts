<#

.SYNOPSIS

This script checks and displays information about available WSUS updates

.DESCRIPTION

check_wsus_updates checks and displays information about available updates on a WSUS server. It is designed to be used with monitoring systems such as nagios. The checks performed by this script provide nagios-compliant outputs.

.PARAMETER Server
  The WSUS server to contact

.PARAMETER Port
The port to reach the WSUS server

.PARAMETER PerformanceData
A string array containing the performance data that should be printed based on update classification, as seen in the Get-WsusClassification command. By default, performance data is only printed for security and critical updates. Passing in an array will override this behavior and only print performance data for the classifications in the provided array.

.PARAMETER SecurityOnly
If set to $TRUE, then critical updates will not throw an alert. Only security updates will throw an alert, which will be a critical alert.

#>

param (
  [string]$Server = 'localhost',
  [int32]$Port = 8530,
  [string[]]$PerformanceData = @('Security Updates', 'Critical Updates'),
  [boolean]$SecurityOnly = $FALSE
)

$wsusServer = Get-WsusServer -Name $Server -PortNumber $Port
$updates = Get-WsusUpdate -UpdateServer $wsusServer -Approval Unapproved -Status FailedOrNeeded
$totalUpdates = 0
$updatesToApprove = 0
$outputMessage = ''
$exitCode = 0

# Initialize all the types of updates available
$classApplications = $classCriticalUpdates = $classDefinitionUpdates = $classDriverSets = $classDrivers = $classFeaturePacks = $classSecurityUpdates = $classServicePacks = $classTools = $classUpdateRollups = $classUpdates = $classUpgrades = 0


$updates | ForEach-Object -Process {
  $totalUpdates += 1

  # Updates to approve are defined as any updates that are not superseded AND that are needed by computers
  if($_.UpdatesSupersedingThisUpdate -eq 'None' -and $_.ComputersNeedingThisUpdate -gt 0) {
    $updatesToApprove += 1
  }

  Switch ($_.Classification) {
    'Application' { $classApplications += 1 }
    'Critical Updates' { $classCriticalUpdates += 1 }
    'Definition Updates' { $classDefinitionUpdates += 1 }
    'Driver Sets' { $classDriverSets += 1 }
    'Drivers' { $classDrivers += 1 }
    'Feature Packs' { $classFeaturePacks += 1 }
    'Security Updates' { $classSecurityUpdates += 1 }
    'Service Packs' { $classServicePacks += 1 }
    'Tools' { $classTools += 1 }
    'Update Rollups' { $classUpdateRollups += 1 }
    'Updates' { $classUpdates += 1}
    'Upgrades' { $classUpgrades += 1 }
    
  }
}

# Any unapproved security updates will result in critical
if($classSecurityUpdates -gt 0) {
  $outputMessage +=  "CRITICAL: $classSecurityUpdates Security Updates Unapproved | "
  $exitCode = 2
} elseif ($classCriticalUpdates -gt 0) {
  # Return OK if user only cared about security updates, else return warning if any critical updates exist
  if ($SecurityOnly) {
    $outputMessage += "OK: $classCriticalUpdates Critical Updates Unapproved | "
    $exitCode = 0
  } else {
    $outputMessage += "WARNING: $classCriticalUpdates Critical Updates Unapproved | "
    $exitCode = 1
  }
} else {
  $outputMessage += "OK | "
  $exitCode = 0
}

# Add performance data for total updates and updates to install
$outputMessage += "'Total Updates'=${totalUpdates} "
$outputMessage += "'Updates to Approve'=${updatesToApprove} "

# Write performance data based on PerformanceData command line arg
$PerformanceData | ForEach-Object -Process {
  Switch ($_) {
    'Applications' { $outputMessage += "'Application'=${classApplications} " }
    'Critical Updates' { $outputMessage += "'Critical Updates'=${classCriticalUpdates} " }
    'Definition Updates' { $outputMessage += "'Definition Updates'=${classDefinitionUpdates} " }
    'Driver Sets' { $outputMessage += "'Driver Sets'=${classDriverSets} " }
    'Drivers' { $outputMessage += "'Drivers'=${classDrivers} " }
    'Feature Packs' { $outputMessage += "'Feature Packs'=${classFeaturePacks} " }
    'Security Updates' { $outputMessage += "'Security Updates'=${classSecurityUpdates} " }
    'Service Packs' { $outputMessage += "'Service Packs'=${classServicePacks} " }
    'Tools' { $outputMessage += "'Tools'=${classTools} " }
    'Update Rollups' { $outputMessage += "'Update Rollups'=${classUpdateRollups} " }
    'Updates' { $outputMessage += "'Updates'=${classUpdates}" }
    'Upgrades' {  $outputMessage += "'Upgrades'=${classUpgrades} " }
  }
}

Write-Host $outputMessage
Exit $exitCode