#!/bin/bash

useradd postgres
useradd enterprisedb

yum install -y \
  vim \
  rsync \

echo "source /vagrant/scripts/export.sh" >> /home/postgres/.bashrc
echo "source /vagrant/scripts/export.sh" >> /home/enterprisedb/.bashrc