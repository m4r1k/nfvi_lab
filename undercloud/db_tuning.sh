#!/bin/bash

rpm -q crudini >/dev/null 2>&1 || sudo yum install crudini -y

sudo crudini --set /etc/my.cnf.d/galera.cnf mysqld max_connections 8192
sudo crudini --set /etc/my.cnf.d/galera.cnf mysqld innodb_buffer_pool_size 2G
sudo crudini --set /etc/my.cnf.d/galera.cnf mysqld innodb_buffer_pool_instances 4
sudo crudini --set /etc/my.cnf.d/galera.cnf mysqld tmp_table_size 128M
sudo crudini --set /etc/my.cnf.d/galera.cnf mysqld connect_timeout 60
sudo systemctl restart mariadb

exit 0
