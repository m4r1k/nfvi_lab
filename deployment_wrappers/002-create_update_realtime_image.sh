#!/bin/bash

mkdir -p ~/tmp_rt/{rpm,image}
cd ~/tmp_rt/

tar -xf /usr/share/rhosp-director-images/overcloud-full-latest-13.0.tar
tar -xf /usr/share/rhosp-director-images/ironic-python-agent-latest-13.0.tar
mv overcloud-full.qcow2 overcloud-realtime-compute.qcow2
rm -f overcloud-full.initrd overcloud-full-rpm.manifest overcloud-full-signature.manifest overcloud-full.vmlinuz

rpm -qa|grep -q libguestfs-tools || sudo yum install -y libguestfs-tools

##########################################
# The following package will be downloaded
###### NFV REPO REQUIRED - rhel-7-server-nfv-rpms
# -kernel-rt
# -kernel-rt-kvm
# -tuned-profiles-nfv-host
# -qemu-kvm-tools-rhev
# -rt-setup
# -rtctl
# -tuna
# -tuned
# -tuned-profiles-realtime
# -tuned-profiles-cpu-partitioning
##########################################
sudo yum install -y --downloadonly --downloaddir=$(pwd)/rpm/ kernel-rt kernel-rt-kvm tuned-profiles-nfv-host tuned-profiles-cpu-partitioning
sudo yum reinstall -y --downloadonly --downloaddir=$(pwd)/rpm/ tuned

cat > rt.sh <<EOF
#!/bin/bash
set -eux
echo "##### START REALTIME KERNEL INSTALLATION #####"
yum -v -y install /root/rpm/*.rpm
yum -v -y --setopt=protected_packages= erase kernel
rm -rf /root/rpm
echo "##### END REALTIME KERNEL INSTALLATION #####"
EOF

virt-copy-in -a overcloud-realtime-compute.qcow2 rpm /root/
virt-customize -a overcloud-realtime-compute.qcow2 -v --run rt.sh 2>&1 | tee virt-customize.log
virt-customize -a overcloud-realtime-compute.qcow2 --selinux-relabel

guestmount -a overcloud-realtime-compute.qcow2 -i --ro image
cp image/boot/vmlinuz-*rt* ./overcloud-realtime-compute.vmlinuz
cp image/boot/initramfs-*rt* ./overcloud-realtime-compute.initrd
guestunmount image

rm -rf image rpm rt.sh

source ~/stackrc
openstack overcloud image upload --update-existing --os-image-name overcloud-realtime-compute.qcow2
openstack overcloud node configure $(openstack baremetal node list -c UUID -f value)

cd -
rm -rf ~/images_rt
mv ~/tmp_rt ~/images_rt
