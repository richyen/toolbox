Steps to get things going:
  1. `docker-compose up -d`
  1. `yum -y install openldap-clients` on `pg` container
  1. Append `TLS_CACERT /etc/openldap/ca_certs.pem` to `/etc/openldap/ldap.conf` in `pg` container
  1. Copy `certs/ca_server.pem` into `/etc/openldap/ca_certs.pem` folder in `pg` container
  1. Test

Use [LDAP Cert setup guide](https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls) as reference if necessary
