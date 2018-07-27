#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef _WIN32
#include <sys/time.h>
#endif

#include "oci.h"

#define DATABASE	"//localhost:5444/edb"
#define USER		"edb"
#define PASSWD		"edb"

OraText *username = (OraText *) USER;
OraText *password = (OraText *) PASSWD;
OraText *dbname = (OraText *) DATABASE;

#ifdef _DEBUG
#define checkerr(x, y) check_ocifunc(x, y, __FILE__, __LINE__)
#else
#define checkerr(x, y) check_ocifunc(x, y, 0, 0)
#endif /* _DEBUG */

#define DATE_FMT "DAY, MONTH DD, YYYY"
#define DATE_LANG "American"

void check_ocifunc(dvoid* errhp, sword res,
    const char* filename, int line);

char res_str[2000];
char str[600];

int main(int argc, char** argv)
{
  ub4         init_mode = OCI_OBJECT;
  ub4         credt = OCI_CRED_RDBMS;
  OCIEnv*     envhp;             // environment handle
  OCIError*   errhp;             // error handle
  OCISvcCtx*  svchp;             // service context handle
  OCIServer*  srvhp;             // server handle
  OCISession* authp;             // user session (authentication) handle
  /* text*       username = (text*)"enterprisedb";
     text*       password = (text*)"edb";*/
  text*       server = (text*)"";
  text*       sql_statement = (text*)" select empno, ename from emp;";
  OCIStmt*    stmthp = 0;
  OCIDefine*  define = 0;

  int         empno = 0;
  ub4         name_buffer_len = 64;
  char*       name_buffer = 0;


  sb2         null_ind1 = 0;   // null indicator for position 1
  sb2         null_ind2 = 0;   // null indicator for position 2
  sb2 	      null_ind3 = 0;   // null indicator for position 3
  ub4         rows = 1;
  ub4         fetched = 1;
  sb4         status = OCI_SUCCESS;
  ub4		  prefetch_rows=14;

  // initialize OCI and set up handles
  if(OCIInitialize(init_mode, (dvoid*)0,
        (dvoid* (*)(dvoid*, size_t))0,
        (dvoid* (*)(dvoid*, dvoid*, size_t))0,
        (void (*)(dvoid*, dvoid*))0) != OCI_SUCCESS)
  {
    printf("ERROR: failed to initialize OCI\n");
  }
  checkerr(envhp,
      OCIEnvInit(&envhp, OCI_DEFAULT,
        (size_t)0, (dvoid**)0));
  checkerr(envhp,
      OCIHandleAlloc(envhp, (dvoid**)&errhp,
        OCI_HTYPE_ERROR, (size_t)0, (dvoid**)0));

  checkerr(errhp,
      OCIHandleAlloc(envhp, (dvoid**)&svchp,
        OCI_HTYPE_SVCCTX, (size_t)0, (dvoid**)0));
  checkerr(errhp,
      OCIHandleAlloc(envhp, (dvoid**)&authp,
        OCI_HTYPE_SESSION, (size_t)0, (dvoid**)0));
  // attach server
  checkerr(errhp,
      OCIHandleAlloc(envhp, (dvoid**)&srvhp,
        OCI_HTYPE_SERVER, (size_t)0, (dvoid**)0));

  checkerr(errhp,
      OCILogon(envhp, errhp, &svchp,
        username, (ub4)strlen((char*)username),
        password, (ub4)strlen((char*)password),
        dbname, (ub4)strlen((char*)dbname)));


  checkerr(errhp,
      OCIHandleAlloc(envhp,
        (dvoid **)&stmthp, OCI_HTYPE_STMT, 0, 0));
  /*
   * SET OCI_ATTR_PREFETCH_ROWS attribute
   */

  checkerr(errhp,OCIAttrSet(stmthp, OCI_HTYPE_STMT, (void*)&prefetch_rows, sizeof(int),
        OCI_ATTR_PREFETCH_ROWS, errhp));


  checkerr(errhp,
      OCIStmtPrepare(stmthp, errhp,
        sql_statement, strlen((const char*)sql_statement),
        OCI_NTV_SYNTAX, 0));
  name_buffer = (char*)malloc(sizeof(char) * name_buffer_len);


  checkerr(errhp,
      OCIDefineByPos(stmthp, &define, errhp,
        (ub4)1, &empno, sizeof(int),
        (ub2)SQLT_INT,
        &null_ind1,
        0, 0, OCI_DEFAULT));
  checkerr(errhp,
      OCIDefineByPos(stmthp, &define, errhp,
        (ub4)2, name_buffer, name_buffer_len + 1,
        (ub2)SQLT_STR,
        &null_ind2,
        0, 0, OCI_DEFAULT));

  status = OCIStmtExecute(svchp, stmthp, errhp,
      rows, (ub4)0,
      (CONST OCISnapshot*)NULL,
      (OCISnapshot*)NULL, OCI_DEFAULT);

  if(status == OCI_NO_DATA)
  {
    /* indicates didn't fetch anything (as we're not array fetching) */
    fetched = 0;

  }
  else
  {
    checkerr(errhp, status);
  }


  if(fetched)
  {
    //

    while(1)
    {
      status = OCIStmtFetch(stmthp, errhp,
          rows, OCI_FETCH_NEXT, OCI_DEFAULT);
      if(status == OCI_NO_DATA)
      {
        //	printf("fetched___________dddd___________________________________ [%d]\n",fetched);
        /* indicates couldn't fetch anything */
        break;
      }
      else
      {
        checkerr(errhp, status);
      }
      printf("empno [%d], empname [%s]\n",empno,name_buffer);

    }
  }

  checkerr(errhp, OCIHandleFree(stmthp, OCI_HTYPE_STMT));
  stmthp = 0;

  checkerr(errhp, OCISessionEnd(svchp, errhp, authp, OCI_DEFAULT));

  if(name_buffer)
    free(name_buffer);

  // free up handles
  checkerr(errhp, OCIHandleFree(authp, OCI_HTYPE_SESSION));
  authp = 0;
  checkerr(errhp, OCIHandleFree(srvhp, OCI_HTYPE_SERVER));
  srvhp = 0;
  checkerr(errhp, OCIHandleFree(svchp, OCI_HTYPE_SVCCTX));
  svchp = 0;
  checkerr(errhp, OCIHandleFree(errhp, OCI_HTYPE_ERROR));
  errhp = 0;
  OCIHandleFree(envhp, OCI_HTYPE_ENV);
  envhp = 0;

}

