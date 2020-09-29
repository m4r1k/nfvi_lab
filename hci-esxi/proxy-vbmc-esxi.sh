#!/bin/bash

# Make sure Subscription is done
# Make sure packages can be downloaded

subscription-manager attach --pool 8a85f99c6e417e37016e6c2fb8180766

subscription-manager repos \
--disable "*" \
--enable rhel-8-for-x86_64-baseos-rpms \
--enable rhel-8-for-x86_64-appstream-rpms \
--enable rhel-8-for-x86_64-supplementary-rpms \
--enable codeready-builder-for-rhel-8-x86_64-rpms

dnf makecache

dnf upgrade -y

dnf install -y ipmitool lsof tcpdump vim git

dnf install -y python3-virtualenv python3-libvirt libvirt-devel gcc make
virtualenv /root/vBMC
source /root/vBMC/bin/activate
pip install --upgrade pip
pip install virtualbmc==2.2.0
firewall-cmd --zone=public --permanent --add-port=623/udp
firewall-cmd --reload

# Do not accept forwarded locale
sed -e 's/^\(AcceptEnv LANG.*\)/#\1/g' -e 's/^\(AcceptEnv LC_.*\)/#\1/g' -i /etc/ssh/sshd_config
systemctl restart sshd

echo "## REBOOT THE vBMC PROXY PLEASE ##"
