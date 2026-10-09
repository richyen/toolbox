# HammerDB CLI auto-script: run one SF 1 TPROC-H query stream (Power Test).
# Run with: hammerdbcli auto demo-scripts/run-tproch-power.tcl
puts "SETTING CONFIGURATION"
dbset db pg
dbset bm TPC-H

diset connection pg_host $env(PGHOST)
diset connection pg_port $env(PGPORT)

diset tpch pg_tpch_dbase tpch
diset tpch pg_tpch_user tpch
diset tpch pg_tpch_pass tpch
diset tpch pg_total_querysets 1
diset tpch pg_verbose true

vuset vu 1

print dict

loadscript
puts "STARTING TPROC-H POWER TEST"
vucreate
vurun
vudestroy

puts "TPROC-H POWER TEST COMPLETE"
exit
