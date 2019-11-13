#!/bin/bash

source ~/overcloudrc

openstack server remove floating ip nfvbench 192.168.178.21
openstack server remove floating ip testpmd 192.168.178.22

wait

openstack server delete --wait nfvbench &
openstack server delete --wait testpmd &

wait

openstack floating ip delete 192.168.178.21 &
openstack floating ip delete 192.168.178.22 &

wait

openstack router remove subnet router mgmt
openstack router unset --external-gateway router
openstack router delete router

openstack port delete nfvbench_a &
openstack port delete nfvbench_b &

wait

openstack network delete pf &
openstack network delete vlan2000 &
openstack network delete vlan2001 &
openstack network delete ext &
openstack network delete mgmt &

wait

openstack keypair delete undercloud

openstack flavor delete nfv

openstack metric resource batch delete "ended_at < '-1min'"

wait
