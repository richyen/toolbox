# XDB Scalability Test
Steps to set up:
* Use [vm_setup.sh](https://github.com/richyen/toolbox/blob/master/pg/edb/epas/vm_setup.sh) to set up a VM
  * Also use [build_xdb_mmr_publication.sh](https://github.com/richyen/ppas_and_docker/blob/master/xdb/6.0/build_xdb_mmr_publication.sh) to expedite XDB setup
  * Be sure to include any custom PG/XDB configs as indicated in the script
* Set up stats gathering with `gather_stats.sh`
  * Note this gathers and prints data to be piped into Graphite
* Set up `iostat` and `vmstat` stats-gathering as needed 
* Run `load_test.sh`
