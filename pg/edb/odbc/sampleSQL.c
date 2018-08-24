#include <sqlext.h>
#include <sqltypes.h>
#include <sql.h>
#include <stdlib.h>

#include <stdio.h>
#include <string.h>
#define MAX_DATA 100
#define MYSQLSUCCESS(rc) ((rc==SQL_SUCCESS)||(rc==SQL_SUCCESS_WITH_INFO))
#define PARAM_ARRAY_SIZE 10

unsigned char szData[MAX_DATA];

#define COL1_LEN  255

SQLLEN  cPersonId;
SQLCHAR strcol1[COL1_LEN];
SQLCHAR strcol2[COL1_LEN];
SQLCHAR strcol3[COL1_LEN];
SQLLEN  lencol1=0, lencol2=0, lencol3=0;

/*
   Simple demo of SELECT and INSERT with ODBC.
   Compile with:
   gcc -o Test sampleSQL.c -m32 -I /usr/local/unixODBC/include/ -L /usr/local/unixODBC/lib/ -lodbc -lodbcinst
   Run with:
   ./Test
   Note that this uses the default EDBAS schema (demo employee database)
 */

BOOL Connect(char* strDB,char* strUser, char* strPassword, HENV** hEnv, HDBC** hDBC)
{
  RETCODE hRet = 0;
  hRet = SQLAllocEnv( (*hEnv) );

  if( SQL_ERROR == hRet )
  {
    printf("Unable to Initialize the Environment..");
    return 0;

  }
  else
  {
    printf("%s\r\n","Environment Initialized..");
    SQLAllocConnect( *(*hEnv),(*hDBC) );
    //printf("datebase check %s",strDB);
    if ( *hDBC != NULL )
    {
      printf("Database Name = %s\r\n",strDB);

    }
    hRet =SQLConnect( *(*hDBC),(SQLCHAR*)strDB,SQL_NTS,(SQLCHAR*)strUser,strlen(strUser),(SQLCHAR*)strPassword,strlen(strPassword));
    if(!MYSQLSUCCESS(hRet))
    {
      SQLFreeEnv(*(*hEnv ));
      SQLFreeConnect(*( *hDBC ) );
      printf("%s\r\n","Unable to connect..");
      return 0;
    }
    else
    {
      printf("%s\r\n","Connected to the Database..");
      return 1;
    }

  }

  return 0;
}

void Disconnect(HENV** hEnv, HDBC** hDBC, HSTMT** hStmt)
{
  SQLFreeStmt( *(*hStmt),SQL_DROP );
  SQLDisconnect( *(*hDBC) );
  SQLFreeConnect( *(*hDBC) );
  SQLFreeEnv( *(*hEnv) );

}

BOOL ExecuteSimple_Select(HSTMT** hStmt,unsigned char * cmdstr)
{
  SDWORD cbData;
  SQLSMALLINT iTotCols = 0;
  int j;
  RETCODE rc=SQLExecDirect(*(*hStmt),cmdstr,SQL_NTS);
  if (!MYSQLSUCCESS(rc))  //Error
  {
    printf("Unable to execute...\r\n");
    //error_out(hStmt);
    // Deallocate handles and disconnect.
    SQLFreeStmt(hStmt,SQL_DROP);
    return 0;
  }
  else
  {
    rc=SQLFetch(*(*hStmt));
    if(SQL_NO_DATA == rc)
    {
      printf("No Data...\r\n");
      return 0;
    }
    SQLNumResultCols(*(*hStmt),&iTotCols);
    printf("No of Columns = %d\r\n",iTotCols);

    for (;rc == SQL_SUCCESS; rc=SQLFetch( *(*hStmt) ) )
    {
      SQLGetData( *(*hStmt),1,SQL_C_CHAR,szData,sizeof(szData),&cbData);
      printf("empno = %s\t",szData);
      printf("\r\n");
      SQLGetData( *(*hStmt),2,SQL_C_CHAR,szData,sizeof(szData),&cbData);
      printf("ename = %s\t",szData);
      printf("\r\n");
      SQLGetData( *(*hStmt),3,SQL_C_CHAR,szData,sizeof(szData),&cbData);
      printf("job = %s\t",szData);
      printf("\r\n");
      SQLGetData( *(*hStmt),4,SQL_C_CHAR,szData,sizeof(szData),&cbData);
      printf("mgr = %s\t",szData);
      printf("\r\n");
      SQLGetData( *(*hStmt),5,SQL_C_CHAR,szData,sizeof(szData),&cbData);
      printf("sal = %s\t",szData);
      printf("\r\n");
    }
    SQLFreeStmt(hStmt,SQL_DROP);
    printf("Done\n");
    return 1;
  }
}

