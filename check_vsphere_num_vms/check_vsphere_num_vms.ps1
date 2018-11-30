<#

.SYNOPSIS

This script checks the number of VMs in a vSphere location (cluster, resource pool, or host). Optionally, it can alert warning or critical based on threshold values.

.DESCRIPTION

check_vsphere_num_vms checks and displays information about the number of VMs that are currently running in a vSphere environment. The check can provide information about the number of VMs running on an individual host, within a particular cluster, or in a resource pool. By default, the check will always exit OK. Specifying the optional Warning or Critical parameters will cause the script to exit with the appropriate alert code if the number of VMs exceed the specified threshold.

.PARAMETER Cluster

The name of the cluster to check. If specified, Datacenter, ResourcePool and VMHost should not be specified.

.PARAMETER CredentialFile

The path to a file that contains a secure string encrypted password for vCenter credentials. Used with -Username

This can be created using the following command:
Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File C:\mycredentials.txt

.PARAMETER Critical

The critical threshold

.PARAMETER Datacenter

The namae of the datacenter to check. If specified, Cluster, ResourcePool, and VMHost should not be specified.

.PARAMETER Password

A password for connecting to vCenter

.PARAMETER ResourcePool

The name of the resource pool to check. If specified, Cluster, Datacenter and VMHost should not be specified.

.PARAMETER Server

Mandatory. The vCenter server to connect to.

.PARAMETER Username

The username for vCenter credentials. Used with -CredentialFile

.PARAMETER VMHost
The name of the host to check. If specified, Cluster, Datacenter, and ResourcePool should not be specified.

.PARAMETER Warning

The warning threshold

#>
param(
  [string]$Cluster,
  [string]$CredentialFile,
  [string]$Critical,
  [string]$Datacenter,
  [string]$Password, # Included for compatibility with Powershell on Linux
  [string]$ResourcePool,
  [Parameter(Mandatory=$true)][string]$Server,
  [string]$Username,
  [string]$VMHost,
  [string]$Warning
)

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

# Get the location based on the provided flags
if($Cluster) {
  $location = Get-Cluster $Cluster
} elseif($ResourcePool) {
  $location = Get-ResourcePool $ResourcePool
} elseif($VMHost) {
  $location = Get-VMHost $VMHost
} elseif($Datacenter) {
  $location = Get-Datacenter $Datacenter
} else {
  Write-Output "UNKNOWN No location specified"
  Exit 3
}

$numVms = Get-VM -Location $location | Measure-Object | Select-Object -ExpandProperty Count

if($Critical -and ($numVms -ge $Critical)) {
  Write-Output "CRITICAL: $numVms total VMs | Total VMs=$numVms;$Warning;$Critical;0;"
  Exit 2
}

if($Warning -and ($numVms -ge $Warning)) {
  Write-Output "WARNING: $numVms total VMs | Total VMs=$numVms;$Warning;$Critical;0;"
  Exit 1
}

Write-Output "OK: $numVms total VMs | Total VMs=$numVms;$Warning;$Critical;0;"
Exit 0