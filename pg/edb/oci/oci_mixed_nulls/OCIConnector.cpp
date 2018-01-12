#define __STDC_WANT_LIB_EXT1__ 1
#include <string.h>
#include <cstring>
#include <stdlib.h>
#include <stdio.h>
#include <algorithm>
#include <oci.h>

#define HANDLE_ERROR(x,y) HANDLE_ERROR(x,y)
#define TESTSTTYLE_1

// Case 628162

void
HANDLE_ERROR (dvoid * errhp, sword status)
{
  text errbuf[1024];
  sb4 errcode;

  if (status == OCI_SUCCESS)
    {
      return;
    }
  switch (status)
    {
    case OCI_SUCCESS_WITH_INFO:
      printf ("OCI_SUCCESS_WITH_INFO:\n");
      OCIErrorGet (errhp, (ub4) 1, (text *) 0, &errcode,
		   errbuf, (ub4) sizeof (errbuf), OCI_HTYPE_ERROR);
      printf ("%s", errbuf);
      break;
    case OCI_NEED_DATA:
      printf ("Error - OCI_NEED_DATA\n");
      break;
    case OCI_NO_DATA:
      printf ("Error - OCI_NO_DATA\n");
      break;
    case OCI_ERROR:
      printf ("Error - OCI_ERROR:\n");
      OCIErrorGet (errhp, (ub4) 1, (text *) 0, &errcode,
		   errbuf, (ub4) sizeof (errbuf), OCI_HTYPE_ERROR);
      printf ("%s\n", errbuf);
      break;
    case OCI_INVALID_HANDLE:
      printf ("Error - OCI_INVALID_HANDLE\n");
      break;
    case OCI_STILL_EXECUTING:
      printf ("Error - OCI_STILL_EXECUTING\n");
      break;
    case OCI_CONTINUE:
      printf ("Error - OCI_CONTINUE\n");
      break;
    default:
      break;
    }
}

void initHandles(OCISvcCtx ** svchp, OCIServer ** srvhp, OCISession ** authp, OCIError ** errhp, OCIEnv ** envhp)
{

	/*
	* Now Starts the Section where we have to initialize & Allocate
	* basic handles. This is a compulsory setup or initialization which
	* is required before we can proceed to logon and work with the
	* database. This initialization and preparation will include the
	* following steps
	*
	* 1. Initialize the OCI (OCIInitialize()) 2. Initialize the
	* Environment (OCIEnvInit()) 3. Initialize & Allocate Error Handle
	* 4. Initialize & Allocate Service Context Handle 5. Initialize &
	* Allocate Session Handle 6. Initialize & Allocate Server Handle
	*
	* As per the new versions of OCI , instead of using OCIInitialize()
	* and OCIEnvInit(), we can do this with one API Call called
	* OCIEnvCreate().
	*/

	// can't use OCIEnvNlsCreate() in EDB oci
	//HANDLE_ERROR(envhp, OCIEnvNlsCreate(envhp,
	//	OCI_THREADED | OCI_OBJECT,
	//	NULL, NULL, NULL, NULL, 0, (void**)NULL,
	//	(ub2)OCI_UTF16ID,		//Metadata and SQL CHAR character set
	//	(ub2)OCI_UTF16ID));		//SQL NCHAR character set

printf("A1\n");
/*
	HANDLE_ERROR(*envhp, OCIEnvCreate(&(*envhp),
		OCI_DEFAULT,
		NULL, NULL, NULL, NULL,
		(size_t)0,
		(void**)NULL));
*/

	/*
	* Initialize OCI
	*/
	if (OCIInitialize(OCI_DEFAULT, (dvoid *)0,
		(dvoid * (*)(dvoid *, size_t)) 0,
		(dvoid * (*)(dvoid *, dvoid *, size_t)) 0,
		(void(*)(dvoid *, dvoid *)) 0) != OCI_SUCCESS)
	{
		printf("ERROR: failed to initialize OCI\n");
		exit(1);
	}

	/*
	* Initialize Environment.
	*/
	HANDLE_ERROR(*envhp,
		OCIEnvInit(&(*envhp), OCI_DEFAULT, (size_t)0,
		(dvoid **)0));

	/*
	* Initialize & Allocate Error Handle
	*/
printf("A2\n");
	HANDLE_ERROR(*envhp,
		OCIHandleAlloc(*envhp, (dvoid **) & (*errhp),
			OCI_HTYPE_ERROR, (size_t)0, (dvoid **)0));

	/*
	* Initialize & Allocate Service Context Handle
	*/
printf("A3\n");
	HANDLE_ERROR(*errhp,
		OCIHandleAlloc(*envhp, (dvoid **) & (*svchp),
			OCI_HTYPE_SVCCTX, (size_t)0, (dvoid **)0));

	/*
	* Initialize & Allocate Session Handle
	*/
printf("A4\n");
	HANDLE_ERROR(*errhp,
		OCIHandleAlloc(*envhp, (dvoid **) & (*authp),
			OCI_HTYPE_SESSION, (size_t)0, (dvoid **)0));

	/*
	* Initialize & Allocate Server Handle
	*/
printf("A5\n");
	HANDLE_ERROR(*errhp,
		OCIHandleAlloc(*envhp, (dvoid **) & (*srvhp),
			OCI_HTYPE_SERVER, (size_t)0, (dvoid **)0));

}

