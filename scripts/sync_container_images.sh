#!/bin/bash

_REREG="registry.access.redhat.com"
_LOREG="$(hostname -f)"

_CEPH="rhceph/rhceph-3-rhel7"
_CEPHVER="3"
for _TAG in $(skopeo inspect docker://${_REREG}/${_CEPH}:latest|jq '.RepoTags'|grep ${_CEPHVER}|sed -e 's/[",\ ]//g'|sort -n -k1.3|tail -4)
do
	skopeo copy docker://${_REREG}/${_CEPH}:${_TAG} docker://${_LOREG}/${_CEPH}:${_TAG}
done
skopeo copy docker://${_REREG}/${_CEPH}:latest docker://${_LOREG}/${_CEPH}:latest

_OSP[0]="rhosp13/openstack-aodh-api"
_OSP[1]="rhosp13/openstack-aodh-evaluator"
_OSP[2]="rhosp13/openstack-aodh-listener"
_OSP[3]="rhosp13/openstack-aodh-notifier"
_OSP[4]="rhosp13/openstack-ceilometer-central"
_OSP[5]="rhosp13/openstack-ceilometer-compute"
_OSP[6]="rhosp13/openstack-ceilometer-notification"
_OSP[7]="rhosp13/openstack-cinder-api"
_OSP[8]="rhosp13/openstack-cinder-backup"
_OSP[9]="rhosp13/openstack-cinder-scheduler"
_OSP[10]="rhosp13/openstack-cinder-volume"
_OSP[11]="rhosp13/openstack-cron"
_OSP[12]="rhosp13/openstack-glance-api"
_OSP[13]="rhosp13/openstack-gnocchi-api"
_OSP[14]="rhosp13/openstack-gnocchi-metricd"
_OSP[15]="rhosp13/openstack-gnocchi-statsd"
_OSP[16]="rhosp13/openstack-haproxy"
_OSP[17]="rhosp13/openstack-heat-api-cfn"
_OSP[18]="rhosp13/openstack-heat-api"
_OSP[19]="rhosp13/openstack-heat-engine"
_OSP[20]="rhosp13/openstack-horizon"
_OSP[21]="rhosp13/openstack-iscsid"
_OSP[22]="rhosp13/openstack-keystone"
_OSP[23]="rhosp13/openstack-mariadb"
_OSP[24]="rhosp13/openstack-memcached"
_OSP[25]="rhosp13/openstack-neutron-dhcp-agent"
_OSP[26]="rhosp13/openstack-neutron-l3-agent"
_OSP[27]="rhosp13/openstack-neutron-metadata-agent"
_OSP[28]="rhosp13/openstack-neutron-openvswitch-agent"
_OSP[29]="rhosp13/openstack-neutron-server"
_OSP[30]="rhosp13/openstack-neutron-sriov-agent"
_OSP[31]="rhosp13/openstack-nova-api"
_OSP[32]="rhosp13/openstack-nova-compute"
_OSP[33]="rhosp13/openstack-nova-conductor"
_OSP[34]="rhosp13/openstack-nova-consoleauth"
_OSP[35]="rhosp13/openstack-nova-libvirt"
_OSP[36]="rhosp13/openstack-nova-novncproxy"
_OSP[37]="rhosp13/openstack-nova-placement-api"
_OSP[38]="rhosp13/openstack-nova-scheduler"
_OSP[39]="rhosp13/openstack-panko-api"
_OSP[40]="rhosp13/openstack-rabbitmq"
_OSP[41]="rhosp13/openstack-redis"
_OSPVER="13.0"
for _IMG in "${_OSP[@]}"
do
	for _TAG in $(skopeo inspect docker://${_REREG}/${_IMG}:latest|jq '.RepoTags'|grep ${_OSPVER}|sed -e 's/[",\ ]//g'|sort -n -k1.6|tail -4)
	do
		skopeo copy docker://${_REREG}/${_IMG}:${_TAG} docker://${_LOREG}/${_IMG}:${_TAG}
	done
	skopeo copy docker://${_REREG}/${_IMG}:latest docker://${_LOREG}/${_IMG}:latest
done

exit 0
