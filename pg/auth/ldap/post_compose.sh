#!/bin/bash

# Use [LDAP Cert setup guide](https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls) as reference if necessary
docker exec -it pg yum -y install openldap-clients
docker exec pg bash -c "echo 'TLS_CACERT /etc/openldap/ca_certs.pem' >> /etc/openldap/ldap.conf"
docker cp certs/ca_server.pem pg:/etc/openldap/ca_certs.pem

# If having trouble auto-loading bootstrap.ldif via docker-compose.yml, use these 2 steps below
# docker cp ldif/bootstrap.ldif pg:/tmp/bootstrap.ldif
# docker exec pg ldapmodify -x -H "ldap://ldap-service" -D "cn=admin,dc=example,dc=org" -w admin -f /tmp/bootstrap.ldif
