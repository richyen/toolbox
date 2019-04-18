ALTER SESSION SET "_ORACLE_SCRIPT"=true;
CREATE USER HR IDENTIFIED BY HR;
GRANT CREATE SESSION TO HR;
CREATE TABLESPACE FOOCLOB DATAFILE '/ORCL/u02/app/oracle/oradata/ORCLCDB/fooclob.dbf' size 3G extent management local autoallocate;
ALTER DATABASE DATAFILE '/ORCL/u02/app/oracle/oradata/ORCLCDB/fooclob.dbf' AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;
CREATE TABLE HR.FOOLOB (n NUMBER, c CLOB) LOB (c) STORE AS BASICFILE ctbspc (tablespace "FOOCLOB" CHUNK 8192 NOCACHE NOLOGGING);
ALTER USER HR DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
ALTER USER HR QUOTA UNLIMITED ON fooclob;

create procedure HR.my_proc (numrows number, rowsize number) as
begin
 for lc in 1..numrows loop
 insert into HR.FOOLOB (n, c)
 values (lc, rpad('*',rowsize,'*'));
 end loop;
 commit;
end;
/
