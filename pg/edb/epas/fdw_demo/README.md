# FDW Oracle Demo

This simple library of scripts sets up an Oracle 11 XE container and a PG 9.5 container to demonstrate the ability to query an Oracle database from a PG database using both `oracle_fdw` and EnterpriseDB's `edb_dblink_oci` extensions.

As of this commit, the installation and configuration of the Oracle Instant Client is not fully-automated, and needs to be set up manually.  Also bear in mind that the compile/install of `oracle_fdw` is not automated--users will still need to open a Bash prompt and run the makefile manually

Users wishing to run this program should follow the steps in `fdw_demo.sh` -- all other files in this directory are called by `fdw_demo.sh`
