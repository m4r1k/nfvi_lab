#!/bin/bash

source ~/overcloudrc

openstack quota set --ram -1 admin
openstack quota set --cores -1 admin

openstack image show fedora >/dev/null 2>&1 || openstack image create \
	--container-format bare \
	--disk-format raw \
	--min-disk 4 \
	--public \
	--file ~/Fedora-Cloud-Base-30-1.2.x86_64.raw \
	--property hw_disk_bus=scsi \
	--property hw_scsi_model=virtio-scsi \
	--property hw_watchdog_action=reset \
	--property os_require_quiesce=yes \
	--property hw_qemu_guest_agent=yes \
	fedora

openstack flavor show nfv >/dev/null 2>&1 || openstack flavor create \
	--id 10 \
	--ram 16384 \
	--disk 50 \
	--vcpus 16 \
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
	openstack network create --mtu 1500 mgmt
	openstack subnet create --network mgmt --dhcp --subnet-range 192.168.125.0/24 mgmt
fi

openstack network show vlan401 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network datacentre \
	--provider-segment 401 \
	--mtu 8950 \
	vlan401
	openstack subnet create \
	--network vlan401 \
	--dhcp \
	--gateway none \
	--subnet-range 10.20.30.0/24 \
	vlan401
fi

openstack network show ext >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network external \
	--provider-segment 137 \
	--mtu 1500 \
	--external \
	ext
	openstack subnet create \
	--network ext \
	--no-dhcp \
	--subnet-range 10.95.134.0/24 \
	--allocation-pool start=10.95.134.20,end=10.95.134.31 \
	ext
fi

openstack network show vlan406 >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network niantic_pool \
	--provider-segment 406 \
	--mtu 9000 \
	vlan406
	openstack subnet create \
	--network vlan406 \
	--no-dhcp \
	--gateway none \
	--subnet-range 172.19.0.0/24 \
	vlan406

	openstack port create --network vlan406 --fixed-ip ip-address=172.19.0.20 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	--qos-policy policy0 \
	172.19.0.20
	openstack port create --network vlan406 --fixed-ip ip-address=172.19.0.21 \
	--vnic-type direct-physical \
	172.19.0.21
fi

openstack router show router >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack router create --ha router
	openstack router set router --external-gateway ext --fixed-ip ip-address=10.95.134.20
	openstack router add subnet router mgmt
	openstack floating ip create --floating-ip-address 10.95.134.21 ext
	openstack floating ip create --floating-ip-address 10.95.134.22 ext
fi

openstack server show vm-vxlan-dpdk-sriov >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image fedora \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic net-id=$(openstack network show vlan401 --format value --column id) \
	--nic port-id=$(openstack port show 172.19.0.20 --format value --column id) \
	--config-drive true\
	--key-name undercloud \
	--wait \
	vm-vxlan-dpdk-sriov &
fi

openstack server show vm-cinder-vxlan-dpdk-pt >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack volume create --bootable --image fedora --size 50 volume

	openstack server create \
	--volume volume \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic net-id=$(openstack network show vlan401 --format value --column id) \
	--nic port-id=$(openstack port show 172.19.0.21 --format value --column id) \
	--key-name undercloud \
	--wait \
	vm-cinder-vxlan-dpdk-pt &
fi

wait

openstack server add floating ip vm-vxlan-dpdk-sriov 10.95.134.21
openstack server add floating ip vm-cinder-vxlan-dpdk-pt 10.95.134.22

ping -c 5 10.95.134.21
ping -c 5 10.95.134.22

openstack port list --network mgmt --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security

ping -c 5 10.95.134.21
ping -c 5 10.95.134.22

openstack server backup create --wait --name vm-vxlan-dpdk-sriov-snapshot vm-vxlan-dpdk-sriov &
openstack volume snapshot create --force --volume volume vm-cinder-vxlan-dpdk-pt-snapshot &

wait

count=10
while :
do
	openstack volume snapshot show vm-cinder-vxlan-dpdk-pt-snapshot --format value --column status | grep -q available && break
	((count--))
	if (( $count <= 0 ))
	then
		echo "ERROR creating snapshot volume"
		exit 1
	fi
	sleep 3s
done