/*
 * Checks return status of OCI function call. Exits the app with an
 * error message if the value is not OCI_SUCCESS.
 */
void check_ocifunc(dvoid* errhp,         /* [IN] error handle */
    sword status,         /* [IN] OCI status code */
    const char* filename, /* [IN] source filename */
    int line)             /* [IN] source line number */
{
  text errbuf[512];
  ub4  errcode;

  /* if everything is OK, return now */
  if(status == OCI_SUCCESS)
  {
    return;
  }

  /* if we've got debug information, print out the location */
  if(filename)
  {
    printf("%s(%d): ", filename, line);
    sprintf(str,"%s(%d): ", filename, line);
    strcat(res_str,str);
  }

  /* print out error information */
  switch(status)
  {
    case OCI_SUCCESS_WITH_INFO:
      printf("OCI_SUCCESS_WITH_INFO:\n");
      sprintf(str,"OCI_SUCCESS_WITH_INFO:\n");
      strcat(res_str,str);
      OCIErrorGet(errhp, (ub4)1, (text*)0, &errcode,
          errbuf, (ub4)sizeof(errbuf), OCI_HTYPE_ERROR);
      printf("%s", errbuf);
      sprintf(str,"%s", errbuf);
      strcat(res_str,str);
      break;
    case OCI_NEED_DATA:
      printf("Error - OCI_NEED_DATA\n");
      sprintf(str,"Error - OCI_NEED_DATA\n");
      strcat(res_str,str);
      break;
    case OCI_NO_DATA:
      printf("Error - OCI_NO_DATA\n");
      sprintf(str,"Error - OCI_NO_DATA\n");
      strcat(res_str,str);
      break;
    case OCI_ERROR:
      printf("Error - OCI_ERROR:\n");
      sprintf(str,"Error - OCI_ERROR:\n");
      strcat(res_str,str);
      OCIErrorGet(errhp, (ub4)1, (text*)0, &errcode,
          errbuf, (ub4)sizeof(errbuf), OCI_HTYPE_ERROR);
      printf("%s", errbuf);
      sprintf(str,"%s", errbuf);
      strcat(res_str,str);
      break;
    case OCI_INVALID_HANDLE:
      printf("Error - OCI_INVALID_HANDLE\n");
      sprintf(str,"Error - OCI_INVALID_HANDLE\n");
      strcat(res_str,str);
      break;
    case OCI_STILL_EXECUTING:
      printf("Error - OCI_STILL_EXECUTING\n");
      sprintf(str,"Error - OCI_STILL_EXECUTING\n");
      strcat(res_str,str);
      break;
    case OCI_CONTINUE:
      printf("Error - OCI_CONTINUE\n");
      sprintf(str,"Error - OCI_CONTINUE\n");
      strcat(res_str,str);
      break;
    default:
      break;
  }
}
