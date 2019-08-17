#!/bin/bash

source ~/overcloudrc

openstack server remove floating ip vm-vxlan-dpdk1 192.168.178.21
openstack server remove floating ip vm-vxlan-dpdk2 192.168.178.22

wait

openstack server delete --wait vm-vxlan-dpdk1 &
openstack server delete --wait vm-vxlan-dpdk2 &

wait

openstack floating ip delete 192.168.178.21 &
openstack floating ip delete 192.168.178.22 &

wait

openstack router remove subnet router mgmt
openstack router unset --external-gateway router
openstack router delete router

wait

openstack network delete vlan2000 &
openstack network delete vlan2001 &
openstack network delete ext &
openstack network delete mgmt &
openstack network delete mgmt-gre &

wait

openstack network qos policy delete policy0

openstack keypair delete undercloud

openstack flavor delete nfv

openstack metric resource batch delete "ended_at < '-1min'"

wait

