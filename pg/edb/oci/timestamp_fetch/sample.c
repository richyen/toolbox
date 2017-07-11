#include <stdio.h>
#include <stdlib.h>
#include <oci.h>
#include <string.h>

#include "helpers.c"

int main(int argc, char *argv[])
{
    OCIStmt     *stmt;
    const char  *query = "SELECT now()";
    OCIDefine   *defineHandle;
	sb2			 nullIndicator;
	OCIDateTime *timestamp;
    sb2			 year;
    ub1			 month, day;
    ub1			 hour,	min, sec;
    ub4			 fsec;

	/* 
	 * connect to the database... this call also allocates and
	 * initializes an OCIEnv handle (env), an OCIError handle (err),
	 * and an OCISvcCtx handle (svc)
	 */
	logon(argc, argv);

	/* Allocate a statement handle and prepare the statement */
    OCIHandleAlloc(env, (void **)&stmt, OCI_HTYPE_STMT, 0, NULL);
    check_oci_err(err, OCIStmtPrepare(stmt, err, (OraText *)query, strlen(query), OCI_NTV_SYNTAX, OCI_DEFAULT));

	/* Allocate (and initialize) an OCIDateTime descriptor */
    OCIDescriptorAlloc(env, (void **)&timestamp, OCI_DTYPE_TIMESTAMP, 0, NULL);

	/* and define that descriptor as the output buffer for column #1 in the result set */
	check_oci_err(err, OCIDefineByPos(stmt, &defineHandle, err, (ub4) 1, (dvoid*)&timestamp, (sb4) sizeof(timestamp), SQLT_TIMESTAMP, &nullIndicator, NULL, NULL, OCI_DEFAULT));

	/* Execute the query and fetch 1 row... */
    check_oci_err(err, OCIStmtExecute(svc, stmt, err, 1, 0, NULL, NULL, OCI_DEFAULT));

	/* Display the results */
    OCIDateTimeGetDate(env, err, timestamp, &year, &month, &day);
    OCIDateTimeGetTime(env, err, timestamp, &hour, &min, &sec, &fsec);

    printf("Fetched the following date %02d-%02d-%04d:%02d-%02d-%02d %06d (%s)\n", day, month, year, hour, min, sec, fsec, "DD-MM-YYYY:HH-MI-SS fsec");

}
