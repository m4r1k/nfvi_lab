# HCI (ESXi)
The HCI node has the scope to run virtualized components for the NFVi platform such as the OpenStack Controller nodes, Ceph etc.
Compared with the Linux HCI, this version runs VMware ESXi as it provides a more generic solution even though computational performance is lower.

To expose a BMC device, the virtualbmc is also used here as Libvirt supports multiple backends including ESXi hosts and vCenter Server.
The packages provided with RHEL 8.1 and upstream virtualbmc 1.6.0 have been tested with ESXi and vCSA 6.7u3 and also with the latest 7.0

Run ```proxy-vbmc-esxi.sh``` to configure a RHEL8/CentOS VM as proxy between the TripleO Undercloud and ESXi/vCenter Server API

The only limitation regards the PXE boot that cannot be configured automatically and needs to be statically set to Network first and then local disk after. Additionally, sometimes, ipxe from VMware hangs and needs VM reset to continue (both BIOS and uEFI VM experienced on vHW15 and also vHW17)

## Userful Knowledge Base
- [Emulating an SSD Virtual Disk in a VMware Environment](https://www.virtuallyghetto.com/2013/07/emulating-ssd-virtual-disk-in-vmware.html)
- [Sample configuration of virtual switch VLAN tagging](https://kb.vmware.com/s/article/1004074)
- [Changing the boot order of a virtual machine using vmx options](https://kb.vmware.com/s/article/2011654)
- [Checking cpuinfo information on an ESXi host](https://kb.vmware.com/s/article/1031785)

## Userful Performance Knowledge Base
- [Performance Best Practices for VMware vSphere 6.7](https://www.vmware.com/content/dam/digitalmarketing/vmware/en/pdf/techpaper/performance/vsphere-esxi-vcenter-server-67-performance-best-practices.pdf)
- [Best Practices for Performance Tuning of Telco and NFV Workloads in vSphere](https://www.vmware.com/content/dam/digitalmarketing/vmware/en/pdf/techpaper/vmware-tuning-telco-nfv-workloads-vsphere-white-paper.pdf)
- [VMware vCloud NFV 3.0](https://docs.vmware.com/en/VMware-vCloud-NFV/3.0/vmware-vcloud-nfv-30.pdf)
- [Hyperthreading and ESXi Hosts](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.resmgmt.doc/GUID-3362A2E9-AB03-4C10-B9A1-3E6CA78D399B.html)
- [What is PreferHT and When To Use It](https://blogs.vmware.com/vsphere/2014/03/perferht-use-2.html)
- [Assign a Virtual Machine to a Specific Processor](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.resmgmt.doc/GUID-F40F901D-C1A7-43E2-90AF-E6F98C960E4B.html)
- [Backing Guest vRAM with 1GB Pages](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.resmgmt.doc/GUID-F0E284A5-A6DD-477E-B80B-8EFDF814EE01.html)
- [Associate Virtual Machines with Specified NUMA Nodes](https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.resmgmt.doc/GUID-A80A6337-7B99-48C8-B024-EE47E2366C1B.html)
- [Checking cpuinfo information on an ESXi host](https://kb.vmware.com/s/article/1031785)
- [VMware vSphere - Why checking NUMA Configuration is so important!](https://itnext.io/vmware-vsphere-why-checking-numa-configuration-is-so-important-9764c16a7e73)
- [VMworld 2017 - SER2724BE - Extreme Performance Series: Performance Best Practices](https://www.youtube.com/watch?v=e9GWK8Pn8ec)
- [Extreme Performance Series at VMworld 2019](https://blogs.vmware.com/performance/2019/07/extreme-performance-series-at-vmworld-2019.html)
- [What is the Impact of the VMKlinux Driver Stack Deprecation?](https://blogs.vmware.com/vsphere/2019/04/what-is-the-impact-of-the-vmklinux-driver-stack-deprecation.html)
