#!/bin/bash

_START=$(date +%s)

# Change directory to where this script is located
# Given the above assumption, all path are local ones
cd $(dirname $(readlink -f $0))

source ~/stackrc

_THT="/usr/share/openstack-tripleo-heat-templates"
_LTHT="$(readlink -f ../overcloud)"
_LDIR="$(readlink -f .)"

# Move to home folder to output the generared files during the deployment there
cd ~/

openstack overcloud deploy \
    --force-postconfig \
    --verbose \
    --stack overcloud \
    --templates ${_THT} \
    --timeout 180 \
    -r ${_LTHT}/roles-data.yaml \
    -e ${_LTHT}/nodes-info.yaml \
    -e ${_THT}/environments/sshd-banner.yaml \
    -e ${_THT}/environments/network-isolation.yaml \
    -e ${_THT}/environments/services/neutron-ovs.yaml \
    -e ${_THT}/environments/ceph-ansible/ceph-ansible.yaml \
    -e ${_THT}/environments/ceph-ansible/ceph-rgw.yaml \
    -e ${_THT}/environments/ceph-ansible/ceph-dashboard.yaml \
    -e ${_THT}/environments/services/cinder-backup.yaml \
    -e ${_THT}/environments/host-config-and-reboot.yaml \
    -e ~/containers-prepare-parameter.yaml \
    -e ${_LTHT}/overcloud_images.yaml \
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

_END=$(date +%s)

_TOTALTIME=$((${_END}-${_START}))
echo "DEPLOYMENT STARTED: $(date --date="@${_START}" --utc)"
if ((${_TOTALTIME} < 3600)); then
	echo "DEPLOYMENT TIME: $(date -d@${_TOTALTIME} -u +%M'm'%S's')"
else
	echo "DEPLOYMENT TIME: $(date -d@${_TOTALTIME} -u +%H'h'%M'm'%S's')"
fi

exit 0
