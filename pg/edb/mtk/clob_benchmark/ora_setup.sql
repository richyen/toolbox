CREATE TABLESPACE FOOCLOB DATAFILE '/u01/app/oracle/oradata/XE/fooclob.dbf' size 3G extent management local autoallocate;
ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/XE/fooclob.dbf' AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;
CREATE TABLE HR.FOOLOB (n NUMBER, c CLOB) LOB (c) STORE AS BASICFILE ctbspc (tablespace "FOOCLOB" CHUNK 8192 NOCACHE NOLOGGING);
