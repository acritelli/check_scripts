# check_vsphere_num_vms

Script for checking the number of VMs in a vSphere location and optionally alerting based on the total number.

## Usage

For complete usage information, check the help: `Get-Help ./check_vsphere_num_vms.ps1 -Full`

check_vsphere_num_vms is able to check for the number of VMs in a vSphere location, including Datacenter, Cluster, Resource Pool, or an individual VM Host. If desired, it can throw a warning or critical alert if the number of VMs exceeds a specified threshold. Otherwise, it will just return OK and provide Nagios performance data. This can be useful for simply tracking the number of VMs in a dynamic environment.

### Connecting to vCenter.

The script must have a way of talking to vCenter. See the "Connecting to vCenter" section of the check_vsphere host, located [here.](../check_vsphere/README.md)

### Running without any thresholds

The most simple execution involves running the script without any defined thresholds. This will exit OK and provide metrics about the number of VMs in the specified location. The example below will print the total number of VMs in the "Production" resource pool.

```
PS C:\> .\check_vsphere.ps1 -Server vcenter.example.com -ResourcePool "Production"
OK: 309 total VMs | Total VMs=309;;;0;
```

Note that location parameters are mutually exclusive. If the `-ResourcePool` parameter is set, then no other parameters (Datacenter, Cluster, etc.) should be set.

### Running with thresholds

If you want to receive alerts when the number of VMs exceeds a certain threshold, simply specify the `-Warning` and/or `-Critical` parameters. The example below checks the number of VMs in the "Development" cluster and warns when there are more than 1000 or alerts critical when there are more than 1500.

```
PS C:\> .\check_vsphere.ps1 -Server rlesvctr -Cluster "Development" -Warning 1000 -Critical 1500
CRITICAL: 1632 total VMs | Total VMs=1632;1000;1500;0;
```