#!/bin/bash

_IMAGE=rhel-7.9-x86_64-kvm.qcow2

source ~/overcloudrc

openstack quota set --ram -1 admin
openstack quota set --cores -1 admin

openstack image show rhel >/dev/null 2>&1 || openstack image create \
	--container-format bare \
	--disk-format qcow2 \
	--min-disk 4 \
	--public \
	--file ~/${_IMAGE} \
	--property hw_disk_bus=scsi \
	--property hw_scsi_model=virtio-scsi \
	--property hw_watchdog_action=reset \
	--property os_require_quiesce=yes \
	--property hw_qemu_guest_agent=yes \
	rhel

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

openstack network show mgmt >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create --mtu 1500 --provider-network-type vxlan --disable-port-security mgmt
	openstack subnet create --network mgmt --dhcp --subnet-range 192.168.125.0/24 mgmt
fi

openstack network show sriov-vlan2000 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--disable-port-security \
	--provider-network-type vlan \
	--provider-physical-network niantic_pool \
	--provider-segment 2000 \
	--mtu 9000 \
	sriov-vlan2000
	openstack subnet create \
	--network sriov-vlan2000 \
	--no-dhcp \
	--gateway none \
	--subnet-range 10.10.1.0/24 \
	sriov-vlan2000

	openstack port create --network sriov-vlan2000 \
	--mac-address 00:00:00:00:00:21 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	--fixed-ip ip-address=10.10.1.2 \
	trafficgen_a
fi

openstack network show sriov-vlan2001 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
        openstack network create \
        --disable-port-security \
        --provider-network-type vlan \
        --provider-physical-network niantic_pool \
        --provider-segment 2001 \
        --mtu 9000 \
        sriov-vlan2001
        openstack subnet create \
        --network sriov-vlan2001 \
        --no-dhcp \
        --gateway none \
        --subnet-range 10.10.2.0/24 \
        sriov-vlan2001

	openstack port create --network sriov-vlan2001 \
	--mac-address 00:00:00:00:00:22 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	--fixed-ip ip-address=10.10.2.2 \
	trafficgen_b
fi

openstack network show vlan2000 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--disable-port-security \
	--provider-network-type vlan \
	--provider-physical-network datacentre0 \
	--provider-segment 2000 \
	--mtu 9000 \
	vlan2000
	openstack subnet create \
	--network vlan2000 \
	--no-dhcp \
	--gateway none \
	--subnet-range 10.10.1.0/24 \
	vlan2000

	openstack port create --network vlan2000 \
	--mac-address aa:aa:aa:aa:aa:21 \
	--fixed-ip ip-address=10.10.1.1 \
	reflector_a
fi

openstack network show vlan2001 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
        openstack network create \
	--disable-port-security \
        --provider-network-type vlan \
        --provider-physical-network datacentre0 \
        --provider-segment 2001 \
        --mtu 9000 \
        vlan2001
        openstack subnet create \
        --network vlan2001 \
	--no-dhcp \
        --gateway none \
        --subnet-range 10.10.2.0/24 \
        vlan2001

	openstack port create --network vlan2001 \
	--mac-address aa:aa:aa:aa:aa:22 \
	--fixed-ip ip-address=10.10.2.1 \
	reflector_b
fi

openstack network show ext >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--disable-port-security \
	--provider-network-type flat \
	--provider-physical-network external \
	--mtu 1500 \
	--external \
	ext
	openstack subnet create \
	--network ext \
	--no-dhcp \
	--subnet-range 192.168.178.0/24 \
	--allocation-pool start=192.168.178.20,end=192.168.178.24 \
	ext
fi

openstack router show router >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack router create --ha router
	openstack router set router --external-gateway ext --fixed-ip ip-address=192.168.178.20
	openstack router add subnet router mgmt
	openstack floating ip create --floating-ip-address 192.168.178.21 ext
	openstack floating ip create --floating-ip-address 192.168.178.22 ext
fi

openstack server show trex >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image rhel \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic port-id=$(openstack port show trafficgen_a --format value --column id) \
	--nic port-id=$(openstack port show trafficgen_b --format value --column id) \
	--config-drive true\
	--key-name undercloud \
	--wait \
	trex &
fi

openstack server show testpmd >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image rhel \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic port-id=$(openstack port show reflector_a --format value --column id) \
	--nic port-id=$(openstack port show reflector_b --format value --column id) \
	--config-drive true\
	--key-name undercloud \
	--wait \
	testpmd &
fi

wait

openstack server add floating ip trex 192.168.178.21
openstack server add floating ip testpmd 192.168.178.22

ping -c 5 192.168.178.21
ping -c 5 192.168.178.22