void
logon (OCISvcCtx ** svchp, OCIServer ** srvhp, OCISession ** authp,
       OCIError ** errhp, OCIEnv ** envhp, text * username, text * passwd,
       text * server)
{

  /*
   * Now Starts our Logon to the Database Server which includes two
   * steps
   *
   * 1. Attaching to the Server 2. Starting or Begining of the Session
   *
   * This is the complex logon. The easy ways to logon is to avoid
   * server attach and session begin and simply use OCILogon() or
   * OCILogon2() and then logoff using OCILogoff()
   */

  /*
   * Attach to the server
   */

printf("B1\n");
  HANDLE_ERROR (*errhp,
		OCIServerAttach (*srvhp, *errhp, server,
				 (ub4) strlen ((char *) server),
				 OCI_DEFAULT));

  /*
   * The following code will start a session but before we start a
   * session we have to 1. Set the Server Handle which is now attached
   * into Service Context Handle 2. Set the Username and password into
   * Session Handle
   */

  /*
   * Set the Server Handle into Service Context Handle
   */

printf("B2\n");
  HANDLE_ERROR (*errhp,
		OCIAttrSet (*svchp, OCI_HTYPE_SVCCTX,
			    (dvoid *) (*srvhp), (ub4) 0, OCI_ATTR_SERVER,
			    *errhp));

  /*
   * Set the username and password into session handle
   */

printf("B3\n");
  HANDLE_ERROR (*errhp,
		OCIAttrSet (*authp, OCI_HTYPE_SESSION,
			    (dvoid *) username,
			    (ub4) strlen ((char *) username),
			    OCI_ATTR_USERNAME, *errhp));
printf("B4\n");
  HANDLE_ERROR (*errhp,
		OCIAttrSet (*authp, OCI_HTYPE_SESSION, (dvoid *) passwd,
			    (ub4) strlen ((char *) passwd), OCI_ATTR_PASSWORD,
			    *errhp));

  /*
   * Now FINALLY Begin our session
   */

printf("B5\n");
  HANDLE_ERROR ((*errhp),
		OCISessionBegin (*svchp, *errhp,
				 *authp, OCI_CRED_RDBMS, OCI_DEFAULT));

  printf ("********************************************\n");
  printf ("Milestone  : Logged on as --> '%s'\n", username);
  printf ("********************************************\n");

  /*
   * After we Begin our session we will have to set the Session
   */

  /*
   * (authentication) handle into Service Context Handle
   */

  HANDLE_ERROR (*errhp,
		OCIAttrSet (*svchp, OCI_HTYPE_SVCCTX,
			    (dvoid *) (*authp), (ub4) 0,
			    OCI_ATTR_SESSION, *errhp));
}

