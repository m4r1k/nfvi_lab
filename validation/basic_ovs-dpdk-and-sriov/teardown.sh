#!/bin/bash

source ~/overcloudrc

openstack server remove floating ip vm-dpdk 192.168.178.21
openstack server remove floating ip vm-sriov 192.168.178.22

wait

openstack server delete --wait vm-dpdk &
openstack server delete --wait vm-sriov &

wait

openstack floating ip delete 192.168.178.21 &
openstack floating ip delete 192.168.178.22 &

wait

openstack router remove subnet router mgmt
openstack router unset --external-gateway router
openstack router delete router

wait

openstack port delete 10.20.0.221 &

wait

openstack network delete vlan2000-dpdk &
openstack network delete vlan2000-sriov &
openstack network delete ext &
openstack network delete mgmt &

wait

openstack network qos policy delete policy0

openstack keypair delete undercloud

openstack flavor delete nfv

openstack metric resource batch delete "ended_at < '-1min'"

wait
