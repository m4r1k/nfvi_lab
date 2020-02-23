#!/bin/bash

# this is for a virtual lab, so let's fake Linux rotational reporting
echo 0 > /sys/block/sdb/queue/rotational

exit 0