void create_table(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *stmhp;
	//temporary
	text *create_statement = (text *)"CREATE TABLE tmpTest \n (ENAME VARCHAR2(20)\n, MGR integer\n, NVAL Number)";
	ub4 status = OCI_SUCCESS;

	/*
	* Initialize & Allocate Statement Handle
	*/
	HANDLE_ERROR(errhp, OCIHandleAlloc(envhp, (dvoid **)& stmhp, OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));


	/*
	* Prepare the Create statement
	*/
	HANDLE_ERROR(errhp, OCIStmtPrepare(stmhp, errhp, create_statement, (ub4)strlen((const char *)create_statement), OCI_NTV_SYNTAX, OCI_DEFAULT));

	/*
	* Execute the Create Statement
	*/
	if ((status = OCIStmtExecute(svchp, stmhp, errhp, (ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN CREATING TABLE(S)\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Table(s) Successfully created\n");
		printf("********************************************\n");
	}

	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));
}

void PrintDataTest(OCISvcCtx * svchp, OCIError * errhp, OCIStmt *stmhp)
{
	OCIDefine *define;
	char chename[21] = { 0 };
	int nhgr = 0;
	double dtest = 0.0;
	text* insstmt = (text *)"select ename,mgr,nval from tmpTest";

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp, insstmt, (ub4)strlen((char *)insstmt), (ub4)OCI_NTV_SYNTAX, (ub4)OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp, (ub4)1, chename, 21, (ub2)SQLT_STR, 0, 0, 0, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp, (ub4)2, &nhgr, sizeof(int), (ub2)SQLT_INT, 0, 0, 0, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp, (ub4)3, &dtest, sizeof(double), (ub2)SQLT_BDOUBLE, 0, 0, 0, OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIStmtExecute(svchp, stmhp, errhp, 1, (ub4)0, NULL, NULL, OCI_DEFAULT));

	printf("EName:'%s',\t%d,\t%.2f\n", chename, nhgr, dtest);
	memset(chename, 0, 21);
	while (1)
	{
		ub4 status = OCIStmtFetch(stmhp, errhp, 1, OCI_FETCH_NEXT, OCI_DEFAULT);

		if (status == OCI_NO_DATA)
			break;
		else
			HANDLE_ERROR(errhp, status);

		printf("EName:'%s',\t%d,\t%.2f\n", chename, nhgr, dtest);
		memset(chename, 0, 21);
	}
}

void prepare_data_array_binding(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	printf("==========array binding===================================================\n");
	OCIStmt *stmhp;
	text *insstmt = (text *)"INSERT INTO tmpTest (ename,mgr,nval) VALUES (:ENAME,:MGR,:NVAL)";

	char *colName[3] = { ":ENAME", ":MGR", ":NVAL" };
	char *ename[3] = { "SMITH_1", "ALLEN_2", "KING_3" };
	sword mgr[] = { 7886, 7110, 7221 };
	double dval[] = { 1.111, 2.222, 3.333 };

	int nRowCount = 3;
	int nColNameSize = 21;
	void **pDataCache = new void*[3];

	pDataCache[0] = new char[nRowCount * nColNameSize];
	pDataCache[1] = new int[nRowCount];
	pDataCache[2] = new double[nRowCount];

	memset(pDataCache[0], 0, nRowCount * nColNameSize);

printf("TEST A\n");
	for (int i = 0; i < 3; i++)
	{
		memcpy(((char*)pDataCache[0]) + i * nColNameSize, ename[i], std::min(strlen(ename[i]), nColNameSize - sizeof(char)));
		*((int*)pDataCache[1] + i) = mgr[i];
		*((double*)pDataCache[2] + i) = dval[i];
                printf("succeeded TEST A %d\n",i);
	}

	HANDLE_ERROR(errhp, OCIHandleAlloc(envhp, (dvoid **)&stmhp, OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));
	HANDLE_ERROR(errhp, OCIStmtPrepare(stmhp, errhp, insstmt, (ub4)strlen((char *)insstmt), (ub4)OCI_NTV_SYNTAX, (ub4)OCI_DEFAULT));

	sb2 nInd1[3] = { 0, 0, 0 };
	sb2 nInd2[3] = { 0, 0, 0 }; // error
	sb2 nInd3[3] = { -1, -1, -1 }; // { 1, -1, -1 }; // error

#ifdef TESTSTTYLE_1

	OCIBind* pBind1 = (OCIBind*)0;
	OCIBind* pBind2 = (OCIBind*)0;
	OCIBind* pBind3 = (OCIBind*)0;

	HANDLE_ERROR(errhp,
		OCIBindByPos(stmhp, &pBind1, errhp, 1,
		(dvoid *)pDataCache[0], (sb4) 21, SQLT_STR,
			(dvoid *)&nInd1[0],
			0, 0, 0, 0, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIBindByPos(stmhp, &pBind2, errhp, 2,
		(dvoid*)pDataCache[1], sizeof(int), SQLT_INT,
			(dvoid *)&nInd2[0],
			0, 0, 0, 0, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIBindByPos(stmhp, &pBind3, errhp, 3,
		(dvoid*)pDataCache[2], sizeof(double), SQLT_BDOUBLE,
			(dvoid *)&nInd3[0],
			0, 0, 0, 0, OCI_DEFAULT));

#endif

printf("TEST X\n");
	HANDLE_ERROR(errhp,
		OCIStmtExecute(svchp, stmhp, errhp, nRowCount, 0,
		(OCISnapshot *)NULL, (OCISnapshot *)NULL, OCI_BATCH_ERRORS));

	OCITransCommit(svchp, errhp, (ub4)0);

	printf("********************************************\n");
	printf("Array Binding: Data Sucessfully inserted \n & Committed via Transaction\n");
	printf("********************************************\n");

	PrintDataTest(svchp, errhp, stmhp);

	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));
}

