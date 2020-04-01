#!/bin/bash

subscription-manager register

subscription-manager attach --pool 8a85f98260c27fc50160c323263339ff

subscription-manager repos \
--disable "*" \
--enable rhel-7-server-rpms \
--enable rhel-7-server-extras-rpms \
--enable rhel-7-server-optional-rpms \
--enable rhel-7-server-rh-common-rpms

# Docker in RHEL7 is based on version 1.13.1 which is super old
# NFVBench runs just fine on Docker provided by Red Hat but I prefer to rely on wider community tested bits
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum makecache fast

yum update -y
yum install -y tuned-profiles-cpu-partitioning tuned dpdk dpdk-devel dpdk-tools driverctl screen sysstat
yum install -y docker-ce docker-ce-cli containerd.io docker-ce-selinux docker-rhel-push-plugin

systemctl disable --now NetworkManager
systemctl enable --now docker

echo "isolated_cores=1-6" | tee -a /etc/tuned/cpu-partitioning-variables.conf
systemctl enable --now tuned

tuned-adm profile cpu-partitioning

sed 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 default_hugepagesz=1GB hugepagesz=1G hugepages=8 isolcpus=1-6"/g' -i /etc/default/grub
grub2-mkconfig -o /etc/grub2.cfg

# https://bugzilla.redhat.com/show_bug.cgi?id=1762087
# vIOMMU not supported
cat > /etc/modprobe.d/vfio.conf << EOF
options vfio enable_unsafe_noiommu_mode=Y
options vfio_iommu_type1 allow_unsafe_interrupts=Y
EOF

driverctl set-override 0000:00:06.0 vfio-pci
driverctl set-override 0000:00:07.0 vfio-pci

dracut -f

docker pull opnfv/nfvbench:latest

reboot