BOOL ExecuteInsertStatement(HSTMT** hStmt)
{
  SQLRETURN retcode;

  char sqlStmtInsert[] = "INSERT INTO dept (deptno, dname, loc) VALUES (?,?,?)";
  char sqlstr[256];
  SQLSMALLINT     NumParams;

  // Generate statement
  sprintf (sqlstr, sqlStmtInsert);
  printf ("SQL is : %s\n",sqlstr);


  // Bind Parameters to all fields
  retcode = SQLBindParameter(*(*hStmt), 1, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, COL1_LEN, 0, strcol1, COL1_LEN, &lencol1);
  if (retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO) {
    printf ("Status : ok\n");
  } else if (retcode == SQL_ERROR) {
    printf ("Status : Bind Error %i\n", retcode);
  } else if (retcode == SQL_INVALID_HANDLE) {
    printf ("Status : Bind Handle Error %i\n", retcode);
  } else {
    printf ("Status : Bind Generic Error %i\n", retcode);
  }
  retcode = SQLBindParameter(*(*hStmt), 2, SQL_PARAM_INPUT,
      SQL_C_CHAR, SQL_CHAR, COL1_LEN, 0,
      strcol2, COL1_LEN, &lencol2);
  retcode = SQLBindParameter(*(*hStmt), 3, SQL_PARAM_INPUT,
      SQL_C_CHAR, SQL_CHAR, COL1_LEN, 0,
      strcol3, COL1_LEN, &lencol3);


  retcode = SQLPrepare(*(*hStmt), (SQLCHAR*) sqlstr, SQL_NTS);
  if (retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO) {
    printf ("Status : ok\n");
  } else {
    printf ("Status : Prepare Error %i\n", retcode);
  }

  NumParams = 3;
  SQLNumParams(*(*hStmt), &NumParams);
  printf ("Num params : %i\n", NumParams);


  memset (strcol1, ' ', COL1_LEN);
  memset (strcol2, ' ', COL1_LEN);
  memset (strcol3, ' ', COL1_LEN);

  strcpy((char*)strcol1,"2");
  strcpy((char*)strcol2,"I002");
  strcpy((char*)strcol3,"100");

  lencol1 = strlen(strcol1);
  lencol2 = strlen(strcol2);
  lencol3 = strlen(strcol3);

  retcode = SQLExecute(*(*hStmt));

  if (retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO) {
    printf ("Status : ok\n");
  } else {
    printf ("Status : Exec Error %i\n", retcode);
  }

  retcode = SQLFreeStmt(*(*hStmt),SQL_DROP);
  if (retcode == SQL_SUCCESS || retcode == SQL_SUCCESS_WITH_INFO) {
    printf ("Status : ok\n");
  } else {
    printf ("Status : End Error %i\n", retcode);
  }
  return 0;
}

int main(int argc, char* argv[])
{
  RETCODE rCode;
  HENV *hEnv = (HENV*)malloc(sizeof(HENV));
  HDBC *hDBC = (HDBC*)malloc(sizeof(HDBC));
  HSTMT *hStmt = (HSTMT*)malloc(sizeof(HSTMT));
  Connect("edb","enterprisedb","abc123",&hEnv,&hDBC);
  rCode = SQLAllocStmt(*hDBC,hStmt);
  if (rCode == SQL_SUCCESS || rCode == SQL_SUCCESS_WITH_INFO) {
    printf ("Status : AS ok\n");
  } else {
    printf ("Status : Alloc Stmt Error %i\n", rCode);
  }
  rCode = SQLAllocHandle(SQL_HANDLE_STMT,*hDBC,hStmt);
  if (rCode == SQL_SUCCESS || rCode == SQL_SUCCESS_WITH_INFO) {
    printf ("Status : AH ok\n");
  } else {
    printf ("Status : Alloc Handle Error %i\n", rCode);
  }

  ExecuteSimple_Select(&hStmt,(UCHAR*) "SELECT empno, ename, job, mgr, sal FROM emp LIMIT 1");
  rCode = SQLAllocStmt(*hDBC,hStmt);
  rCode = SQLAllocHandle(SQL_HANDLE_STMT,*hDBC,hStmt);
  ExecuteInsertStatement(&hStmt);
  rCode = SQLAllocStmt(*hDBC,hStmt);
  rCode = SQLAllocHandle(SQL_HANDLE_STMT,*hDBC,hStmt);
  ExecuteSimple_Select(&hStmt,(UCHAR*) "SELECT empno, ename, job, mgr, sal FROM emp LIMIT 1");

  Disconnect(&hEnv,&hDBC,&hStmt);

  free(hEnv);
  free(hDBC);
  free(hStmt);

  return 0;
}
