#!/bin/bash

# Change directory to where this script is located
# Given the above assumption, all path are local ones
cd $(dirname $(readlink -f $0))

sudo subscription-manager status >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo "subscription-manager returned an error"
  sudo subscription-manager status
  exit 1
fi

_THT="/usr/share/openstack-tripleo-heat-templates"
_LTHT="../overcloud"

# The CLI openstack overcloud container image prepare ignore any Role that has CountDefault set to 0
# Ensure no Roles with CountDefault set to 0 exist
# All Container Image Services will be correctly downloaded
cp ${_LTHT}/roles-data.yaml ~/roles-data.yaml
sed -e "s/CountDefault: 0/CountDefault: 1/g" -i ~/roles-data.yaml

source ~/stackrc

rm -f ${_LTHT}/overcloud_images.yaml

sudo -E openstack tripleo container image prepare \
    -e ~/containers-prepare-parameter.yaml \
    --output-env-file=${_LTHT}/overcloud_images.yaml \
    -r ~/roles-data.yaml \
    -e ${_THT}/environments/sshd-banner.yaml \
    -e ${_THT}/environments/network-isolation.yaml \
    -e ${_THT}/environments/services/neutron-ovs.yaml \
    -e ${_THT}/environments/ceph-ansible/ceph-ansible.yaml \
    -e ${_THT}/environments/ceph-ansible/ceph-rgw.yaml \
    -e ${_THT}/environments/ceph-ansible/ceph-dashboard.yaml \
    -e ${_THT}/environments/services/cinder-backup.yaml \
    -e ${_THT}/environments/host-config-and-reboot.yaml \
    -e ${_LTHT}/environments/10-commons-parameters.yaml \
    -e ${_LTHT}/environments/20-network-environment.yaml \
    -e ${_LTHT}/environments/30-storage-environment.yaml \
    -e ${_LTHT}/environments/40-fencing.yaml \
    -e ${_LTHT}/environments/50-keystone-admin-endpoint.yaml \
    -e ${_LTHT}/environments/60-openstack-neutron-custom-configs.yaml \
    -e ${_LTHT}/environments/60-openstack-nova-custom-configs.yaml \
    -e ${_LTHT}/environments/60-openstack-glance-custom-configs.yaml \
    -e ${_LTHT}/environments/70-ovs-dpdk-sriov.yaml \
    -e ${_LTHT}/environments/99-extraconfig.yaml \
    -e ${_LTHT}/environments/99-server-blacklist.yaml

curl -s $(ip -4 -o address show br-ctlplane|awk '{print $4}'|sed "s/\/.*$//g"):8787/v2/_catalog|jq .
rm -f ~/roles-data.yaml

exit 0
