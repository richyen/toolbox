#!/bin/bash

# Simple script to set up and install pljava on an EDB Posgres Advanced Server instance.
# Assumes you have access to EDB's Yum Repository

if [[ `psql -Atc "SELECT current_setting('server_version_num');" | cut -f1 -d'0'` -ne 9 ]]
then
  echo "This script only compatible with PG 9.x"
  exit
fi

MAJOR_VERSION=`psql -Atc "SELECT current_setting('server_version_num');" | cut -f2 -d'0'`

if [[ $MAJOR_VERSION -lt 6 ]]
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
  echo "pljava.classpath = '/usr/edb/as9.6/lib/pljava.jar'" >> /var/lib/edb/as9.6/data/postgresql.conf
  ln -s /usr/edb/as9.6/share/pljava/pljava-1.5.0.jar /usr/edb/as9.6/lib/pljava.jar
  ln -s /usr/edb/as9.6/lib/libpljava-so-1.5.0.so /usr/edb/as9.6/lib/pljava.so
  service edb-as-9.6 restart
  psql -c "CREATE EXTENSION pljava"
fi
