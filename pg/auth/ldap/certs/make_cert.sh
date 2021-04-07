#!/bin/bash

set -e
set -x

# Make sure openssl is installed
# yum -y -q install openssl

SUBJ="/C=US/ST=MA/L=Bedford/O=edb/OU=edb/CN=ldap-service"
# DIR="/docker/certs"
DIR="."

openssl genrsa 2048 > ${DIR}/ldap_server.key
chmod 400 ${DIR}/ldap_server.key
openssl req -config ${DIR}/openssl.cnf -new -x509 -days 3650 -key ${DIR}/ldap_server.key -out ${DIR}/ldap_server.pem -subj "${SUBJ}"
# cp ${DIR}/ldap_server.pem ${DIR}/ca_server.pem
