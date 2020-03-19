#!/bin/bash

source /root/vBMC/bin/activate

ip addr show br0 | grep -q "192.168.178.25/24" || ip addr add 192.168.178.25/24 dev br0
ip addr show br0 | grep -q "192.168.178.26/24" || ip addr add 192.168.178.26/24 dev br0
ip addr show br0 | grep -q "192.168.178.27/24" || ip addr add 192.168.178.27/24 dev br0
ip addr show br0 | grep -q "192.168.178.28/24" || ip addr add 192.168.178.28/24 dev br0
ip addr show br0 | grep -q "192.168.178.29/24" || ip addr add 192.168.178.29/24 dev br0
ip addr show br0 | grep -q "192.168.178.30/24" || ip addr add 192.168.178.30/24 dev br0

vbmcd

vbmc show CEPH0 2>/dev/null || vbmc add --username root --password calvin --address 192.168.178.25 --port 623 CEPH0
vbmc show CEPH1 2>/dev/null || vbmc add --username root --password calvin --address 192.168.178.26 --port 623 CEPH1
vbmc show CEPH2 2>/dev/null || vbmc add --username root --password calvin --address 192.168.178.27 --port 623 CEPH2
vbmc show CTRL0 2>/dev/null || vbmc add --username root --password calvin --address 192.168.178.28 --port 623 CTRL0
vbmc show CTRL1 2>/dev/null || vbmc add --username root --password calvin --address 192.168.178.29 --port 623 CTRL1
vbmc show CTRL2 2>/dev/null || vbmc add --username root --password calvin --address 192.168.178.30 --port 623 CTRL2

vbmc show CEPH0 | grep status | grep -q running || vbmc start CEPH0
vbmc show CEPH1 | grep status | grep -q running || vbmc start CEPH1
vbmc show CEPH2 | grep status | grep -q running || vbmc start CEPH2
vbmc show CTRL0 | grep status | grep -q running || vbmc start CTRL0
vbmc show CTRL1 | grep status | grep -q running || vbmc start CTRL1
vbmc show CTRL2 | grep status | grep -q running || vbmc start CTRL2

ipmitool -H 192.168.178.25 -U root -P calvin -p 623 -I lanplus power status
ipmitool -H 192.168.178.26 -U root -P calvin -p 623 -I lanplus power status
ipmitool -H 192.168.178.27 -U root -P calvin -p 623 -I lanplus power status
ipmitool -H 192.168.178.28 -U root -P calvin -p 623 -I lanplus power status
ipmitool -H 192.168.178.29 -U root -P calvin -p 623 -I lanplus power status
ipmitool -H 192.168.178.30 -U root -P calvin -p 623 -I lanplus power status
