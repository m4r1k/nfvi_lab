#!/bin/bash

bash /root/vBMC.sh

virsh start UC &
virsh start CTRL0 &
virsh start CTRL1 &
virsh start CTRL2 &
virsh start CEPH0 &
virsh start CEPH1 &
virsh start CEPH2 &

wait
