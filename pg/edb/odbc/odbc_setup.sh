#!/bin/bash

## Assumes edb.repo is already installed and configured
yum -y --enablerepo=enterprisedb-dependencies --enablerepo=enterprisedb-tools install edb-odbc

INIFILE=`odbcinst -j | grep "SYSTEM DATA SOURCES" | cut -f2 -d ':'`

cat << EOF > $INIFILE
[edb]
Driver=/usr/edb/connectors/odbc/edb-odbc.so
Description=Connection to LDAP/POSTGRESQL
Servername=127.0.0.1
Port=5432
Protocol=7.4
FetchBufferSize=99
Username=enterprisedb
Password=edb
Database=edb
ReadOnly=no
Debug=1
UseServerSidePrepare=1
UseDeclareFetch=1
CommLog=1
EOF

echo "SELECT * FROM pg_class LIMIT 1" | isql edb -v3