void cleanup(OCISvcCtx ** svchp, OCIServer ** srvhp, OCISession ** authp, OCIError ** errhp, OCIEnv ** envhp)
{
	printf("===========cleanup======================================\n");
	/*
	* log off
	*/
	HANDLE_ERROR(*errhp, OCISessionEnd(*svchp, *errhp, *authp, OCI_DEFAULT));
	printf("logged off\n");

	/*
	* detach from server
	*/
	HANDLE_ERROR(*errhp, OCIServerDetach(*srvhp, *errhp, OCI_DEFAULT));
	printf("detached form server\n");

	/*
	* free up handles
	*/
	HANDLE_ERROR(*errhp, OCIHandleFree(*authp, OCI_HTYPE_SESSION));
	/* free session handle */
	*authp = 0;
	HANDLE_ERROR(*errhp, OCIHandleFree(*srvhp, OCI_HTYPE_SERVER));
	/* free server handle */
	*srvhp = 0;
	HANDLE_ERROR(*errhp, OCIHandleFree(*svchp, OCI_HTYPE_SVCCTX));
	/* free service context */
	*svchp = 0;
	HANDLE_ERROR(*errhp, OCIHandleFree(*errhp, OCI_HTYPE_ERROR));
	/* free error handle */
	*errhp = 0;
	OCIHandleFree(*envhp, OCI_HTYPE_ENV);
	/* free environment handle */
	*envhp = 0;
	printf("free'd all handles\n");
}

int main()
{
printf("test1\n");
	/*
	* Declare Handles, a typical OCI program would need at least
	* following handles Environment Handle Error Handle Service Context
	* Handle Server Handle User Session (Authentication Handle)
	*/

	/* Environment */
	OCIEnv *envhp;

	/* Error */
	OCIError *errhp;

	/* Service Context */
	OCISvcCtx *svchp;

	/* Server */
	OCIServer *srvhp;

	/* Session(authentication) */
	OCISession *authp;

	text *chUserName = (text *)"enterprisedb";
	text *chPassword = (text *)"password";
	text *chServer = (text *)"//127.0.0.1:5432/edb";

	initHandles(&svchp, &srvhp, &authp, &errhp, &envhp);

	logon(&svchp, &srvhp, &authp, &errhp, &envhp, chUserName, chPassword, chServer);
printf("test2\n");

	//create_table(svchp, errhp, envhp);
printf("test3\n");

	//prepare_data(svchp, errhp, envhp);

	// array binding test
	prepare_data_array_binding(svchp, errhp, envhp);
printf("test4\n");

	cleanup(&svchp, &srvhp, &authp, &errhp, &envhp);
printf("test5\n");
}
