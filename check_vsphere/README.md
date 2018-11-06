# check_vsphere

Script for checking CPU and Memory utilization in vSphere clusters or hosts

## Usage

For complete usage information, check the help: `Get-Help ./check_vsphere.ps1 -Full`

check_vsphere is able to check for raw percentage value CPU and memory statistics, alert using Nagios compliant exit codes, and provide Nagios formatted performance data.

### Connecting to vCenter

Before the script can do anything, it must be connected to vCenter. If you're on a Windows domain bound computer and your user has vCenter access, then the script will simply call `Get-VIServer` with your logged in credentials.

If you need to specify credentials, then you will have to create a password file using the command below:

`Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File C:\mycredentials.txt`

Once the credential file has been created, the credentials can be passed to the script:

`./check_vsphere -Server vcenter.example.com -Username user@vsphere.local -CredentialFile C:\mycredentials.txt <additional arguments>`

### Mode

The `-Mode` paramter indicates whether the script should run against a cluster or a host.

If `-Mode Cluster` is specified, then you must also specify the cluster name with the `-Cluster` parameter. For example:

`./check_vsphere -Server vcenter.example.com -Mode Cluster -Cluster "Production"`

If `-Mode Host` is specified, then you must also specify the name of the host in vCenter with the `-VMHost` parameter. For example:

`./check_vsphere -Server vcenter.example.com -Mode Host -VMHost vmwhost01.example.com`

### Metric

The `-Metric` parameter indicates whether to collect data about CPU or Memory utilization.

### Threshold Type

The `-ThresholdType` parameter indicates the type of threshold to use with the `-Critical` and `-Warning` parameters. Valid values include:

* **PercentUsed** - Alerts based on the percent of the metric used. For example, the following command will alert critical if **more** than 60% of memory is used and warning if **more** than 40% is used.
  * `./check_vsphere -Server vcenter.example.com -Mode Cluster -Cluster "Production" -Metric Memory -Critical 60 -Warning 40 -ThresholdType PercentUsed`
* **PercentFree** - Alerts based on the percent of the metric free. For example, the following command will alert critical if **less** than 20% of CPU is free and warning if **less** than 40% is free.
  * `./check_vsphere -Server vcenter.example.com -Mode Cluster -Cluster "Production" -Metric Memory -Critical 20 -Warning 40 -ThresholdType PercentFree`
* **RawUsed** - Alerts based on the raw amount that is used. For example, the following command will alert critical if **more** than 128 GB of memory are used and warning if **more** than 100GB of memory are used.
  * `.\check_vsphere.ps1 -Server vcenter.example.com -Mode Host -VMHost "vmhost01.example.com" -Metric Memory -Critical 128 -Warning 100 -ThresholdType RawUsed`
* **RawFree** - Alerts based on the raw amount that is free. For example, the following command will alert critical if **less** than 48 GB of memory are free and warning if **less** than 64 GB of memory are free.
  * `.\check_vsphere.ps1 -Server vcenter.example.com -Mode Host -VMHost "vmhost01.example.com" -Metric Memory -Critical 48 -Warning 64 -ThresholdType RawFree`

### Performance Data

By default, the script will print the following types of performance data according to Nagios plugin developer guidelines:

* Raw used
* Raw free
* Percent used
* Percent free

The script will print the minimum and maximum. It will also fill in the critical and warning levels for the appropriate performance data, depending on the value of `-ThresholdType`. For example,

Performance data can be suppressed by setting any (or all) of the following parameters to `$false`:

* ShowRawUsed
* ShowRawFree
* ShowPercentUsed
* ShowPercentFree

For example, the invocation below will not print any performance data:

```
PS C:\>.\check_vsphere.ps1 -Server vcenter.example.com -Mode Cluster -Cluster "Production" -Metric Memory -ThresholdType PercentUsed -Critical 70 -Warning 50 -ShowPercentUsed $false -ShowPercentFree $false -ShowRawUsed $false -ShowRawFree $false

CRITICAL: 82.39391364278513895781327436% Memory Used |
```