#!/bin/bash

set -e
set -x

# Make sure openssl is installed
yum -y -q install openssl

SUBJ="/C=US/ST=MA/L=Bedford/O=edb/OU=edb/CN=ldap-service"

openssl genrsa 2048 > /docker/certs/ldap_server.key
chmod 400 /docker/certs/ldap_server.key
openssl req -config /docker/certs/openssl.cnf -new -x509 -days 3650 -key /docker/certs/ldap_server.key -out /docker/certs/ldap_server.pem -subj "${SUBJ}"
cp /docker/certs/ldap_server.pem /docker/certs/ca_server.pem
