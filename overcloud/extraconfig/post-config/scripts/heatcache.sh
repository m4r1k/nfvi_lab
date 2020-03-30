#!/bin/bash

crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf cache enabled true
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf cache memcache_servers 'overcloud-controller-0.internalapi:11211,overcloud-controller-1.internalapi:11211,overcloud-controller-2.internalapi:11211'
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf cache memcache_dead_retry 600
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf cache memcache_socket_timeout 1
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf cache memcache_pool_unused_timeout 10
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf cache memcache_pool_connection_get_timeout 1
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf constraint_validation_cache caching true
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf service_extension_cache caching true
crudini --set /var/lib/config-data/puppet-generated/heat/etc/heat/heat.conf resource_finder_cache caching true

podman ps --filter name=heat --quiet|xargs -n1 podman restart

exit 0
