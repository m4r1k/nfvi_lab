#!/bin/bash

echo "#### Removing old image directory content"
rm -rf ~/images

echo "#### Updating local overcloud image packages to the latest version"
sudo rpm -q rhosp-director-images >/dev/null 2>&1 || sudo yum install -y rhosp-director-images
sudo rpm -q rhosp-director-images-ipa >/dev/null 2>&1 || sudo yum install -y rhosp-director-images-ipa
sudo yum update -y rhosp-director-images rhosp-director-images-ipa

echo "#### Extract new overcloud images"
mkdir ~/images
cd ~/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest-16.1.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-16.1.tar; do tar -xvf $i; done

echo "#### Uploading updated overcloud image to the Undercloud's Glance Registry"
source ~/stackrc
openstack overcloud image upload --image-path ~/images/ --update-existing
openstack baremetal node list -c UUID -f value|xargs -n 10 -P 1 -r openstack overcloud node configure

exit 0
