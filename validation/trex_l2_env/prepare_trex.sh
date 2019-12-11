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

# https://bugzilla.redhat.com/show_bug.cgi?id=1762087
# vIOMMU not supported
cat > /etc/modprobe.d/vfio.conf << EOF
options vfio enable_unsafe_noiommu_mode=Y
options vfio_iommu_type1 allow_unsafe_interrupts=Y
EOF

driverctl set-override 0000:00:06.0 vfio-pci
driverctl set-override 0000:00:07.0 vfio-pci

dracut -f

mkdir -p /opt/trex
cd /opt/trex
curl -O -L https://trex-tgn.cisco.com/trex/release/v2.71.tar.gz
tar xf v2.71.tar.gz

cat > /etc/trex_cfg.yaml << EOF
- port_limit: 2
  version: 2
  interfaces: ['00:06.0', '00:07.0']
  port_info:
      - dest_mac: aa:aa:aa:aa:aa:21
        src_mac:  00:00:00:00:00:21
      - dest_mac: aa:aa:aa:aa:aa:22
        src_mac:  00:00:00:00:00:22
  c: 2
  limit_memory: 4096

  platform:
      master_thread_id: 1
      latency_thread_id: 2
      dual_if:
        - socket: 0
          threads: [3,4,5,6]
EOF

reboot
