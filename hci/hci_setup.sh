#!/bin/bash

# Make sure Subscription is done
# Make sure packages can be downloaded

subscription-manager attach --pool 8a85f99c6e417e37016e6c2fb484073e

subscription-manager repos \
--disable "*" \
--enable rhel-8-for-x86_64-baseos-rpms \
--enable rhel-8-for-x86_64-appstream-rpms \
--enable rhel-8-for-x86_64-highavailability-rpms \
--enable rhel-8-for-x86_64-nfv-rpms \
--enable rhel-8-for-x86_64-rt-rpms \
--enable rhel-8-for-x86_64-supplementary-rpms \
--enable codeready-builder-for-rhel-8-x86_64-rpms \
--enable ansible-2.9-for-rhel-8-x86_64-rpms \
--enable advanced-virt-for-rhel-8-x86_64-rpms \
--enable satellite-tools-6.6-for-rhel-8-x86_64-rpms \
--enable openstack-16-for-rhel-8-x86_64-rpms \
--enable openstack-16-tools-for-rhel-8-x86_64-rpms \
--enable openstack-16-devtools-for-rhel-8-x86_64-rpms \
--enable fast-datapath-for-rhel-8-x86_64-rpms

dnf makecache

dnf module -y reset virt
dnf module -y enable virt:8.1

dnf module -y enable container-tools
dnf module -y install container-tools

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

dnf install -y lm_sensors
sensors-detect --auto
systemctl enable --now lm_sensors.service

dnf install -y ipmitool lsof tcpdump vim git

dnf install -y rng-tools
systemctl enable --now rngd

dnf install -y python3-virtualenv python3-libvirt libvirt-devel gcc make
virtualenv /root/vBMC
source /root/vBMC/bin/activate
pip install virtualbmc
firewall-cmd --zone=public --permanent --add-port=623/udp
firewall-cmd --reload

dnf install -y nvme-cli

dnf install -y perf
podman run -d --name=netdata \
  -p 19999:19999 \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  --cap-add SYS_PTRACE \
  --security-opt label=disable \
  --restart always \
  --cpuset-cpus 0,1,20,21,40,41,60,61 \
  netdata/netdata:v1.20.0
cat > /etc/systemd/system/netdata-container.service << EOF
[Unit]
Description=Netdata Container
[Service]
Restart=always
ExecStart=/usr/bin/podman start -a netdata
ExecStop=/usr/bin/podman stop -t 2 netdata
[Install]
WantedBy=local.target
EOF
systemctl enable netdata-container.service
firewall-cmd --zone=public --permanent --add-port=19999/tcp
firewall-cmd --reload

# Do not accept forwarded locale
sed -e 's/^\(AcceptEnv LANG.*\)/#\1/g' -e 's/^\(AcceptEnv LC_.*\)/#\1/g' -i /etc/ssh/sshd_config
systemctl restart sshd

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
# Also see /usr/share/doc/kernel-doc-4.18.0/Documentation/admin-guide/kernel-parameters.txt
sed 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 mitigations=off"/g' -i /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

virsh pool-define --file optane.xml
virsh pool-start optane
virsh pool-autostart optane

virsh pool-define --file ssd.xml
virsh pool-start ssd
virsh pool-autostart ssd

qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/UC.img 100G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/CTRL0.img 50G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/CTRL1.img 50G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/CTRL2.img 50G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/CEPH0.img 50G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/CEPH1.img 50G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/images/CEPH2.img 50G &

wait

qemu-img create -f raw -o preallocation=full /var/lib/libvirt/ssd/CEPH0-0.img 75G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/ssd/CEPH0-1.img 75G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/ssd/CEPH1-0.img 75G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/ssd/CEPH1-1.img 75G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/ssd/CEPH2-0.img 75G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/ssd/CEPH2-1.img 75G &

wait

qemu-img create -f raw -o preallocation=full /var/lib/libvirt/optane/CEPH0.img 8G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/optane/CEPH1.img 8G &
qemu-img create -f raw -o preallocation=full /var/lib/libvirt/optane/CEPH2.img 8G &

wait

curl -o /tmp/dell_ome.zip -L https://downloads.dell.com/FOLDER05774382M/1/openmanage_enterprise_kvm_format_3.2.1.zip
unzip /tmp/dell_ome.zip -x openmanage_enterprise.qcow2 -d /tmp/
mv /tmp/appliance/qemu-kvm/openmanage_enterprise.qcow2 /var/lib/libvirt/images/
rm -rf /tmp/dell_ome.zip /tmp/appliance

cat > /etc/sysctl.d/asynchronous_io_tuning.conf << EOF
# http://kvmonz.blogspot.com/p/knowledge-choosing-right-configuration.html
# http://kvmonz.blogspot.com/p/knowledge-disk-performance-hints-tips.html
fs.aio-nr = 0
fs.aio-max-nr = 4194304
EOF
sysctl -w fs.aio-max-nr=4194304

virsh define --file ./UC.xml --validate
virsh define --file ./CTRL0.xml --validate
virsh define --file ./CTRL1.xml --validate
virsh define --file ./CTRL2.xml --validate
virsh define --file ./CEPH0.xml --validate
virsh define --file ./CEPH1.xml --validate
virsh define --file ./CEPH2.xml --validate
virsh define --file ./OME.xml --validate

echo "## REBOOT THE HCI NODE PLEASE ##"
