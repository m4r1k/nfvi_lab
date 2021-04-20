#!/bin/bash

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf makecache
dnf install -y epel-release

dnf update -y
dnf install -y tuned-profiles-cpu-partitioning tuned dpdk dpdk-devel dpdk-tools driverctl screen sysstat
dnf install -y docker-ce docker-ce-cli containerd.io container-selinux

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
