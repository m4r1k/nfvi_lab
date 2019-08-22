#!/bin/bash

source ~/overcloudrc

openstack quota set --ram -1 admin
openstack quota set --cores -1 admin

openstack image show fedora >/dev/null 2>&1 || openstack image create \
	--container-format bare \
	--disk-format qcow2 \
	--min-disk 4 \
	--public \
	--file ~/Fedora-Cloud-Base-30-1.2.x86_64.qcow2 \
	--property hw_disk_bus=scsi \
	--property hw_scsi_model=virtio-scsi \
	--property hw_watchdog_action=reset \
	--property os_require_quiesce=yes \
	--property hw_qemu_guest_agent=yes \
	fedora

openstack flavor show nfv >/dev/null 2>&1 || openstack flavor create \
	--id 10 \
	--ram 16384 \
	--disk 10 \
	--vcpus 7 \
	--public \
	--property hw:cpu_policy=dedicated \
	--property hw:cpu_thread_policy=isolate \
	--property hw:mem_page_size=large \
	--property hw:numa_mempolicy=strict \
	--property hw:emulator_threads_policy=share \
	--property hw:cpu_sockets=1 \
	--property hw:numa_nodes=1 \
	nfv

openstack keypair show undercloud >/dev/null 2>&1 || openstack keypair create --public-key ~/.ssh/id_rsa.pub undercloud

openstack network qos policy show policy0 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network qos policy create policy0
	openstack network qos rule create policy0 \
	--type bandwidth-limit \
	--max-kbps 1000000 \
	--max-burst-kbits 1000000 \
	--egress
fi

openstack network show mgmt >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create --mtu 1500 --provider-network-type vxlan mgmt
	openstack subnet create --network mgmt --dhcp --subnet-range 192.168.125.0/24 mgmt
fi

openstack network show mgmt-gre >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create --mtu 1500 --provider-network-type gre mgmt-gre
	openstack subnet create --network mgmt-gre --dhcp --subnet-range 192.168.126.0/24 mgmt-gre
fi

openstack network show vlan2000 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network niantic_pool \
	--provider-segment 2000 \
	--mtu 9000 \
	vlan2000
	openstack subnet create \
	--network vlan2000 \
	--dhcp \
	--gateway none \
	--subnet-range 10.20.0.0/24 \
	vlan2000

	openstack port create --network vlan2000 --fixed-ip ip-address=10.20.0.21 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	--qos-policy policy0 \
	10.20.0.21
	openstack port create --network vlan2000 --fixed-ip ip-address=10.20.0.22 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	--qos-policy policy0 \
	10.20.0.22
fi

openstack network show vlan2001 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network niantic_pool \
	--provider-segment 2001 \
	--mtu 9000 \
	vlan2001
	openstack subnet create \
	--network vlan2001 \
	--dhcp \
	--gateway none \
	--subnet-range 10.30.0.0/24 \
	vlan2001

	openstack port create --network vlan2001 --fixed-ip ip-address=10.30.0.21 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	10.30.0.21
	openstack port create --network vlan2001 --fixed-ip ip-address=10.30.0.22 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	10.30.0.22
fi

openstack network show ext >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type flat \
	--provider-physical-network external \
	--mtu 1500 \
	--external \
	ext
	openstack subnet create \
	--network ext \
	--no-dhcp \
	--subnet-range 192.168.178.0/24 \
	--allocation-pool start=192.168.178.20,end=192.168.178.25 \
	ext
fi

openstack router show router >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack router create --ha router
	openstack router set router --external-gateway ext --fixed-ip ip-address=192.168.178.20
	openstack router add subnet router mgmt
	openstack router add subnet router mgmt-gre
	openstack floating ip create --floating-ip-address 192.168.178.21 ext
	openstack floating ip create --floating-ip-address 192.168.178.22 ext
fi

openstack server show vm-sriov1 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image fedora \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic port-id=$(openstack port show 10.20.0.21 --format value --column id) \
	--nic port-id=$(openstack port show 10.30.0.21 --format value --column id) \
	--config-drive true\
	--key-name undercloud \
	--wait \
	vm-sriov1 &
fi

openstack server show vm-sriov2 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image fedora \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic port-id=$(openstack port show 10.20.0.22 --format value --column id) \
	--nic port-id=$(openstack port show 10.30.0.22 --format value --column id) \
	--key-name undercloud \
	--wait \
	vm-sriov2 &
fi

wait

openstack server add floating ip vm-sriov1 192.168.178.21
openstack server add floating ip vm-sriov2 192.168.178.22

ping -c 5 192.168.178.21
ping -c 5 192.168.178.22

openstack port list --network mgmt --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security
openstack port list --network mgmt-gre --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security
openstack port list --network vlan2000 --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security

ping -c 5 192.168.178.21
ping -c 5 192.168.178.22
