<#

.SYNOPSIS

This script checks to see if a scheduled task ran successfully.

.DESCRIPTION

check_scheduled_task checks the return value of a scheduled task (from Task Scheduler) and indicates if it ran successfully or not. By default, it will throw a critical error if the specified task returns anything other than a 0 exit code.

.PARAMETER TaskName

The name of the scheduled task to check

.PARAMETER TaskResult

The task result exit code that represents a successful run. Defaults to 0.

.PARAMETER WarnOnly

Changes the behavior to warn instead of alert critical

#>

param (
  [Parameter(Mandatory=$true)][string]$TaskName,
  [string]$TaskResult = 0,
  [bool]$WarnOnly = $false
)

$outputMessage = ''
$exitCode = 0

$taskInfo = Get-ScheduledTask $TaskName -ErrorAction SilentlyContinue | Get-ScheduledTaskInfo

# If we got back a task and its info, then set the output and return successfully
if($taskInfo) {
  if($taskInfo.LastTaskResult -ne $TaskResult) {
    if($WarnOnly) {
      $outputMessage += 'WARNING '
      $exitCode = 1
    } else {
      $outputMessage += 'CRITICAL '
      $exitCode = 2
    }

    $outputMessage += "exit code for $TaskName was $($taskInfo.LastTaskResult), expected $TaskResult |"
  } else {
    $outputMessage += "OK |"
  }
} else {
  # Otherwise, exit with an error
  $outputMessage += "UNKNOWN Attempt to get scheduled task info failed |"
  $exitCode = 3
}


Write-Host $outputMessage
Exit $exitCode