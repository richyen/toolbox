#!/bin/bash

# Simple script to set up and install pljava on an EDB Posgres Advanced Server instance.
# Assumes you have access to EDB's Yum Repository

if [[ "${1}x" == "x" ]]
then
  echo "Usage: $0 <major version>"
  echo "Assumes you are using version 9.x"
  exit
fi

MAJOR_VERSION=${1}

if [[ $1 -lt 6 ]]
then
  yum -y install java-1.7.0-openjdk-devel ppas9${MAJOR_VERSION}-pljava
  echo "pljava.libjvm_location = '/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.141.x86_64/jre/lib/amd64/server/libjvm.so'" >> /var/lib/ppas/9.${MAJOR_VERSION}/data/postgresql.conf 
  echo "pljava.classpath = '/usr/ppas-9.${MAJOR_VERSION}/lib/pljava.jar'" >> /var/lib/ppas/9.${MAJOR_VERSION}/data/postgresql.conf 
  ln -s /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.141.x86_64/jre/lib/amd64/server/libjvm.so /lib64
  service ppas-9.${MAJOR_VERSION} restart
  psql < /usr/ppas-9.${MAJOR_VERSION}/share/pljava_install.sql
else
  yum --enablerepo=edbas96 -y install edb-as96-pljava
  echo "pljava.libjvm_location = '/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.141-2.b16.el6_9.x86_64/jre/lib/amd64/server/libjvm.so'" >> /var/lib/edb/as9.6/data/postgresql.conf
  service edb-as-9.6 restart
  psql -c "CREATE EXTENSION pljava"
fi
