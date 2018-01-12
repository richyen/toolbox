#include<stdio.h>
#include<stdlib.h>
#include"postgres.h"
#include<memory.h>
#include <dlfcn.h>

OCISvcCtx*      pOCISession;    // Oracle OCI Service Conchar Handle
OCIError*       pOCIErr;                // OCI Error Handle for error handling purposes
OCIServer*      srvhp;                  //OCI Server Handle
OCIStmt*        pOCIStmtInsert;                       // Statement handle for the prepared statement
OCIStmt*        pOCIStmtSelect;                       // Statement handle for the prepared statement
OCIEnv* pOCIEnv;                        // OCI Environment Handle (for each server connection)
int             val;            // Value returned for each row in result set

t_OCIHandleFree pOCIHandleFree;
t_OCIErrorGet pOCIErrorGet;
t_OCIServerDetach pOCIServerDetach;
t_OCIEnvCreate pOCIEnvCreate;
t_OCIHandleAlloc pOCIHandleAlloc;
t_OCILogon pOCILogon;
t_OCIStmtPrepare pOCIStmtPrepare;
t_OCIDefineByPos pOCIDefineByPos;
t_OCIStmtExecute pOCIStmtExecute;
t_OCIStmtFetch pOCIStmtFetch;
t_OCILogoff pOCILogoff;
t_OCIAttrSet pOCIAttrSet;
t_OCIAttrGet pOCIAttrGet;
t_OCIBindByPos pOCIBindByPos;
t_OCITransRollback pOCITransRollback;
t_OCIParamGet pOCIParamGet;
t_OCITransCommit pOCITransCommit;
t_OCIBreak pOCIBreak;

typedef struct
{
  int len;
  char data[65535];
}lvc;

int connect( const char*     dsn,            // DB Server Name (not used)
    const char*     dbname,         // DB Name
    const char*     username,       // User Name
    const char*     passwd)         // User Password
{
  void* clientload = NULL;
  int ret = 0;
  //static char* db_environ = getenv("DB_TYPE") ;
  *(&clientload) = dlopen("libedboci.so", RTLD_NOW|RTLD_DEEPBIND);

  if(NULL != clientload)
  {
    *(void **)(&pOCIHandleFree) = dlsym (clientload,"OCIHandleFree");
    *(void **)(&pOCIErrorGet) = dlsym (clientload,"OCIErrorGet");
    *(void **)(&pOCIServerDetach) = dlsym (clientload,"OCIServerDetach");
    *((void **)(&pOCIEnvCreate)) = dlsym (clientload,"OCIEnvCreate");
    *(void **)(&pOCIHandleAlloc) = dlsym (clientload,"OCIHandleAlloc");
    *(void **)(&pOCILogon) = dlsym (clientload,"OCILogon");
    *(void **)(&pOCIStmtPrepare) = dlsym (clientload,"OCIStmtPrepare");
    *(void **)(&pOCIDefineByPos) = dlsym (clientload,"OCIDefineByPos");
    *(void **)(&pOCIStmtExecute) = dlsym (clientload,"OCIStmtExecute");
    *(void **)(&pOCIStmtFetch) = dlsym (clientload,"OCIStmtFetch");
    *(void **)(&pOCILogoff) = dlsym (clientload,"OCILogoff");
    *(void **)(&pOCIAttrSet) = dlsym (clientload,"OCIAttrSet");
    *(void **)(&pOCIAttrGet) = dlsym (clientload,"OCIAttrGet");
    *(void **)(&pOCIBindByPos) = dlsym (clientload,"OCIBindByPos");
    *(void **)(&pOCITransRollback) = dlsym (clientload,"OCITransRollback");
    *(void **)(&pOCIParamGet)= dlsym (clientload,"OCIParamGet");
    *(void **)(&pOCITransCommit)= dlsym (clientload,"OCITransCommit");
    *(void **)(&pOCIBreak)= dlsym (clientload,"OCIBreak");
  }

  ret = pOCIEnvCreate(    &pOCIEnv,                                                       /* OCIEnv **envhpp,*/
      OCI_DEFAULT,                                            /* ub4 mode,*/
      (const dvoid*)0,                                                        /* CONST dvoid *ctxp,*/
      (const dvoid*(*)(void*,size_t))0,                       /* CONST dvoid *(*malocfp)*/
      (const dvoid*(*)(void*,void*,size_t))0, /* CONST dvoid *(*ralocfp)*/
      (const void(*)(void*,void*))0,                  /* CONST void (*mfreefp)*/
      0,                                                                      /* size_t xtramemsz,*/
      (dvoid**)0);
  if(ret != OCI_SUCCESS){
    return -1;
  }
  ret = pOCIHandleAlloc(  (dvoid*)pOCIEnv,
      (dvoid**)&pOCIErr,
      OCI_HTYPE_ERROR, (size_t)0, 0);
  if(ret != OCI_SUCCESS){
    return -1;
  }
  ret = pOCILogon(        pOCIEnv,
      pOCIErr,
      &pOCISession,
      (const OraText *)username,
      (ub4)strlen(username),
      (const OraText *)passwd,
      (ub4)strlen(passwd),
      (const OraText *)dbname,
      (ub4)strlen(dbname));
  if(ret != OCI_SUCCESS){
    return -1;
  }

#if 0
  ret = pOCIHandleAlloc((dvoid *)pOCIEnv, (dvoid **) &(srvhp),
      OCI_HTYPE_SERVER, (size_t) 0, (dvoid**)0);
#else
  ret = pOCIAttrGet(pOCISession,
      (ub4)OCI_HTYPE_SVCCTX,
      &srvhp,
      0,
      OCI_ATTR_SERVER,
      pOCIErr);
#endif

  if(ret != OCI_SUCCESS){
    return -1;
  }

  ub4 holdType = EDB_WITH_HOLD;

  ret = pOCIAttrSet(      (dvoid*)srvhp,
      OCI_HTYPE_SERVER,
      &holdType,
      (ub4)0,
      EDB_ATTR_HOLDABLE,
      pOCIErr);
  if(ret != OCI_SUCCESS){
    return -1;
  }
}

