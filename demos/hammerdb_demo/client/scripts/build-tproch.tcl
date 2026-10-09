# HammerDB CLI auto-script: build an SF 1 TPROC-H schema on PostgreSQL.
# Run with: hammerdbcli auto demo-scripts/build-tproch.tcl
puts "SETTING CONFIGURATION"
dbset db pg
dbset bm TPC-H

diset connection pg_host $env(PGHOST)
diset connection pg_port $env(PGPORT)

diset tpch pg_tpch_superuser $env(PGUSER)
diset tpch pg_tpch_superuserpass $env(PGPASSWORD)
diset tpch pg_tpch_defaultdbase $env(PGDATABASE)
diset tpch pg_tpch_dbase tpch
diset tpch pg_tpch_user tpch
diset tpch pg_tpch_pass tpch

# SF 1 is about 1 GB of raw data; keep the demo build to one loader thread.
diset tpch pg_scale_fact 1
diset tpch pg_num_tpch_threads 1

print dict

puts "BUILDING TPROC-H SCHEMA"
buildschema
puts "TPROC-H SCHEMA BUILD COMPLETE"

exit
