#!/bin/bash

# Change directory to where this script is located
# Given the above assumption, all path are local ones
cd $(dirname $(readlink -f $0))

source ~/stackrc
openstack overcloud node import ../undercloud/instackenv.json
openstack baremetal node list --provision-state manageable|awk '/power on/ {print $2}'|xargs -n 1 -P 4 -r openstack baremetal node power off
openstack overcloud node introspect --all-manageable --provide
openstack baremetal node list -c UUID -f value|xargs -n 1 -P 1 -r openstack overcloud node configure

exit 0
