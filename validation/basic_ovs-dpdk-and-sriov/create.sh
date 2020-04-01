#!/bin/bash

_IMAGE=Fedora-Cloud-Base-31-1.9.x86_64.qcow2
_URL=https://download.fedoraproject.org/pub/fedora/linux/releases/31/Cloud/x86_64/images/${_IMAGE}

if [ ! -f ~/${_IMAGE} ]; then
        curl -o ~/${_IMAGE} -L ${_URL}
fi

source ~/overcloudrc

openstack quota set --ram -1 admin
openstack quota set --cores -1 admin

openstack image show fedora >/dev/null 2>&1 || openstack image create \
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
	fedora

openstack flavor show nfv >/dev/null 2>&1 || openstack flavor create \
	--id 10 \
	--ram 16384 \
	--disk 10 \
	--vcpus 7 \
	--public \
    --property resources:PCPU=7 \
    --property trait:HW_CPU_HYPERTHREADING=required \
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

openstack network show vlan2000-dpdk >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network datacentre0 \
	--provider-segment 2000 \
	--mtu 9000 \
	vlan2000-dpdk
	openstack subnet create \
	--network vlan2000-dpdk \
	--dhcp \
	--gateway none \
	--subnet-range 10.20.0.0/25 \
	vlan2000-dpdk
fi

openstack network show vlan2000-sriov >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack network create \
	--provider-network-type vlan \
	--provider-physical-network niantic_pool \
	--provider-segment 2000 \
	--mtu 9000 \
	vlan2000-sriov
	openstack subnet create \
	--network vlan2000-sriov \
	--dhcp \
	--gateway none \
	--subnet-range 10.20.0.128/25 \
	vlan2000-sriov

	openstack port create --network vlan2000-sriov --fixed-ip ip-address=10.20.0.221 \
	--vnic-type direct --binding-profile type=dict --binding-profile trusted=true \
	10.20.0.221
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

openstack server show vm-dpdk >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image fedora \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
	--nic net-id=$(openstack network show vlan2000-dpdk --format value --column id) \
	--config-drive true\
	--key-name undercloud \
	--wait \
	vm-dpdk &
fi

openstack server show vm-sriov >/dev/null 2>&1
if [[ "$?" != "0" ]]; then
	openstack server create \
	--image fedora \
	--flavor nfv \
	--nic net-id=$(openstack network show mgmt --format value --column id) \
        --nic port-id=$(openstack port show 10.20.0.221 --format value --column id) \
	--key-name undercloud \
	--wait \
	vm-sriov
fi

wait

openstack server add floating ip vm-dpdk 192.168.178.21
openstack server add floating ip vm-sriov 192.168.178.22

ping -c 5 192.168.178.21
ping -c 5 192.168.178.22

openstack port list --network mgmt --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security
openstack port list --network vlan2000-dpdk --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security
openstack port list --network vlan2000-sriov --format value --column ID | xargs -n1 openstack port set --no-security-group --disable-port-security

ping -c 5 192.168.178.21
ping -c 5 192.168.178.22
