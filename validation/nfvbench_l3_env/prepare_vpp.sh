#!/bin/bash

subscription-manager register

subscription-manager attach --pool 8a85f98260c27fc50160c323263339ff

subscription-manager repos \
--disable "*" \
--enable rhel-7-server-rpms \
--enable rhel-7-server-extras-rpms \
--enable rhel-7-server-optional-rpms \
--enable rhel-7-server-rh-common-rpms

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# https://packagecloud.io/fdio/release
curl -s https://packagecloud.io/install/repositories/fdio/release/script.rpm.sh | bash

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

yum install -y vpp vpp-plugins vpp-selinux-policy

cat > /etc/vpp/startup.conf << EOF
unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /run/vpp/cli.sock
  startup-config /etc/vpp/base.conf
  gid vpp
}
api-trace {
  on
}
api-segment {
  gid vpp
}
socksvr {
  default
}
cpu {
        main-core 1
        corelist-workers 2-5
        workers 4
        scheduler-policy fifo
        scheduler-priority 50
}
buffers {
        buffers-per-numa 16384
        default data-size 2048
}
dpdk {
        dev default {
                num-rx-queues 1
                num-tx-queues 1
                num-rx-desc 1024
                num-tx-desc 1024
                vlan-strip-offload off
        }
        uio-driver uio_pci_generic
        socket-mem 4096
        # no-multi-seg
        # no-tx-checksum-offload
}
EOF

cat > /etc/vpp/base.conf << EOF
set interface ip address GigabitEthernet0/4/0 10.10.1.1/24
set interface ip address GigabitEthernet0/5/0 10.10.2.1/24
set interface state GigabitEthernet0/4/0 up
set interface state GigabitEthernet0/5/0 up
ip route add 16.0.0.0/8 via 10.10.1.2
ip route add 48.0.0.0/8 via 10.10.2.2
EOF

systemctl enable --now vpp

reboot
