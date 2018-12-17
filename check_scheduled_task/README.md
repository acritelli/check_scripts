# check_scheduled_task

Script for checking whether or not a scheduled task ran successfully.

## Usage

For complete usage information, check the help: `Get-Help ./check_scheduled_task.ps1 -Full`

### Default behavior

By default, the script will check for a specified scheduled task and return OK (0) if the last task run was successful (exit code 0) or CRITICAL (2) if the last task run was something other than 0. It will exit UNKNOWN (3) if it is unable to get the task info (i.e. a call to `Get-ScheduledTask $TaskName -ErrorAction SilentlyContinue | Get-ScheduledTaskInfo` fails).

To call the script with defaults, invoke it with only the `-TaskName` argument:

```
PS C:\scripts> .\check_scheduled_task.ps1 -TaskName sih
OK |
```

```
PS C:\scripts> .\check_scheduled_task.ps1 -TaskName "A Task That Failed"
CRITICAL exit code for A Task That Failed was 2147942402, expected 0 |
```

### Changing the valid exit code

To change the valid exit code to something other than 0, simply pass in the number to `-TaskResult`:

```
PS C:\scripts> .\check_scheduled_task.ps1 -TaskName "A Task That Failed" - TaskResult 2147942402
OK |
```

### Returning WARNING instead of CRITICAL

To return a warning instead of critical alert, simply set `-warnOnly` to `$true`:

```
PS C:\scripts> .\check_scheduled_task.ps1 -TaskName "A Task That Failed"
WARNING exit code for A Task That Failed was 2147942402, expected 0 |
```

### Performance Data

This script does not produce performance data.