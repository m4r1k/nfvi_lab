#!/bin/bash

cat > /etc/modprobe.d/kvm.rt.conf << EOF
options kvm nx_huge_pages_recovery_ratio=0
EOF
chcon system_u:object_r:modules_conf_t:s0 /etc/modprobe.d/kvm.rt.conf

lsmod | grep -q kvm && echo 0 > /sys/module/kvm/parameters/nx_huge_pages_recovery_ratio

exit 0
