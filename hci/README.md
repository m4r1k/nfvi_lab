# HCI (Linux)
The HCI node has the scope to run virtualized components for the NFVi platform such as the OpenStack Controller nodes, Ceph etc.
Running the ```hci_setup.sh``` it's possible to configure a RHEL8 node for the scope.
The only manual step is the block storage configuration (creating partition table, FS, etc)

When the nodes start, running the ```vBMC.sh``` the vBMC for the VM will be initiated

# Userful Knowledge Base
[KVM guests with emulated SSD and NVMe drives](https://blog.christophersmart.com/2019/12/18/kvm-guests-with-emulated-ssd-and-nvme-drives/)
[Storage Performance Tuning for FAST! Virtual Machines](https://events19.lfasiallc.com/wp-content/uploads/2017/11/Storage-Performance-Tuning-for-FAST-Virtual-Machines_Fam-Zheng.pdf)
