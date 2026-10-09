# HammerDB CLI auto-script: run two SF 1 TPROC-H query streams
# (the HammerDB Throughput Test stream count for SF 1).
# Run with: hammerdbcli auto demo-scripts/run-tproch-throughput.tcl
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

vuset vu 2

print dict

loadscript
puts "STARTING TPROC-H THROUGHPUT TEST"
vucreate
vurun
vudestroy

puts "TPROC-H THROUGHPUT TEST COMPLETE"
exit
