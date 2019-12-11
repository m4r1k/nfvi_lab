#!/bin/bash

subscription-manager register

subscription-manager attach --pool 8a85f98260c27fc50160c323263339ff

subscription-manager repos \
--disable "*" \
--enable rhel-7-server-rpms \
--enable rhel-7-server-extras-rpms \
--enable rhel-7-server-optional-rpms \
--enable rhel-7-server-rh-common-rpms

yum makecache fast

yum update -y
yum install -y tuned-profiles-cpu-partitioning tuned dpdk dpdk-devel dpdk-tools driverctl screen

echo "isolated_cores=1-6" | tee -a /etc/tuned/cpu-partitioning-variables.conf
systemctl enable --now tuned

tuned-adm profile cpu-partitioning

sed 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 default_hugepagesz=1GB hugepagesz=1G hugepages=8 isolcpus=1-6"/g' -i /etc/default/grub
grub2-mkconfig -o /etc/grub2.cfg

driverctl set-override 0000:00:04.0 uio_pci_generic
driverctl set-override 0000:00:05.0 uio_pci_generic

dracut -f

reboot
