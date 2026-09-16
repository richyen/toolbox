# HammerDB CLI auto-script: build the TPROC-C (TPC-C-like) schema on
# the target postgres database. Run with:
#   hammerdbcli auto demo-scripts/build.tcl
puts "SETTING CONFIGURATION"
dbset db pg
dbset bm TPC-C

diset connection pg_host $env(PGHOST)
diset connection pg_port $env(PGPORT)

diset tpcc pg_superuser postgres
diset tpcc pg_superuserpass postgres
diset tpcc pg_defaultdbase postgres
diset tpcc pg_dbase tpcc
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc

# Small warehouse count so the build finishes quickly for a demo
diset tpcc pg_count_ware 5
diset tpcc pg_num_vu 4
diset tpcc pg_vacuum true

print dict

puts "BUILDING SCHEMA"
buildschema
puts "SCHEMA BUILD COMPLETE"

exit
