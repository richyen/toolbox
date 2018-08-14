A quick startup guide for setting up ODBC on CentOS

1. execute following command odbcinst -j on terminal.You will see following output and confirm that you have updated respective odbc.ini file.
```
user@ubuntu:~/Downloads/unixODBC-2.3.1$ odbcinst -j
unixODBC 2.2.14
DRIVERS............: /etc/odbcinst.ini
SYSTEM DATA SOURCES: /etc/odbc.ini
FILE DATA SOURCES..: /etc/ODBCDataSources
USER DATA SOURCES..: /home/user/.odbc.ini
SQLULEN Size.......: 8
SQLLEN Size........: 8
SQLSETPOSIROW Size.: 8
```
2. You can directly add Driver in odbc.ini file (ignoring odbcinst.ini file). Following is the example.
```
[edb]
Driver=/path/to/edb-odbc.so
Description=Connection to LDAP/POSTGRESQL
Servername=localhost
Port=5444
Protocol=7.4
FetchBufferSize=99
Username=enterprisedb
Password=edb
Database=edb
ReadOnly=no
Debug=1
UseServerSidePrepare=1
UseDeclareFetch=1
CommLog=1
```
3. Use 'isql' utility ( installed as part of unixODBC) to confirm if DSN is configured correctly.
```
user@ubuntu:~/Downloads/unixODBC-2.3.1$ isql  edb -v3
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL>
```
4. execute the desired application ( refer to same DSN you have configured and verified using isql' utility.