int createStatement()
{
  //Creating a statement
  //
  int ret = pOCIAttrGet(      (dvoid*)pOCISession,
      (ub4)OCI_HTYPE_SVCCTX,
      (dvoid*)&pOCIEnv,
      (ub4*)0,
      (ub4)OCI_ATTR_ENV,
      pOCIErr);


  // Create OCI Error Handle for Oracle Statement
  // ---------------------------------------------
  ret = pOCIHandleAlloc(  (dvoid*)pOCIEnv,
      (dvoid**)&pOCIErr,
      OCI_HTYPE_ERROR, (size_t)0, 0);

  if(ret != OCI_SUCCESS){
    return -1;
  }

  // Create OCI Statement Handle for Oracle Statement
  // --------------------------------------------------

  ret = pOCIHandleAlloc(  (dvoid*)pOCIEnv,
      (dvoid**)&pOCIStmtInsert,
      OCI_HTYPE_STMT, (size_t)0, 0);
  if(ret != OCI_SUCCESS){
    return -1;
  }

  ret = pOCIHandleAlloc(  (dvoid*)pOCIEnv,
      (dvoid**)&pOCIStmtSelect,
      OCI_HTYPE_STMT, (size_t)0, 0);
  if(ret != OCI_SUCCESS){
    return -1;
  }

  return ret;
}

int bindValues(OCIStmt* pOCIStmt, int cndx, int userSize, void* userValue, int DBType)
{
  short*                  ind;
  OCIBind*                pOCIBind;
  pOCIBind = 0;

  ind = (short*)calloc(1,sizeof(short));

  if(userSize == 0)
    *ind = -1;

  int ret = pOCIBindByPos(    pOCIStmt,
      &pOCIBind,
      pOCIErr,
      (ub4)cndx+1,                    // Index of bindvar
      (dvoid*)userValue,              // Value of bindvar
      (sb4)userSize,                  // Size of bindvar
      (ub2)DBType,                    // Database type for bindvar
      (dvoid*)ind,                    // pointer to indicator variable
      (ub2*)0,
      (ub2*)0,
      (ub4)0,
      (ub4*)0,
      OCI_DEFAULT);

  return 0;
}

int prepareQuery(OCIStmt* pOCIStmt, char *pQuery)
{

  int ret = 0;

  ret = pOCIStmtPrepare(  pOCIStmt,
      pOCIErr,
      (const OraText *)pQuery,
      (ub4)strlen(pQuery),
      OCI_NTV_SYNTAX,
      OCI_DEFAULT);

  return ret;
}

