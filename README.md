# Overview

This repository is a collection of scripts that I've written for use with Icinga/Nagios. There's a README in each subdirectory, but here's a high-level overview of the available checks:

## VMWare/PowerCLI Checks
* [check_vsphere](./check_vsphere) - Script for checking CPU and Memory utilization in vSphere clusters or hosts
* [check_vsphere_num_vms](./check_vsphere_num_vms) - Script for checking the number of VMs in a vSphere location and optionally alerting based on the total number.

## Windows Checks
* [check_scheduled_task](./check_scheduled_task) - Script for checking whether or not a scheduled task ran successfully.
* [check_wsus_updates](./check_wsus_updates) - Script for checking whether there are updates that need to be approved in WSUS.