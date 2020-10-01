#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import shutil
from pathlib import Path
from six.moves import configparser
from tripleo_common.actions import ansible

output_dir = '/home/stack/config-download'
ansible_cfg = 'ansible.cfg'
deployment_user = 'tripleo-admin'
ssh_private_key = '/var/lib/mistral/overcloud/ssh_private_key'

fact_caching_connection = '/tmp/ansible_fact_cache'

print ("Starting {} export...".format(ansible_cfg))

ansible.write_default_ansible_cfg(output_dir, deployment_user,
                                  ssh_private_key)

ansible_config_path = os.path.join(output_dir, ansible_cfg)
config = configparser.ConfigParser()
config.read(ansible_config_path)
config.set('defaults', 'fact_caching_connection',
           fact_caching_connection)
config.set('defaults', 'host_key_checking', 'false')

with open(ansible_config_path, 'w') as configfile:
    config.write(configfile)

dirpath = Path(fact_caching_connection)
if dirpath.exists() and dirpath.is_dir():
    shutil.rmtree(dirpath)

print("The {} configuration has been successfully generated into: {}".format(ansible_cfg,
        output_dir))

sys.exit(0)
