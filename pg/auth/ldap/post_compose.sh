#!/bin/bash
# Use [LDAP Cert setup guide](https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls) as reference if necessary

docker exec -it pg yum -y install openldap-clients
docker exec pg bash -c "echo 'TLS_CACERT /etc/openldap/ca_certs.pem' >> /etc/openldap/ldap.conf"
docker cp certs/ca_server.pem pg:/etc/openldap/ca_certs.pem
