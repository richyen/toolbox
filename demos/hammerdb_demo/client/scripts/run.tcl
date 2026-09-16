# HammerDB CLI auto-script: run a short TPROC-C driver test against
# the schema created by build.tcl. Run with:
#   hammerdbcli auto demo-scripts/run.tcl
puts "SETTING CONFIGURATION"
dbset db pg
dbset bm TPC-C

diset connection pg_host $env(PGHOST)
diset connection pg_port $env(PGPORT)

diset tpcc pg_dbase tpcc
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc

diset tpcc pg_driver timed
diset tpcc pg_rampup 1
diset tpcc pg_duration 2
diset tpcc pg_allwarehouse false
diset tpcc pg_timeprofile false

vuset vu 4
vuset logtotemp 1

print dict

loadscript
puts "STARTING VIRTUAL USERS"
vucreate
vurun
vudestroy

puts "TPROC-C RUN COMPLETE"
exit
