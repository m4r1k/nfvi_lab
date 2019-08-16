#!/bin/bash

source ~/overcloudrc

openstack server remove floating ip vm-vxlan-dpdk-sriov 10.95.134.21 &
openstack server remove floating ip vm-cinder-vxlan-dpdk-pt 10.95.134.22 &

wait

openstack server delete --wait vm-vxlan-dpdk-sriov &
openstack server delete --wait vm-cinder-vxlan-dpdk-pt &

wait

openstack image delete vm-vxlan-dpdk-sriov-snapshot
openstack volume snapshot delete vm-cinder-vxlan-dpdk-pt-snapshot

sleep 15s

openstack volume delete volume &

wait

openstack floating ip delete 10.95.134.21 &
openstack floating ip delete 10.95.134.22 &

wait

openstack router remove subnet router mgmt
openstack router unset --external-gateway router
openstack router delete router

openstack port delete 172.19.0.20 &
openstack port delete 172.19.0.21 &

wait

openstack network delete vlan406 &
openstack network delete vlan401 &
openstack network delete ext &
openstack network delete mgmt &

wait

openstack network qos policy delete policy0

openstack keypair delete undercloud

openstack flavor delete nfv

openstack metric resource batch delete "ended_at < '-1min'"

wait

