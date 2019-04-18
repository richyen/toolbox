FROM epas11:latest

ARG YP
RUN sed -i "s/:@/edb-richardyen:${YP}@/" /etc/yum.repos.d/edb.repo
RUN yum -y --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies install edb-migrationtoolkit java-1.8.0-openjdk-devel unzip libaio
COPY toolkit.properties /usr/edb/migrationtoolkit/etc
RUN chmod 700 /usr/edb/migrationtoolkit/etc/toolkit.properties
RUN chown enterprisedb:enterprisedb /usr/edb/migrationtoolkit/etc/toolkit.properties

ENV oic="instantclient-basic-linux.x64-12.2.0.1.0.zip"
ENV sdk="instantclient-sdk-linux.x64-12.2.0.1.0.zip"
ENV ohome="/u01/app/oracle/product/12.2.0/dbhome_1"
COPY ${oic} /tmp/
COPY ${sdk} /tmp/
RUN unzip /tmp/${oic}
RUN unzip /tmp/${sdk}
RUN mkdir -p ${ohome}/lib
RUN cp /instantclient_12_2/lib* ${ohome}/lib
RUN mkdir -p ${ohome}/rdbms/public
RUN cp /instantclient_12_2/sdk/include/*.h ${ohome}/rdbms/public
RUN cp /instantclient_12_2/ojdbc8.jar /usr/edb/migrationtoolkit/lib/
# COPY ojdbc7.jar /usr/edb/migrationtoolkit/lib/

RUN echo "export ORACLE_HOME=${ohome}" >> /etc/bashrc
RUN echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/bashrc
RUN echo 'export ORACLE_SID=ORCLCDB' >> /etc/bashrc
RUN echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH' >> /etc/bashrc
RUN echo "export ORACLE_HOME=${ohome}" >> /etc/profile
RUN echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/profile
RUN echo 'export ORACLE_SID=ORCLCDB' >> /etc/profile
RUN echo 'export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH' >> /etc/profile
RUN ln -s ${ohome}/lib/libclntsh.so.12.1 ${ohome}/lib/libclntsh.so
RUN ln -s ${ohome}/lib/libclntsh.so.12.1 /lib64
RUN ln -s ${ohome}/lib/libclntsh.so /lib64
RUN ln -s ${ohome}/lib/libnnz12.so /lib64

CMD service edb-as-11 start && tail -F /var/lib/edb/as11/pgstartup.log
