# check_wsus_updates

Script for checking whether there are updates that need to be approved in WSUS.

## Usage

For complete usage information, check the help: `Get-Help ./check_wsus_updates.ps1 -Full`

### Default behavior

By default, the script will check the WSUS server (localhost, if none is provided by the `-Server` argument) for the presence of any security or critical updates that need to be approved. If security updates are found and have not been approved (or superseded by an approved update), then the script returns critical. If only critical updates are found and have not been approved (or superseded by an approved update), then the script returns warning.

To call the script with defaults, invoke it without any arguments: 

```
PS C:\scripts> .\check_wsus_updates.ps1
CRITICAL: 33 Security Updates Unapproved | 'Total Updates'=48 'Updates to Approve'=11 'Security Updates'=33 'Critical Updates'=13
```

Alternatively, you can supply the FQDN for a server:

```
PS C:\scripts> .\check_wsus_updates.ps1 -Server wsus.organization.example.com

CRITICAL: 33 Security Updates Unapproved | 'Total Updates'=48 'Updates to Approve'=11 'Security Updates'=33 'Critical Updates'=13
```

### Checking for only security updates

If you only want security updates to generate a non-OK exit code, then simply set the `-SecurityOnly` to `$true`. This will prevent critical updates from generating an error message:

```
PS C:\scripts> .\check_wsus_updates.ps1 -SecurityOnly $true

OK: 13 Critical Updates Unapproved | 'Total Updates'=48 'Updates to Approve'=11 'Security Updates'=0 'Critical Updates'=13
```

### Performance Data

The script can generate performance data (according to [Nagios Plugin Development Guidelines](https://nagios-plugins.org/doc/guidelines.html)) for the update classifications found in the `Get-WsusClassification` command. By default, performance data is provided for the following:

* Total Updates: All updates that haven't been approved
* Updates to approve: Updates that haven't been approved and are **not** superseded by any other updates
* Security Updates
* Crticial Updates

To get performance data for other update classifications, simply provide a string list of classifications to the `-PerformanceData` argument. Note that this list overrides the default behavior for security and critical classifications, so those must also be supplied if desired.

```
PS C:\scripts> Get-WsusClassification

Title              ID
-----              --
Applications       5c9376ab-8ce6-464a-b136-22113dd69801
Critical Updates   e6cf1350-c01b-414d-a61f-263d14d133b4
Definition Updates e0789628-ce08-4437-be74-2495b842f43b
Driver Sets        77835c8d-62a7-41f5-82ad-f28d1af1e3b1
Drivers            ebfc1fc5-71a4-4f7b-9aca-3b9a503104a0
Feature Packs      b54e7d24-7add-428f-8b75-90a396fa584f
Security Updates   0fa1201d-4330-4fa8-8ae9-b877473b6441
Service Packs      68c5b0a3-d1a6-4553-ae49-01d3a7827828
Tools              b4832bd8-e735-4761-8daf-37f882276dab
Update Rollups     28bc880e-0592-4cbf-8f95-c79b17911d5f
Updates            cd5ffd1e-e932-4e3a-bf74-18bf0b1bbd83
Upgrades           3689bdc8-b205-4af4-8d4a-a63924c5e9d5
```

```
PS C:\scripts> .\check_wsus_updates.ps1 -Server ist-wsus01 -PerformanceData @("Applications","Definition Updates","Security Updates","Critical Updates")

CRITICAL: 33 Security Updates Unapproved | 'Total Updates'=48 'Updates to Approve'=11 
'Application'=0 'Definition Updates'=2 'Security Updates'=33 'Critical Updates'=13
```