#!/bin/bash

# Make sure Subscription is done
# Make sure packages can be downloaded

dnf makecache

dnf module -y reset virt
dnf module -y enable virt:8.1

dnf upgrade -y

dnf install -y cockpit cockpit-machines cockpit-storaged cockpit-dashboard qemu-kvm qemu-kvm-common
systemctl enable --now cockpit.socket
systemctl enable --now libvirtd.service

firewall-cmd --add-service=cockpit --permanent
firewall-cmd --reload

dnf install -y rhosp-openvswitch
systemctl enable --now openvswitch.service
systemctl enable --now network

dnf install -y tuned-profiles-cpu-partitioning tuned numactl
systemctl enable --now tuned
systemctl disable --now ksm.service ksmtuned.service
tuned-adm profile virtual-host

dnf install -y ipmitool lsof tcpdump vim git

dnf install -y rng-tools
systemctl enable --now rngd

dnf install -y python3-virtualenv python3-libvirt libvirt-devel gcc make
virtualenv /root/vBMC
source /root/vBMC/bin/activate
pip install virtualbmc

firewall-cmd --zone=public --permanent --add-port=623/udp
firewall-cmd --reload

cat > /etc/sysconfig/network-scripts/ifcfg-br0 << EOF
DEVICE=br0
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=192.168.178.13
PREFIX=24
GATEWAY=192.168.178.1
DNS1=1.1.1.1
DNS2=8.8.8.8
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br1 << EOF
DEVICE=br1
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=none
ZONE=trusted
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br2 << EOF
DEVICE=br2
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=none
ZONE=trusted
MTU=9000
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eno1 << EOF
DEVICE=eno1
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br0
BOOTPROTO=none
HOTPLUG=no
NM_CONTROLLED=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eno2 << EOF
DEVICE=eno2
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br1
BOOTPROTO=none
HOTPLUG=no
NM_CONTROLLED=no
ZONE=trusted
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-enp130s0 << EOF
DEVICE=enp130s0
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br2
BOOTPROTO=none
HOTPLUG=no
NM_CONTROLLED=no
ZONE=trusted
MTU=9000
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eno3 << EOF
DEVICE=eno3
ONBOOT=no
NM_CONTROLLED=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eno4 << EOF
DEVICE=eno4
ONBOOT=no
NM_CONTROLLED=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-enp130s0d1 << EOF
DEVICE=enp130s0d1
ONBOOT=no
NM_CONTROLLED=no
EOF

systemctl restart network NetworkManager

virsh net-define --file ./br0.xml
virsh net-start br0
virsh net-autostart br0

virsh net-define --file ./br1.xml
virsh net-start br1
virsh net-autostart br1

virsh net-define --file ./br2.xml
virsh net-start br2
virsh net-autostart br2

virsh net-destroy default
virsh net-autostart default --disable

firewall-cmd --permanent --zone=trusted --add-interface=br1
firewall-cmd --permanent --zone=trusted --add-interface=br2
firewall-cmd --permanent --zone=trusted --add-interface=eno2
firewall-cmd --permanent --zone=trusted --add-interface=enp130s0
firewall-cmd --reload

# firewall-cmd --get-log-denied
# firewall-cmd --set-log-denied=all
# firewall-cmd --reload

sed 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 default_hugepagesz=1GB hugepagesz=1G hugepages=240 intel_iommu=on iommu=pt isolcpus=2-19,22-39,42-59,62-79"/g' -i /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# This is a fully disconnected system, disabling any mitigations for the Side Channel Attacks
# Side Channel Attacks Cheat Sheet -> https://access.redhat.com/articles/3629031
sed 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 spectre_v2=off nopti spec_store_bypass_disable=off l1tf=off mds=off"/g' -i /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

qemu-img create -o preallocation=full -f qcow2 /var/lib/libvirt/images/CTRL0.qcow2 50G
qemu-img create -o preallocation=full -f qcow2 /var/lib/libvirt/images/CTRL1.qcow2 50G
qemu-img create -o preallocation=full -f qcow2 /var/lib/libvirt/images/CTRL2.qcow2 50G

cat > /etc/sysctl.d/asynchronous_io_tuning.conf << EOF
# http://kvmonz.blogspot.com/p/knowledge-choosing-right-configuration.html
# http://kvmonz.blogspot.com/p/knowledge-disk-performance-hints-tips.html
fs.aio-nr = 0
fs.aio-max-nr = 4194304
EOF
sysctl -w fs.aio-max-nr=4194304

dnf define --file ./UC.xml --validate
dnf define --file ./CTRL0.xml --validate
dnf define --file ./CTRL1.xml --validate
dnf define --file ./CTRL2.xml --validate

echo "## REBOOT THE HCI NODE PLEASE ##"
