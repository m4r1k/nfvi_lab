#!/bin/bash

# Change directory to where this script is located
# Given the above assumption, all path are local ones
cd $(dirname $(readlink -f $0))

_LTHT="$(readlink -f ./)"

# Move to home folder to output the generared files during the deployment there
cd ~/

echo "### Undercloud Installation ###"
read -p "Enter Red Hat Customer Portal Username:" _USERNAME
prompt="Enter Red Hat Customer Portal Password:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    _PASSWORD+="$char"
done; echo
read -p "Enter Red Hat Customer Pool ID:" _POOL

sudo subscription-manager remove --all >/dev/null 2>&1
sudo subscription-manager unregister >/dev/null 2>&1
sudo subscription-manager clean >/dev/null 2>&1

sudo subscription-manager register --username=${_USERNAME} --password=${_PASSWORD} || exit 1
sudo subscription-manager attach --pool=${_POOL} || exit 1
sudo subscription-manager release --set=8.2
sudo subscription-manager repos \
--disable "*" \
--enable rhel-8-for-x86_64-baseos-eus-rpms \
--enable rhel-8-for-x86_64-appstream-eus-rpms \
--enable rhel-8-for-x86_64-highavailability-eus-rpms \
--enable rhel-8-for-x86_64-nfv-rpms \
--enable rhel-8-for-x86_64-rt-rpms \
--enable rhel-8-for-x86_64-supplementary-eus-rpms \
--enable ansible-2.9-for-rhel-8-x86_64-rpms \
--enable advanced-virt-for-rhel-8-x86_64-rpms \
--enable satellite-tools-6.5-for-rhel-8-x86_64-rpms \
--enable openstack-16.1-for-rhel-8-x86_64-rpms \
--enable fast-datapath-for-rhel-8-x86_64-rpms \
--enable rhceph-4-tools-for-rhel-8-x86_64-rpms || exit 1

sudo dnf makecache
sudo dnf module disable -y container-tools:rhel8
sudo dnf module enable -y container-tools:2.0
sudo dnf module disable -y virt:rhel
sudo dnf module enable -y virt:8.2
sudo dnf upgrade -y
sudo dnf install -y vim git bash-completion
sudo dnf install -y python3-tripleoclient ceph-ansible

sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf config-manager --set-disabled epel
sudo dnf --enablerepo=epel install screen -y
cat > ~/.screenrc << EOF
hardstatus alwayslastline
hardstatus string '%{= kG}[ %{G}%H %{g} ][%= %{= kw}%?%-Lw%?%{r} (%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B} %d/%m %{W}%c %{g}]'
termcapinfo xterm* ti@:te@
defscrollback 90000
EOF

# https://github.com/amix/vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_basic_vimrc.sh
cd ~/.vim_runtime
git pull --rebase
python3 update_plugins.py
cd

openstack complete > ~/openstack
sudo mv ~/openstack /etc/bash_completion.d/openstack
sudo sed -e '/^.*INFO.*$/d' -e '/^.*DEBUG.*$/d' -i /etc/bash_completion.d/openstack

grep -q "10.0.10.10 undercloud.local undercloud" /etc/hosts || echo "10.0.10.10 undercloud.local undercloud" | sudo tee -a /etc/hosts
sudo hostnamectl set-hostname undercloud.local
sudo hostnamectl set-hostname --transient undercloud.local

ln -s ${_LTHT}/undercloud.conf ~/
ln -s ${_LTHT}/custom_hieradata.yaml ~/
cp ${_LTHT}/containers-prepare-parameter.yaml ~/
cat >> ~/containers-prepare-parameter.yaml << EOF
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      ${_USERNAME}: '${_PASSWORD}'
EOF

mkdir /home/stack/builddir/

openstack undercloud install

ln -s ~/builddir/undercloud-passwords.conf ~/
