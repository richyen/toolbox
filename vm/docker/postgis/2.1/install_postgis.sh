#!/bin/bash

service postgresql-9.4 start

psql -c "CREATE EXTENSION postgis;" template1 postgres
psql -c "CREATE EXTENSION postgis_topology;" template1 postgres
psql -c "CREATE EXTENSION fuzzystrmatch;" template1 postgres
psql -c "CREATE EXTENSION postgis_tiger_geocoder;" template1 postgres

createdb -U postgres postgis_test
