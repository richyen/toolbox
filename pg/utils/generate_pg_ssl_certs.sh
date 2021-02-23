#!/bin/bash

CERT_COMMON_NAME="PG"
CERT_COUNTRY="US"
CERT_STATE="CA"
CERT_CITY="San Diego"
CERT_ORG_UNIT="Postgres"
CERT_EMAIL="richard.yen@edb.com"

# Setup
# Make sure sslutils are installed via yum

su - ${PG_USER} -c "pg_ctl start"
PG_VERSION=$( cat ${PGDATA}/PG_VERSION )
yum -y -q install sslutils_${PG_VERSION} postgresql${PG_VERSION}-contrib
psql -Atqc "CREATE EXTENSION hstore;"
psql -Atqc "CREATE EXTENSION sslutils;"
cd ${PGDATA}

# Certificate Authority
psql -Atqc "SELECT public.openssl_rsa_generate_key(4096);" >  ${PGDATA}/ca_key.key
chown ${PG_USER}:${PG_USER} ${PGDATA}/ca_key.key
chmod 600 ${PGDATA}/ca_key.key

CA_KEY=$(cat ${PGDATA}/ca_key.key)

psql -Atqc "SELECT openssl_csr_to_crt(openssl_rsa_key_to_csr( '${CA_KEY}', '${CERT_COMMON_NAME}', '${CERT_COUNTRY}', '${CERT_STATE}', '${CERT_CITY}', '${CERT_ORG_UNIT}', '${CERT_EMAIL}' ), NULL, '${PGDATA}/ca_key.key');" > ${PGDATA}/ca_certificate.crt
chown ${PG_USER}:${PG_USER} ${PGDATA}/ca_certificate.crt
chmod 600 ${PGDATA}/ca_certificate.crt

# root
cp ${PGDATA}/ca_certificate.crt ${PGDATA}/root.crt
chown ${PG_USER}:${PG_USER} ${PGDATA}/root.crt
chmod 600 ${PGDATA}/root.crt

psql -Atqc "SELECT openssl_rsa_generate_crl('${PGDATA}/ca_certificate.crt', '${PGDATA}/ca_key.key');" > ${PGDATA}/root.crl
chown ${PG_USER}:${PG_USER} ${PGDATA}/root.crl
chmod 600 ${PGDATA}/root.crl

# server
psql -Atqc "SELECT public.openssl_rsa_generate_key(4096);" >> ${PGDATA}/server.key
chown ${PG_USER}:${PG_USER} ${PGDATA}/server.key
chmod 600 ${PGDATA}/server.key

SSL_KEY=$(cat ${PGDATA}/server.key)
psql -Atqc "SELECT openssl_csr_to_crt(openssl_rsa_key_to_csr( '${SSL_KEY}', '${CERT_COMMON_NAME}', '${CERT_COUNTRY}', '${CERT_STATE}', '${CERT_CITY}', '${CERT_ORG_UNIT}', '${CERT_EMAIL}' ), NULL, '${PGDATA}/ca_key.key');" > ${PGDATA}/server.crt
chown ${PG_USER}:${PG_USER} ${PGDATA}/server.crt
chmod 600 ${PGDATA}/server.crt

echo "ssl = on" >> ${PGDATA}/postgresql.conf
su - ${PG_USER} -c "pg_ctl restart"
