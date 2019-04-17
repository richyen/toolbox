FROM epas11:latest

ARG YP
RUN sed -i "s/:@/edb-richardyen:${YP}@/" /etc/yum.repos.d/edb.repo
RUN yum -y --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies install edb-migrationtoolkit java-1.7.0-openjdk-devel unzip libaio
COPY toolkit.properties /usr/edb/migrationtoolkit/etc
RUN chmod 700 /usr/edb/migrationtoolkit/etc/toolkit.properties
COPY ojdbc6.jar /usr/edb/migrationtoolkit/lib/

COPY instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/
COPY instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/
RUN unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip
RUN unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip
RUN mkdir -p /u01/app/oracle/product/11.2.0/xe/lib
RUN cp /instantclient_11_2/lib* /u01/app/oracle/product/11.2.0/xe/lib
RUN mkdir -p /u01/app/oracle/product/11.2.0/xe/rdbms/public
RUN cp /instantclient_11_2/sdk/include/*.h /u01/app/oracle/product/11.2.0/xe/rdbms/public

RUN echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> /etc/bashrc
RUN echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/bashrc
RUN echo 'export ORACLE_SID=XE' >> /etc/bashrc
RUN echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH' >> /etc/bashrc
RUN echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> /etc/profile
RUN echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/profile
RUN echo 'export ORACLE_SID=XE' >> /etc/profile
RUN echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH' >> /etc/profile
RUN ln -s /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so.11.1 /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so
RUN ln -s /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so.11.1 /lib64
RUN ln -s /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so /lib64
RUN ln -s /u01/app/oracle/product/11.2.0/xe/lib/libnnz11.so /lib64

CMD service edb-as-11 start && tail -F /var/lib/edb/as11/pgstartup.log