sword defineOutputBuffer(OCIStmt* pOCIStmt, int cndx, int userSize, void* userValue, int DBType)
{
  OCIDefine *define;

  return pOCIDefineByPos(pOCIStmt, &define, pOCIErr, (ub4) cndx+1, &userValue, userSize, (ub2)DBType, 0, 0, 0, OCI_DEFAULT);

}

int executeInsert(OCIStmt* pOCIStmt)
{
  // Execute Statement
  int ret = pOCIStmtExecute(  pOCISession,            // OCI Service Conchar Handle
      pOCIStmt,                       // OCI Statement Handle
      pOCIErr,                        // OCI Error Handle
      1,                        // # of rows
      0,                                      // Array offset (if any)
      (OCISnapshot*)0,
      (OCISnapshot*)0,
      OCI_DEFAULT);                          // OCI_DEFAULT (implicit describe)
  printf("Return after inserting [%d]\n",ret);
  return ret;
}
int executeSelect(OCIStmt* pOCIStmt)
{
  int ret = pOCIStmtExecute(  pOCISession,
      pOCIStmt,
      pOCIErr,
      (ub4)0,                        // Num Requested
      (ub4)0,                                         // Row Offset
      (OCISnapshot*)NULL,
      (OCISnapshot*)NULL,
      OCI_DEFAULT);

  printf("Return after creating the cursor [%d]\n",ret);

  return ret;
}

int fetchData(OCIStmt* pOCIStmt)
{
  int ret = pOCIStmtFetch( pOCIStmt,
      pOCIErr,
      (ub4)1,                       // Num Requested
      (ub2)OCI_DEFAULT,		// Orientation
      (ub4)0,                       // Row Offset
      (ub4)OCI_DEFAULT);

  printf("Return after fetching  [%d]\n",ret);

  return ret;
}

int disconnect()
{
  int ret = 0;

  if(pOCISession){
    pOCILogoff(pOCISession, pOCIErr);
  }

  if(pOCIErr){
    ret = pOCIHandleFree((dvoid*)pOCIErr, OCI_HTYPE_ERROR);
  }

  if(pOCISession){
    ret = pOCIHandleFree((dvoid*)pOCISession, OCI_HTYPE_SVCCTX);
  }

  return ret;
}

int commit()
{
  int ret = pOCITransCommit(pOCISession, pOCIErr, OCI_DEFAULT);
  printf("Return after committing  [%d]\n",ret);
  return ret;
}
int printError()
{
  char sDBMsg[1200];
  sb4 dberrcode;

  memset(sDBMsg,0,1200);

  if(pOCIErr)
  {
    pOCIErrorGet((dvoid*)pOCIErr, (ub4)1, (text*)0, (sb4*)&dberrcode, (text*)sDBMsg, (ub4)sizeof(sDBMsg), OCI_HTYPE_ERROR);
  }

  printf("Error is [%s]\n",sDBMsg);

  return 1;
}

int main(int argc, char* argv[])
{

  char *datarec = (char*)malloc(65535);
  int ret = connect(argv[1],argv[2],argv[3],argv[4]);

  if(ret  < 0)
  {
    printError();

  }

  createStatement();

  FILE* data=NULL;

  lvc *value = (lvc*)malloc(sizeof(lvc));
  data=fopen("data","r");
  fscanf(data,"%s", value->data);
  value->len = (int)strlen( value->data);
  printf("\n%s\n%ld\n", value->data,value->len);

  prepareQuery(pOCIStmtInsert,"insert into data_table values(1,:1)");
  bindValues(pOCIStmtInsert,0,strlen(value->data),value,SQLT_LVC);
  ret = executeInsert(pOCIStmtInsert);
  if(ret  < 0)
  {
    printError();

  }

  ret =commit();

  free(value);
  /*	if(ret  < 0)
      {
      printError();

      }
      prepareQuery(pOCIStmtSelect,"select * from data_table");
      defineOutputBuffer(pOCIStmtSelect,1,strlen(datarec),datarec,SQLT_LVC);
      ret = executeSelect(pOCIStmtSelect);
      if(ret  < 0)
      {
      printError();

      }
      else
      {
      ret = fetchData(pOCIStmtSelect);
      }
      if(ret  < 0)
      {
      printError();

      }
      ret =commit();
      if(ret  < 0)
      {
      printError();

      }
   */
  disconnect();
  free(datarec);
  return 1;
}
