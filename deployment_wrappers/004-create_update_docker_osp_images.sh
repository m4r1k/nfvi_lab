#!/bin/bash

# Change directory to where this script is located
# Given the above assumption, all path are local ones
cd $(dirname $(readlink -f $0))

echo "This script is meant to pull the Container images from the Red Hat CDN, hence a valid subscription must be enrolled to the system."

sudo subscription-manager status >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
  echo "subscription-manager returned an error"
  sudo subscription-manager status
  exit 1
fi

_THT="/usr/share/openstack-tripleo-heat-templates"
_LTHT="../overcloud"

source ~/stackrc

rm -f ${_LTHT}/overcloud_images.yaml

sudo -E openstack overcloud container image prepare \
    --namespace=registry.access.redhat.com/rhosp13 \
    --push-destination=$(ip -4 -o address show br-ctlplane|awk '{print $4}'|sed "s/\/.*$//g"):8787 \
    --prefix=openstack- \
    --tag-from-label {version}-{release} \
    --output-env-file=${_LTHT}/overcloud_images.yaml \
    --output-images-file /home/stack/local_registry_images.yaml \
    -r ${_LTHT}/roles-data.yaml \
    -e ${_THT}/environments/sshd-banner.yaml \
    -e ${_THT}/environments/network-isolation.yaml \
    -e ${_THT}/environments/host-config-and-reboot.yaml \
    -e ${_LTHT}/environments/10-commons-parameters.yaml \
    -e ${_LTHT}/environments/20-network-environment.yaml \
    -e ${_LTHT}/environments/30-storage-environment.yaml \
    -e ${_LTHT}/environments/40-fencing.yaml \
    -e ${_LTHT}/environments/50-keystone-admin-endpoint.yaml \
    -e ${_LTHT}/environments/60-openstack-neutron-custom-configs.yaml \
    -e ${_LTHT}/environments/65-openstack-nova-custom-configs.yaml \
    -e ${_LTHT}/environments/70-ovs-dpdk-sriov.yaml \
    -e ${_LTHT}/environments/99-extraconfig.yaml \
    -e ${_LTHT}/environments/99-server-blacklist.yaml

sudo -E openstack overcloud container image upload \
  --config-file  /home/stack/local_registry_images.yaml \
  --verbose

curl -s $(ip -4 -o address show br-ctlplane|awk '{print $4}'|sed "s/\/.*$//g"):8787/v2/_catalog|jq .
rm -f /home/stack/local_registry_images.yaml

exit 0
