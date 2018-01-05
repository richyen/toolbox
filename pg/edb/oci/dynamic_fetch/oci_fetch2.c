#include <stdio.h>
#include <stdlib.h>
#include <oci.h>
#include <string.h>


void check_oci_env_err(OCIEnv *env, sword retCode);
void check_oci_err(OCIError *err, sword retCode);

int main(int nargs, char *args[])
{
    OCIEnv    *env;
    OCIError  *err;
    OCISvcCtx *svc;
    OraText   *username = (OraText *) "enterprisedb";
    OraText   *password = (OraText *) "edb";
    OraText   *dbname = (OraText *) "//127.0.0.1/edb";
    OCIStmt   *stmt;
    OCIDefine *def;
  char      *value;
  char       dummy;
  sb2      ind = 0, rlen = 0, rcode = 0;
    char      *query = "SELECT table_name FROM all_tables";

    OCIEnvInit(&env, OCI_DEFAULT, 0, NULL);
    OCIHandleAlloc(env, (void *)&err, OCI_HTYPE_ERROR, 0, NULL);

    check_oci_err(err, OCILogon2(env, err, &svc, username, strlen(username), password, strlen(password), dbname, strlen(dbname), OCI_DEFAULT));

    OCIHandleAlloc(env, (void *)&stmt, OCI_HTYPE_STMT, 0, NULL);

    check_oci_err(err, OCIStmtPrepare(stmt, err, query, strlen(query), OCI_NTV_SYNTAX, OCI_DEFAULT));

  /*
   * This query fetches a single column. We don't know how big each value in the result set
   * will be until we actually fetch the value.
   *
   * So we execute the statement and specify iters=0 to tell the OCI that it should *not* fetch
   * any row as part of the OCIStmtExecute() call.
   */

  check_oci_err(err, OCIStmtExecute(svc, stmt, err, /* iters */0, 0, NULL, NULL, OCI_STMT_SCROLLABLE_READONLY));

  /*
   * Now we can fetch rows from the result set
   */
  for( ; ; )
  {
    /*
     * Since we don't know how large this next value will be, we define the output
     * buffer as a single byte (dummy)...
     */
    value = &dummy;
    check_oci_err(err, OCIDefineByPos(stmt, &def, err, 1, value, sizeof(dummy), SQLT_CHR, &ind, &rlen, &rcode, OCI_DEFAULT));

    /*
     * and, when we fetch, we expect to get warning that a value was truncated... OCIStmtFetch2() will
     * return OCI_SUCCESS_WITH_INFO (note: OCIStmtFetch2() will actually return part of the column - since
     * we defined a one-byte output buffer, OCIStmtFetch2() will write the first byte of the value into
     * the output buffer (dummy).  If you wish, you could bind to a buffer large enough to hold *most* values
     * and then re-define and re-fetch if you encounter a value too large to fit into that space.
     */
    sword result = OCIStmtFetch2(stmt, err, 1, OCI_FETCH_NEXT, 0, OCI_DEFAULT);

    /*
     * If we got an OCI_SUCCESS_WITH_INFO, we assume that OCIStmtFetch2() truncated one or more of the
     * values that we fetched.  For each column, OCIStmtFetch2() returns the *actual* length of the value
     * in the indicator variable (see the earlier call to OCIDefineByPos()).
     */
    printf("result(%d) ind(%d) rlen(%d) rcode(%d)\n", result, ind, rlen, rcode);

    if (result == OCI_SUCCESS_WITH_INFO)
    {
      /*
       * OCIStmtFetch2() returned a result that indicates that a value has been truncated (we should probably
       * check for the exact error code here, just to make sure).
       *
       * Now that we know how much space we need, we can malloc() a buffer large enough to hold the value (we
       * add one byte to hold the null terminator).
       *
       * Then we call OCIDefineByPos() to give the OCI the address of this new buffer, and we re-fetch the
       * same row out of the result set by cal OCIStmtFetch2() again with orientation=OCI_FETCH_CURRENT.
       */
      value = malloc(ind+1);
      check_oci_err(err, OCIDefineByPos(stmt, &def, err, 1, value, ind+1, SQLT_CHR, &ind, &rlen, &rcode, OCI_DEFAULT));
      check_oci_err(err, OCIStmtFetch2(stmt, err, 1, OCI_FETCH_CURRENT, 0, OCI_DEFAULT));

      printf("refetched - %*.*s\n", rlen, rlen, value);
      printf("ind(%d) rlen(%d) rcode(%d)\n", ind, rlen, rcode);
    }
    else if (result == OCI_NO_DATA)
    {
      break;
    }
  }

    check_oci_err(err, OCILogoff(svc, err));

    OCIHandleFree(err, OCI_HTYPE_ERROR);
    OCIHandleFree(env, OCI_HTYPE_ENV);

    return 0;
}

/******************************************************************************
 *
 *                          Environment Error Handling
 *
 ******************************************************************************/
void check_oci_env_err(OCIEnv *env, sword retCode)
{
    char    szBuf[512];
    sb4     errCode;


    switch(retCode)
    {
    case OCI_SUCCESS:
      break;

    case OCI_SUCCESS_WITH_INFO:
      {
        memset(szBuf, 0, 512);
        OCIErrorGet(env, 1, NULL, &errCode, szBuf, 512, OCI_HTYPE_ENV);
        printf("OCI_SUCCESS_WITH_INFO : %s\n", szBuf);
      }
      break;

    case OCI_RESERVED_FOR_INT_USE:
      break;

    case OCI_NO_DATA:
            printf("OCI_NO_DATA\n", szBuf);
      break;

    case OCI_ERROR:
      {
        memset(szBuf, 0, 512);
        OCIErrorGet(env, 1, NULL, &errCode, szBuf, 512, OCI_HTYPE_ENV);
        printf("OCI_ERROR : %s\n", szBuf);
      }
      break;

    case OCI_INVALID_HANDLE:
      break;

    case OCI_NEED_DATA:
      break;

    case OCI_STILL_EXECUTING:
      break;
    }
}

/******************************************************************************
 *
 *                              Error Handling
 *
 ******************************************************************************/
void check_oci_err(OCIError *err, sword retCode)
{
    char    szBuf[512];
    sb4     errCode;
    sword   status;
    ub4     recordno;


    switch(retCode)
    {
    case OCI_SUCCESS:
      break;

    case OCI_SUCCESS_WITH_INFO:
      {
        recordno = 1;

        memset(szBuf, 0, 512);
        status = OCIErrorGet(err, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR);
        while(status != OCI_NO_DATA)
        {
          printf("OCI_ERROR : %s\n", szBuf);

          memset(szBuf, 0, 512);
          status = OCIErrorGet(err, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR);
        }
      }
      break;

    case OCI_RESERVED_FOR_INT_USE:
      break;

    case OCI_NO_DATA:
            printf("OCI_NO_DATA\n", szBuf);
      break;

    case OCI_ERROR:
      {
        recordno = 1;

        memset(szBuf, 0, 512);
        status = OCIErrorGet(err, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR);
        while(status != OCI_NO_DATA)
        {
          printf("OCI_ERROR : %s\n", szBuf);

          memset(szBuf, 0, 512);
          status = OCIErrorGet(err, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR);
        }
      }
      break;

    case OCI_INVALID_HANDLE:
      break;

    case OCI_NEED_DATA:
      break;

    case OCI_STILL_EXECUTING:
      break;
    }
}
