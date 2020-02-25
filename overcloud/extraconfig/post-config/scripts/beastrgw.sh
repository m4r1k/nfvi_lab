#!/bin/bash

grep -q "rgw frontends = civetweb" /etc/ceph/ceph.conf
if [[ "$?" == "0" ]]; then
	sed -e "s/rgw frontends = civetweb port/rgw frontends = beast endpoint/g" -i /etc/ceph/ceph.conf
	docker ps --filter name=rgw --quiet | xargs -n1 -r docker restart
fi

exit 0
