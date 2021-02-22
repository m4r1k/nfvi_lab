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
    --stack-only \
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

_END1=$(date +%s)

# Creates tripleo-admin user in the overcloud and exchange SSH Key
openstack overcloud admin authorize

# Ensure the Mistral SSH Key is usable by Stack  user
sudo chown 42430:$(id --group) /var/lib/mistral/overcloud/ssh_private_key
sudo chmod 0660 /var/lib/mistral/overcloud/ssh_private_key

# Generate all Ansible's playbooks
openstack overcloud config download \
  --name overcloud \
  --no-preserve-config \
  --config-dir ~/config-download

# To directly use Ansible, is not possible to re-use Mistral's ansible.cfg, so creates a new one
python3 ${_LDIR}/write_default_ansible_cfg.py

# Generates Ansible's inventory
tripleo-ansible-inventory \
  --ansible_ssh_user tripleo-admin \
  --plan overcloud \
  --static-yaml-inventory ~/config-download/inventory.yaml

cd ~/config-download
ansible -i ~/config-download/inventory.yaml -m ping all
# https://docs.openstack.org/project-deploy-guide/tripleo-docs/latest/deployment/ansible_config_download.html#manual-config-download
ansible-playbook \
  -i ~/config-download/inventory.yaml \
  --become \
  --skip-tags opendev-validation \
  ~/config-download/overcloud/deploy_steps_playbook.yaml

_END2=$(date +%s)
_TOTALTIME=$((${_END2}-${_START}))
_PROVISIONING=$((${_END1}-${_START}))
_CONFIG=$((${_END2}-${_END1}))
echo "DEPLOYMENT STARTED: $(date --date="@${_START}" --utc)"
if ((${_TOTALTIME} < 3600)); then
	echo "PROVISIONING PHASE: $(date -d@${_PROVISIONING} -u +%M'm'%S's')"
	echo "CONFIG PHASE: $(date -d@${_CONFIG} -u +%M'm'%S's')"
	echo "TOTAL DEPLOYMENT TIME: $(date -d@${_TOTALTIME} -u +%M'm'%S's')"
else
	echo "PROVISIONING PHASE: $(date -d@${_PROVISIONING} -u +%H'h'%M'm'%S's')"
	echo "CONFIG PHASE: $(date -d@${_CONFIG} -u +%H'h'%M'm'%S's')"
	echo "TOTAL DEPLOYMENT TIME: $(date -d@${_TOTALTIME} -u +%H'h'%M'm'%S's')"
fi

exit 0
