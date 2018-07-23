#!/bin/bash

export PGDATA="/etc/postgresql/10/main"

# Install dependencies
apt-get -y -qq install ca-certificates sudo

# Install Postgres
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get -y -qq update
sudo apt-get -y -qq upgrade
sudo apt-get -y -qq install postgresql-10
sed -i -e "s/peer/trust/" ${PGDATA}/pg_hba.conf
sudo -u postgres psql -tc "select pg_reload_conf()"

# Done
echo "Your Vagrant box is all set up.  Use 'vagrant ssh' to log in"
