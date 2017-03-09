ORACLE_HOME = /u01/app/oracle/product/11.2.0/xe

CC=g++
CPPFLAGS=-Wall -g -I$(ORACLE_HOME)/rdbms/public -L/usr/ppas/connectors/oci/lib -ledboci

SAMPLES = OCIConnector

all: $(SAMPLES)

%:%.o
	$(CC) $(CPPFLAGS) -o $@
clean:
	rm -rf $(SAMPLES)
