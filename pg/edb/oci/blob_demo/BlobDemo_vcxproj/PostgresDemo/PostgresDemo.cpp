/* ###########################################################################
Data created with:

CREATE OR REPLACE FUNCTION random_bytea(bytea_length integer)
RETURNS bytea AS $body$
SELECT decode(string_agg(lpad(to_hex(width_bucket(random(), 0, 1, 256)-1),2,'0') ,''), 'hex')
FROM generate_series(1, $1);
$body$
LANGUAGE 'sql'
VOLATILE

########################################################################### */


/* ============================================================================
* Copyright (c) 2004-2015 EnterpriseDB Corporation. All Rights Reserved.
* ===========================================================================
*/
// PostgresDemo.cpp : main project file.

#include "stdafx.h"


//int main(array<System::String ^> ^args)
//{
//    Console::WriteLine(L"Hello World");
//    return 0;
//}
//



/* ============================================================================
* Copyright (c) 2004-2015 EnterpriseDB Corporation. All Rights Reserved.
* ===========================================================================
*/
#include <stdio.h>
#include <stdlib.h>
//#include <sys/time.h>
#include <string.h>
#include <oci.h>


/* Define a macro to handle errors */
#define HANDLE_ERROR(x,y) check_oci_error(x,y)

#define DATE_FMT "DAY, MONTH DD, YYYY"
#define DATE_LANG "American"

sword ConvertStringToDATE(char *datep, char *formatp, dvoid *datepp);
/* A Custom Routine to handle errors,	 */

/* this demonstrates the Error/ Exception Handling in OCI */
void check_oci_error(dvoid * errhp, sword status);

/*
* <<<<<<<<<<<<<<<<<<< FUNCTION PROTOTYPES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*/

/* Initialize	& Allocate all handles */
void
initHandles(OCISvcCtx **, OCIServer **, OCISession **, OCIError **,
	OCIEnv **);

/* logon to the database and begin user-session */
void
logon(OCISvcCtx **, OCIServer **, OCISession **, OCIError **,
	OCIEnv **, text *, text *, text *);

/* Create required table(s)  */
void create_table(OCISvcCtx *, OCIError *, OCIEnv *);

/* prepare data for our examples */
void prepare_data(OCISvcCtx *, OCIError *, OCIEnv *);

/* prepare data for our examples */
void prepare_data2(OCISvcCtx *, OCIError *, OCIEnv *);

/* create procedures/functions to demonstrate in the example */
void create_stored_procs(OCISvcCtx *, OCIError *, OCIEnv *);

/* select and print data by iterating through resultSet */
void select_print_data(OCISvcCtx *, OCIError *, OCIEnv *);

/* select and print data by iterating through resultSet */
void select_print_data2(OCISvcCtx *, OCIError *, OCIEnv *);


/* demonstrate calling stored procedures and retrieving values */

/* proc1 demonstrates IN OUT */
void call_stored_proc1(OCISvcCtx *, OCIError *, OCIEnv *);

/* proc2 demonstrates OUT */
void call_stored_proc2(OCISvcCtx *, OCIError *, OCIEnv *);

/* drop required table(s) */
void drop_table(OCISvcCtx *, OCIError *, OCIEnv *);

/* drop stored procedures and functions */
void drop_stored_procs(OCISvcCtx *, OCIError *, OCIEnv *);

/* clean-up main handles before exit */
void cleanup(OCISvcCtx **, OCIServer **, OCISession **, OCIError **, OCIEnv **);


/* BLOB stuff */
void ReadBlob(OCISvcCtx * , OCIError * , OCIEnv * );

static sb4 read_callback(dvoid *ctxp, const void *bufp, ub4 len, ub1 piece)
{
	/* This callback is called for each piece of data that is read in the OCILobRead call.
	* In oracle_blob_read the piece of data fits in the buffer, so there is just one piece.
	* The callback now just asserts that it is the last PIECE.
	*/

	sb4 result;

	switch (piece)
	{
	case OCI_FIRST_PIECE:  printf("callback - len = %d, piece = OCI_FIRST_PIECE\n", len); break;
	case OCI_NEXT_PIECE:   printf("callback - len = %d, piece = OCI_NEXT_PIECE\n", len); break;
	case OCI_LAST_PIECE:   printf("callback - len = %d, piece = OCI_LAST_PIECE\n", len); break;
	default:
		printf("callback - len = %d, UNEXPECTED piece = %d\n", len, piece); break;
	}

	result = OCI_CONTINUE;

	return result;
}

static int blob_locate(char *tableName, char *lobName, char *keyName, char *keyvalue, OCIEnv *env, OCIError *err, OCILobLocator **plocator, OCISvcCtx *svc)
{
	OCIBind   *bindp = 0;
	OCIDefine *defnp = 0;
	OCIStmt   *stmt = 0;
	char	   sql[1024];
	int		   ret;

	sprintf(sql, "select %s from %s where %s = '%s'", lobName, tableName, keyName, keyvalue);
	printf("%s", sql);
	if ((ret = OCIHandleAlloc(env, (dvoid **)&stmt, OCI_HTYPE_STMT, 0, NULL)) == 0)
	{
		if ((ret = OCIStmtPrepare(stmt, err, (OraText *)sql, (ub4)strlen(sql), OCI_NTV_SYNTAX, OCI_DEFAULT)) != 0)
		{
			check_oci_error(err, ret);
			ret = -1;
		}
	}

	/*if (ret == 0)
	{
		if ((ret = OCIBindByName(stmt, &bindp, err, (OraText *)":1", -1, &pkey, sizeof(pkey), SQLT_INT, NULL, NULL, NULL, 0, 0, OCI_DEFAULT)) != 0)
		{
			check_oci_error(err, ret);
			ret = -1;
		}
	}*/

	if (ret == 0)
	{
		if ((ret = OCIDescriptorAlloc(env, (dvoid **)plocator, OCI_DTYPE_LOB, 0, NULL)) != 0)
		{
			check_oci_error(err, ret);
			ret = -1;
		}
	}

	if (ret == 0)
	{
		if ((ret = OCIDefineByPos(stmt, &defnp, err, 1, plocator, sizeof(plocator), SQLT_BLOB, 0, 0, 0, OCI_DEFAULT)) != 0)
		{
			check_oci_error(err, ret);
			ret = -1;
		}
	}

	if (ret == 0)
	{
		if ((ret = OCIStmtExecute(svc, stmt, err, 0, 0, 0, 0, OCI_DEFAULT)) != 0)
		{
			check_oci_error(err, ret);
			ret = -1;
		}
	}

	if (ret == 0)
	{
		if ((ret = OCIStmtFetch(stmt, err, 1, OCI_FETCH_NEXT, OCI_DEFAULT)) != 0)
		{
			check_oci_error(err, ret);
			ret = -1;
		}
	}

	if (stmt)
		OCIHandleFree(stmt, OCI_HTYPE_STMT);

	return ret;
}

/*
* <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION PROTOYPES<<<<<<<<<<<<<<<<<<<<<<<<<<
*/


/* <<<<<<<<<< Global Variables */
ub4 init_mode = OCI_DEFAULT;
ub4 auth_mode = OCI_CRED_RDBMS;

/* <<<<<<<<<< End Global Variables */

int main(void)
{

	/*
	* Declare Handles, a typical OCI program would need atleast
	* following handles Enviroment Handle Error Handle Service Context
	* Handle Server Handle User Session (Authentication Handle)
	*/

	/* Enviroment */
	OCIEnv *envhp;

	/* Error */
	OCIError *errhp;

	/* Service Context */
	OCISvcCtx *svchp;

	/* Server */
	OCIServer *srvhp;

	/* Session(authentication) */
	OCISession *authp;


	/*
	* End of Handle declaration
	*/

	/*
	* Declare local variables,
	*/
	text *username = (text *) "enterprisedb";
	text *passwd = (text *) "edb"; //"edb";

											  ///*
											  //* Oracle Instant Client Connection String
											  //*/
											  //text *server = (text *) "//127.0.0.1:5432/edb";
	text *server = (text *) "//localhost:5444/edb";

	/*
	* Initialize and Allocate handles
	*/
	initHandles(&svchp, &srvhp, &authp, &errhp, &envhp);

	/*
	* logon to the database
	*/
	logon(&svchp, &srvhp, &authp, &errhp, &envhp, username, passwd, server);

	/*
	* Create table(s) required for this example
	*/
	//create_table (svchp, errhp, envhp);


	/*
	* insert data into table
	*/
	//prepare_data2 (svchp, errhp, envhp);

	/*
	* create stored procedures & functions
	*/
	//create_stored_procs (svchp, errhp, envhp);

	/*
	* select and print data by iterating through simple resultSet
	*/
	//select_print_data2(svchp, errhp, envhp);

	/*
	* demonstrate calling stored procedures and retrieving values
	*/
	//call_stored_proc1 (svchp, errhp, envhp);

	/*
	* demonstrate OUT parameters
	*/
	//call_stored_proc2 (svchp, errhp, envhp);

	/*
	* Drop table(s) used in this example
	*/
	//drop_table (svchp, errhp, envhp);

	/*
	* Drop stroed procedures & functions used in this example
	*/
	//drop_stored_procs (svchp, errhp, envhp);

	//LOB

	ReadBlob(svchp, errhp, envhp);

	//END LOB






	/*
	* clean up resources
	*/
	cleanup(&svchp, &srvhp, &authp, &errhp, &envhp);

	return 0;
}

/* A Custom Routine to handle errors,	 */

void check_oci_error(dvoid * errhp, sword status)
{
	text errbuf[512];
	sb4 errcode;

	if (status == OCI_SUCCESS)
	{
		return;
	}
	switch (status)
	{
	case OCI_SUCCESS_WITH_INFO:
		printf("OCI_SUCCESS_WITH_INFO:\n");
		OCIErrorGet(errhp, (ub4)1, (text *)0, &errcode,
			errbuf, (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
		printf("%s", errbuf);
		break;
	case OCI_NEED_DATA:
		printf("Error - OCI_NEED_DATA\n");
		break;
	case OCI_NO_DATA:
		printf("Error - OCI_NO_DATA\n");
		break;
	case OCI_ERROR:
		printf("Error - OCI_ERROR:\n");
		OCIErrorGet(errhp, (ub4)1, (text *)0, &errcode,
			errbuf, (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
		printf("%s", errbuf);
		break;
	case OCI_INVALID_HANDLE:
		printf("Error - OCI_INVALID_HANDLE\n");
		break;
	case OCI_STILL_EXECUTING:
		printf("Error - OCI_STILL_EXECUTING\n");
		break;
	case OCI_CONTINUE:
		printf("Error - OCI_CONTINUE\n");
		break;
	default:
		break;
	}

	/*
	* exit app
	*/
	exit((int)status);
}

/* Initialize & Allocate required handles */
void initHandles(OCISvcCtx ** svchp, OCIServer ** srvhp, OCISession ** authp,
	OCIError ** errhp, OCIEnv ** envhp)
{

	/*
	* Now Starts the Section where we have to initialize & Allocate
	* basic handles. This is a compulsory setup or initilization which
	* is required before we can proceed to logon and work with the
	* database. This initialization and prepration will include the
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

	/*
	* Initialize OCI
	*/
	if (OCIInitialize(init_mode, (dvoid *)0,
		(dvoid * (*)(dvoid *, size_t)) 0,
		(dvoid * (*)(dvoid *, dvoid *, size_t)) 0,
		(void(*)(dvoid *, dvoid *)) 0) != OCI_SUCCESS)
	{
		printf("ERROR: failed to initialize OCI\n");
		exit(1);
	}
	/*
	* Initialize Enviroment.
	*/
	HANDLE_ERROR(*envhp,
		OCIEnvInit(&(*envhp), OCI_DEFAULT, (size_t)0,
			(dvoid **)0));

	/*
	* Initialize & Allocate Error Handle
	*/
	HANDLE_ERROR(*envhp,
		OCIHandleAlloc(*envhp, (dvoid **)& (*errhp),
			OCI_HTYPE_ERROR, (size_t)0, (dvoid **)0));

	/*
	* Initialize & Allocate Service Context Handle
	*/
	HANDLE_ERROR(*errhp,
		OCIHandleAlloc(*envhp, (dvoid **)& (*svchp),
			OCI_HTYPE_SVCCTX, (size_t)0, (dvoid **)0));

	/*
	* Initialize & Allocate Session Handle
	*/
	HANDLE_ERROR(*errhp,
		OCIHandleAlloc(*envhp, (dvoid **)& (*authp),
			OCI_HTYPE_SESSION, (size_t)0, (dvoid **)0));

	/*
	* Initialize & Allocate Server Handle
	*/
	HANDLE_ERROR(*errhp,
		OCIHandleAlloc(*envhp, (dvoid **)& (*srvhp),
			OCI_HTYPE_SERVER, (size_t)0, (dvoid **)0));

}

void logon(OCISvcCtx ** svchp, OCIServer ** srvhp, OCISession ** authp,
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

	HANDLE_ERROR(*errhp,
		OCIServerAttach(*srvhp, *errhp, server,
			(ub4)strlen((char *)server),
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

	HANDLE_ERROR(*errhp,
		OCIAttrSet(*svchp, OCI_HTYPE_SVCCTX,
			(dvoid *)(*srvhp), (ub4)0, OCI_ATTR_SERVER,
			*errhp));

	/*
	* Set the username and password into session handle
	*/

	HANDLE_ERROR(*errhp,
		OCIAttrSet(*authp, OCI_HTYPE_SESSION,
			(dvoid *)username,
			(ub4)strlen((char *)username),
			OCI_ATTR_USERNAME, *errhp));
	HANDLE_ERROR(*errhp,
		OCIAttrSet(*authp, OCI_HTYPE_SESSION, (dvoid *)passwd,
			(ub4)strlen((char *)passwd), OCI_ATTR_PASSWORD,
			*errhp));

	/*
	* Now FINALLY Begin our session
	*/

	HANDLE_ERROR((*errhp),
		OCISessionBegin(*svchp, *errhp,
			*authp, auth_mode, OCI_DEFAULT));

	printf("********************************************\n");
	printf("Milestone  : Logged on as --> '%s'\n", username);
	printf("********************************************\n");

	/*
	* After we Begin our session we will have to set the Session
	*/

	/*
	* (authentication) handle into Service Context Handle
	*/

	HANDLE_ERROR(*errhp,
		OCIAttrSet(*svchp, OCI_HTYPE_SVCCTX,
			(dvoid *)(*authp), (ub4)0,
			OCI_ATTR_SESSION, *errhp));
}

/* Create table(s) required for this example */
void create_table(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *stmhp;
	text *create_statement =
		(text *)"CREATE TABLE OCISPEC \n (ENAME VARCHAR2(20)\n, MGR NUMBER\n, HIREDATE DATE\n, PHOTO BYTEA)";
	ub4 status = OCI_SUCCESS;

	/*
	* Initialize & Allocate Statement Handle
	*/
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));


	/*
	* Prepare the Create statement
	*/

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp,
			create_statement,
			strlen((const char *)create_statement),
			OCI_NTV_SYNTAX, OCI_DEFAULT));


	/*
	* Execute the Create Statement
	*/
	if ((status = OCIStmtExecute(svchp, stmhp, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
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

/* prepare data for our examples */
void prepare_data(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *stmhp;
	text *insstmt =
		(text *)
		"INSERT INTO OCISPEC (ename,mgr, hiredate, photo) VALUES (:ENAME,:MGR, CAST(:HIREDATE AS timestamp), random_bytea(400000))";
	OCIBind *bnd1p = (OCIBind *)0;	/* the first bind handle   */
	OCIBind *bnd2p = (OCIBind *)0;	/* the second bind handle */
	OCIBind *bnd3p = (OCIBind *)0;	/* the third bind handle   */
	ub4 status = OCI_SUCCESS;
	int i = 0;

	char *ename[3] = { "SMITH2", "ALLEN2", "KING2" };

	sword mgr[] = { 7886, 7110, 7221 };

	char *date_buffer[3] = { "02-AUG-07", "02-APR-07", "02-MAR-07" };

	/*
	* Initialize & Allocate Statement Handle
	*/
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	/*
	* Prepare the insert statement
	*/
	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp, insstmt,
			(ub4)strlen((char *)insstmt),
			(ub4)OCI_NTV_SYNTAX, (ub4)OCI_DEFAULT));

	/*
	* In this loop we will bind data from the arrays to insert multi
	* rows in the database a more elegant and better way to do this is
	* to use Array Binding (Batch Inserts). EnterpriseDB OCI Replacement
	* Library WILL support Array Bindings even if it is not used here
	* right now
	*/
	for (i = 0; i < 3; i++)
	{
		/*
		* Bind Variable for ENAME
		*/
		HANDLE_ERROR(errhp,
			OCIBindByName(stmhp, &bnd1p, errhp, (text *) ":ENAME",
				-1, (dvoid *)ename[i],
				(sb4)strlen(ename[i]) + 1, SQLT_STR,
				(dvoid *)0, 0, (ub2 *)0, (ub4)0,
				(ub4 *)0, OCI_DEFAULT));

		/*
		* Bind Variable for MGR
		*/
		HANDLE_ERROR(errhp,
			OCIBindByName(stmhp, &bnd2p, errhp, (text *) ":MGR",
				-1, (dvoid *)& mgr[i], sizeof(mgr[i]),
				SQLT_INT, (dvoid *)0, 0, (ub2 *)0,
				(ub4)0, (ub4 *)0, OCI_DEFAULT));

		/*
		* Bind Variable for HIREDATE
		*/
		HANDLE_ERROR(errhp,
			OCIBindByName(stmhp, &bnd3p, errhp, (text *) ":HIREDATE",
				-1, (dvoid *)date_buffer[i],
				strlen(date_buffer[i]) + 1, SQLT_STR, (dvoid *)0, 0,
				(ub2 *)0, (ub4)0, (ub4 *)0,
				OCI_DEFAULT));

		/*
		* Execute the statement and insert data
		*/
		if ((status = OCIStmtExecute(svchp, stmhp, errhp,
			(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
		{
			printf("FAILURE IN INSERTING DATA\n");
			HANDLE_ERROR(errhp, status);
			return;
		}
	}

	OCITransCommit(svchp, errhp, (ub4)0);
	printf("********************************************\n");
	printf
		("MileStone : Data Sucessfully inserted \n & Committed via Transaction\n");
	printf("********************************************\n");
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));

}


void prepare_data2(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	ub1 photo[400000];
	{

		//char* photo = new char[400000];
		OCIRaw*photo_raw = (OCIRaw *)1;
		ub2 *myphotolength;

		/* Statement */
		OCIStmt *stmhp;

		/* Define */
		OCIDefine *define;

		/*Buffer for photo */
		sword photo_status;
		//ub1 photo[400000];

		/*
		* a simple select statement
		*/
		text * sql_statement = (text *) "select photo from ocispec where ename = 'SMITH'";
		//(text *) "select ename,mgr,hiredate,photo from ocispec where ename = :ENAME";
		//(text *) "select grid from on_line.antenna_gain where id = '{011D4E0A-1943-4549-A961-86FC1E317074}'";


		//**********************************************************************************
		//**********************************************************************************
		//**********************************************************************************

		/*
		* additional local variables
		*/

		ub4 rows = 1;
		ub4 fetched = 1;
		ub4 status = OCI_SUCCESS;

		/* null indicator for mgr */
		sb2 null_ind_photo = 0;

		/* null indicator for hiredate */

		/*
		* Now we are going to start the Milestone of a Simple Query of the
		* database and loop through the resultSet This would include
		* following steps
		*
		* 1. Initialize and Allocate the Statement Handle 2. Prepare the
		* Statement 3. Define Output variables to recieve the output of the
		* select statement 4. Execute the statement 5. Fetch the resultset
		* and Print values
		*
		*/
		memset(photo, 0, sizeof(photo));

		/*
		* Initialize & Allocate Statement Handle
		*/

		HANDLE_ERROR(errhp,
			OCIHandleAlloc(envhp, (dvoid **)& stmhp,
				OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));


		/*
		* Prepare the statement
		*/

		HANDLE_ERROR(errhp,
			OCIStmtPrepare(stmhp, errhp,
				sql_statement,
				strlen((const char *)sql_statement),
				OCI_NTV_SYNTAX, OCI_DEFAULT));


		/*
		* Bind a String (OCIString) variable on position 1. Datatype used
		* SQLT_VST
		*/

		HANDLE_ERROR(errhp,
			OCIDefineByPos(stmhp, &define, errhp,
				(ub4)1, photo, 400000,
				(ub2)SQLT_BIN, &null_ind_photo, myphotolength, 0,
				OCI_DEFAULT));

		/*
		* Execute the simple SQL Statement
		*/
		status = OCIStmtExecute(svchp, stmhp, errhp,
			rows, (ub4)0, NULL, NULL, OCI_DEFAULT);


		/*
		* Print the Resultset
		*/
		if (status == OCI_NO_DATA)
		{
			/*
			* indicates didn't fetch anything (as we're not array
			* fetching)
			*/
			fetched = 0;
		}
		else
		{
			HANDLE_ERROR(errhp, status);
		}

		if (fetched)
		{
			if (null_ind_photo == -1)
				printf("photo -> [NULL]\n");
			else
			{
				//photo_status = OCIRawAssignBytes(envhp, errhp, photo, 8000, &photo_raw);
				//OCIRawSize(envhp, photo_raw);
				//printf("photo_raw -> [%d]\n", *myphotolength); //CRASH HERE
				//printf ("photo -> [%s]\n", photo );
				printf("photo -> [%s]\n", photo);
				printf("photo -> [323286 = %c]\n", photo[323286]);
				printf("photo -> [323286 = %d]\n", photo[323286]);
				printf("photo -> [323287 = %c]\n", photo[323287]);
				printf("photo -> [323287 = %d]\n", photo[323287]);
				printf("photo -> [323288 = %c]\n", photo[323288]);
				printf("photo -> [323288 = %d]\n", photo[323288]);
			}

			/*
			* loop through the resultset one by one through
			* OCIStmtFetch()
			*/




			/*
			* untill we find nothing
			*/
			while (1)
			{
				status = OCIStmtFetch(stmhp, errhp,
					rows, OCI_FETCH_NEXT, OCI_DEFAULT);
				if (status == OCI_NO_DATA)
				{
					/*
					* indicates couldn't fetch anything
					*/
					break;
				}
				else
				{
					HANDLE_ERROR(errhp, status);
				}

				if (null_ind_photo == -1)
					printf("photo -> [NULL]\n");
				else
				{
					//photo_status = OCIRawAssignBytes(envhp, errhp, photo, 8000, &photo_raw);
					//OCIRawSize(envhp, photo_raw);


					//printf("photo_raw -> [%d]\n", *myphotolength);
					printf("photo -> [%s]\n", photo);
					printf("photo -> [%c]\n", photo[323288]);
				}
			}
		}
		HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));



	}
	{
		OCIStmt *stmhp;
		text *insstmt =
			(text *)
			"INSERT INTO OCISPEC (ename,mgr, hiredate, photo) VALUES (:ENAME,:MGR, CAST(:HIREDATE AS timestamp), :PHOTO)";
		OCIBind *bnd1p = (OCIBind *)0;	/* the first bind handle   */
		OCIBind *bnd2p = (OCIBind *)0;	/* the second bind handle */
		OCIBind *bnd3p = (OCIBind *)0;	/* the third bind handle   */
		ub4 status = OCI_SUCCESS;
		int i = 0;

		char *ename[3] = { "SMITH_", "ALLEN_", "KING_" };

		sword mgr[] = { 1111, 2222, 3333 };

		char *date_buffer[3] = { "02-AUG-07", "02-APR-07", "02-MAR-07" };

		/*
		* Initialize & Allocate Statement Handle
		*/
		HANDLE_ERROR(errhp,
			OCIHandleAlloc(envhp, (dvoid **)& stmhp,
				OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

		/*
		* Prepare the insert statement
		*/
		HANDLE_ERROR(errhp,
			OCIStmtPrepare(stmhp, errhp, insstmt,
				(ub4)strlen((char *)insstmt),
				(ub4)OCI_NTV_SYNTAX, (ub4)OCI_DEFAULT));

		/*
		* In this loop we will bind data from the arrays to insert multi
		* rows in the database a more elegant and better way to do this is
		* to use Array Binding (Batch Inserts). EnterpriseDB OCI Replacement
		* Library WILL support Array Bindings even if it is not used here
		* right now
		*/
		for (i = 0; i < 3; i++)
		{
			/*
			* Bind Variable for ENAME
			*/
			HANDLE_ERROR(errhp,
				OCIBindByName(stmhp, &bnd1p, errhp, (text *) ":ENAME",
					-1, (dvoid *)ename[i],
					(sb4)strlen(ename[i]) + 1, SQLT_STR,
					(dvoid *)0, 0, (ub2 *)0, (ub4)0,
					(ub4 *)0, OCI_DEFAULT));

			/*
			* Bind Variable for MGR
			*/
			HANDLE_ERROR(errhp,
				OCIBindByName(stmhp, &bnd2p, errhp, (text *) ":MGR",
					-1, (dvoid *)& mgr[i], sizeof(mgr[i]),
					SQLT_INT, (dvoid *)0, 0, (ub2 *)0,
					(ub4)0, (ub4 *)0, OCI_DEFAULT));

			/*
			* Bind Variable for HIREDATE
			*/
			HANDLE_ERROR(errhp,
				OCIBindByName(stmhp, &bnd3p, errhp, (text *) ":HIREDATE",
					-1, (dvoid *)date_buffer[i],
					strlen(date_buffer[i]) + 1, SQLT_STR, (dvoid *)0, 0,
					(ub2 *)0, (ub4)0, (ub4 *)0,
					OCI_DEFAULT));

			/*
			* Bind Variable for PHOTO
			*/
			HANDLE_ERROR(errhp,
				OCIBindByName(stmhp, &bnd3p, errhp, (text *) ":PHOTO",
					-1, (dvoid *)photo,
					400000, SQLT_BIN, (dvoid *)0, 0,
					(ub2 *)0, (ub4)0, (ub4 *)0,
					OCI_DEFAULT));

			/*
			* Execute the statement and insert data
			*/
			if ((status = OCIStmtExecute(svchp, stmhp, errhp,
				(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
			{
				printf("FAILURE IN INSERTING DATA\n");
				HANDLE_ERROR(errhp, status);
				return;
			}
		}

		OCITransCommit(svchp, errhp, (ub4)0);
		printf("********************************************\n");
		printf
			("MileStone : Data Sucessfully inserted \n & Committed via Transaction\n");
		printf("********************************************\n");
		HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));
	}
}

/* Create Stored procedures and functions to be used in this example */
void create_stored_procs(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	/*
	* This function created 2 stored procedures and one stored function
	* 1. StoredProcedureSample1 - is to exhibit exeucting procedure and
	* recieving values from an IN OUT parameter 2.
	* StoredProcedureSample2 - is to exhibit executing procedure and
	* recieving values from an OUT parameter 3. StoredProcedureSample3 -
	* is to exhibit executing a function and recieving the value
	* returned by the function in a Callable Statement way
	*/
	OCIStmt *stmhp;
	OCIStmt *stmhp2;
	OCIStmt *stmhp3;

	text *create_statement =
		(text *)"CREATE OR REPLACE PROCEDURE StoredProcedureSample1\n (mgr1 int, ename1 IN OUT varchar2)\n   is\nbegin\ninsert into ocispec (mgr, ename) values (7990,'STOR1');\nename1 := 'Successful';\n end;\n";

	text *create_statement2 =
		(text *)"CREATE OR REPLACE PROCEDURE StoredProcedureSample2\n(mgr1 int, ename1 varchar2,eout1 OUT varchar2)\nis\nbegin\ninsert into ocispec(mgr,ename) values (7991, 'STOR2');\neout1 := 'Successful';\n	end;";

	text *create_statement3 =
		(text *)"CREATE OR REPLACE FUNCTION f1\nRETURN VARCHAR2\nis\nv_Sysdate DATE;\nv_charSysdate VARCHAR2(20);\nbegin\nSELECT TO_CHAR(SYSDATE, 'dd-mon-yyyy') into v_charSysdate FROM DUAL;\n	return(v_charSysdate);\nend;";



	ub4 status = OCI_SUCCESS;

	/*
	* Initialize & Allocate Statement Handles
	*/
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp2,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp3,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	/*
	* Prepare the Create statements
	*/

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp,
			create_statement,
			strlen((const char *)create_statement),
			OCI_NTV_SYNTAX, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp2, errhp, create_statement2,
			strlen((const char *)create_statement2),
			OCI_NTV_SYNTAX, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp3, errhp, create_statement3,
			strlen((const char *)create_statement3),
			OCI_NTV_SYNTAX, OCI_DEFAULT));

	/*
	* Execute the Create Statement SampleProcedure1
	*/
	if ((status = OCIStmtExecute(svchp, stmhp, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN CREATING PROCEDURE 1\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Sample Procedure 1 Successfully created\n");
		printf("********************************************\n");

	}

	/*
	* Execute the Create Statement Sample Procedure2
	*/
	if ((status = OCIStmtExecute(svchp, stmhp2, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN CREATING PROCEDURE 2\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Sample Procedure 2 Successfully created\n");
		printf("********************************************\n");
	}

	/*
	* Execute the Create Statement Sample Procedure3
	*/
	if ((status = OCIStmtExecute(svchp, stmhp3, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN CREATING PROCEDURE 3\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Sample Procedure 3 Successfully created\n");
		printf("********************************************\n");
	}


	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp2, OCI_HTYPE_STMT));
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp3, OCI_HTYPE_STMT));
}

/* select and print data by iterating through resultSet */
void select_print_data(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{

	/* Statement */
	OCIStmt *stmhp;

	/* Define */
	OCIDefine *define;

	/* Buffer for employee Name */
	char ename_buffer[10];

	/* Buffer for mgr */
	sword mgr_buffer;

	/*Buffer for hiredate */
	char hire_date[19];

	/*Buffer for photo */
	sword photo_status;
	//ub1 photo[400000];
	char* photo = new char[400000];
	OCIRaw*photo_raw = (OCIRaw *)1;
	ub2 *myphotolength;

	//printf("photo -> [%c]\n", photo[323286]);
	//printf("photo -> [%c]\n", photo[323287]);
	//printf("photo -> [%c]\n", photo[323288]);

	/*
	* a simple select statement
	*/
	text * sql_statement = (text *) "select ename,mgr,hiredate,photo from ocispec";
		//(text *) "select ename,mgr,hiredate,photo from ocispec where ename = :ENAME";
	//(text *) "select grid from on_line.antenna_gain where id = '{011D4E0A-1943-4549-A961-86FC1E317074}'";


	//**********************************************************************************
	//**********************************************************************************
	//**********************************************************************************

	/*
	* additional local variables
	*/

	ub4 rows = 1;
	ub4 fetched = 1;
	ub4 status = OCI_SUCCESS;

	sb2 null_ind_ename = 0;

	/* null indicator for ename */
	sb2 null_ind_mgr = 0;

	/* null indicator for mgr */
	sb2 null_ind_hiredate = 0;

	/* null indicator for mgr */
	sb2 null_ind_photo = 0;

	/* null indicator for hiredate */

	/*
	* Now we are going to start the Milestone of a Simple Query of the
	* database and loop through the resultSet This would include
	* following steps
	*
	* 1. Initialize and Allocate the Statement Handle 2. Prepare the
	* Statement 3. Define Output variables to recieve the output of the
	* select statement 4. Execute the statement 5. Fetch the resultset
	* and Print values
	*
	*/
	memset(ename_buffer, 0, sizeof(ename_buffer));
	memset(hire_date, 0, sizeof(hire_date));
	memset(photo, 0, sizeof(photo));

	//printf("photo -> [323286 = %c]\n", photo[323286]);
	//printf("photo -> [323286 = %d]\n", photo[323286]);
	//printf("photo -> [323287 = %c]\n", photo[323287]);
	//printf("photo -> [323287 = %d]\n", photo[323287]);
	//printf("photo -> [323288 = %c]\n", photo[323288]);
	//printf("photo -> [323288 = %d]\n", photo[323288]);

	/*
	* Initialize & Allocate Statement Handle
	*/

	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));


	/*
	* Prepare the statement
	*/

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp,
			sql_statement,
			strlen((const char *)sql_statement),
			OCI_NTV_SYNTAX, OCI_DEFAULT));


	/*
	* Bind a String (OCIString) variable on position 1. Datatype used
	* SQLT_VST
	*/
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp,
			(ub4)1, ename_buffer, 10,
			(ub2)SQLT_STR, &null_ind_ename, 0, 0,
			OCI_DEFAULT));

	/*
	* Bind a Number (OCINumber) variable on position 2. Datatype used
	* SQLT_VNU
	*/
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp,
			(ub4)2, &mgr_buffer, sizeof(sword),
			(ub2)SQLT_INT, &null_ind_mgr, 0, 0,
			OCI_DEFAULT));

	/*
	* Bind a Date (OCIDate) variable on position 3. Datatype used
	* SQLT_ODT
	*/
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp,
			(ub4)3, hire_date, 19,
			(ub2)SQLT_STR, &null_ind_hiredate, 0, 0,
			OCI_DEFAULT));

	/*
	* Bind a RAW (OCIRaw) variable on position 4. Datatype used
	* SQLT_BIN
	*/
	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp,
			(ub4)4, photo, 400000,
			(ub2)SQLT_BIN, &null_ind_photo, myphotolength, 0,
			OCI_DEFAULT));

	/*HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp,
			(ub4)1, photo, 400000,
			(ub2)SQLT_BIN, &null_ind_photo, myphotolength, 0,
			OCI_DEFAULT));*/

	/*
	* Execute the simple SQL Statement
	*/

	//TODAY
	//OCIBind *bnd1p = (OCIBind *)0;	/* the first bind handle   */
	//char *ename[3] = { "SMITH", "ALLEN", "KING" };

	//HANDLE_ERROR(errhp, OCIBindByName(stmhp, &bnd1p, errhp, (text *) ":ENAME",
	//	-1, (dvoid *)ename[1],
	//	(sb4)strlen(ename[1]) + 1, SQLT_STR,
	//	(dvoid *)0, 0, (ub2 *)0, (ub4)0,
	//	(ub4 *)0, OCI_DEFAULT));
	//END TODAY

	status = OCIStmtExecute(svchp, stmhp, errhp,
		rows, (ub4)0, NULL, NULL, OCI_DEFAULT);

	//TODAY
	//	ub4 col_count = 0;
	//
	//	HANDLE_ERROR(errhp, OCIAttrGet(stmhp, OCI_HTYPE_STMT, &col_count, 0, OCI_ATTR_PARAM_COUNT, errhp));
	//
	//
	//	for (int pos = 1; pos <= col_count; pos++)
	//	{
	//		OCIParam * ptr = 0;
	//		HANDLE_ERROR(errhp, OCIParamGet(stmhp, OCI_HTYPE_STMT, errhp, (void**)&ptr, pos));
	//
	//		void * descriptorp;
	//		if (ptr == 0)
	//		{
	//			if (OCIDescriptorAlloc(envhp, &descriptorp, OCI_DTYPE_PARAM, 0, 0) != OCI_SUCCESS)
	//				descriptorp = 0;
	//		}
	//		else
	//		{
	//			descriptorp = ptr;
	//		}
	//
	//		ub4 len;
	//		char * name;
	//
	//		HANDLE_ERROR(errhp, OCIAttrGet(descriptorp, OCI_DTYPE_PARAM, &name, &len, OCI_ATTR_NAME, errhp));
	//		char * str;
	//		unsigned long* _data = reinterpret_cast<unsigned long*>(new char[sizeof(unsigned long) + len + 1]);
	//		*_data = 1;
	//		str = reinterpret_cast<char*>(_data + 1);
	//
	//
	//#pragma warning(disable: 4996)
	//		strncpy(str, name, len);
	//		str[len] = 0;
	//#pragma warning(default: 4996) // Restore warnings
	//
	//		ub2 datatype;
	//		HANDLE_ERROR(errhp, OCIAttrGet(descriptorp, OCI_DTYPE_PARAM, &datatype, 0, OCI_ATTR_DATA_TYPE, errhp));
	//
	//		ub4 size; //size of the data
	//		switch (datatype)
	//		{
	//			case SQLT_INT:
	//				break;
	//			case SQLT_UIN:
	//				break;
	//			case SQLT_NUM:
	//			case SQLT_FLT:
	//				break;
	//			case SQLT_DAT:	// DATE
	//				break;
	//			case SQLT_BIN: // RAW
	//				HANDLE_ERROR(errhp, OCIAttrGet(descriptorp, OCI_DTYPE_PARAM, &size, 0, OCI_ATTR_DATA_SIZE, errhp));
	//				break;
	//			case SQLT_BLOB:
	//				size = sizeof(OCILobLocator*);
	//				break;
	//			case SQLT_BFILE:
	//				size = sizeof(OCILobLocator*);
	//				break;
	//			case SQLT_CLOB:
	//				size = sizeof(OCILobLocator*);
	//				break;
	//			case SQLT_CHR: // VARCHAR2
	//			case SQLT_AFC: // CHAR
	//			case SQLT_RID: // ROWID
	//			default:
	//				break;
	//		}
	//	}
	//
	//END TODAY
	/*
	* Print the Resultset
	*/
	if (status == OCI_NO_DATA)
	{
		/*
		* indicates didn't fetch anything (as we're not array
		* fetching)
		*/
		fetched = 0;
	}
	else
	{
		HANDLE_ERROR(errhp, status);
	}

	if (fetched)
	{
		/*
		* print string
		*/
		if (null_ind_ename == -1)
			printf("name -> [NULL]\t");
		else
			printf("name -> [%s]\t", ename_buffer);


		/*
		* print number by converting it into int
		*/
		if (null_ind_mgr == -1)
			printf("mgr -> [NULL]\n");
		else
		{
			printf("mgr -> [%d]\n", mgr_buffer);
		}

		if (null_ind_hiredate == -1)
			printf("hiredate -> [NULL]\n");
		else
		{
			printf("hiredate -> [%s]\n", hire_date);
		}

		if (null_ind_photo == -1)
			printf("photo -> [NULL]\n");
		else
		{
			//photo_status = OCIRawAssignBytes(envhp, errhp, photo, 8000, &photo_raw);
			//OCIRawSize(envhp, photo_raw);
			//printf("photo_raw -> [%d]\n", *myphotolength); //CRASH HERE
			//printf ("photo -> [%s]\n", photo );
			printf("photo -> [%s]\n", photo);
			printf("photo -> [323286 = %c]\n", photo[323286]);
			printf("photo -> [323286 = %d]\n", photo[323286]);
			printf("photo -> [323287 = %c]\n", photo[323287]);
			printf("photo -> [323287 = %d]\n", photo[323287]);
			printf("photo -> [323288 = %c]\n", photo[323288]);
			printf("photo -> [323288 = %d]\n", photo[323288]);

			int count = 0;
			for (int i = 0; i < 400000; i++)
			{
				if ((int)photo[i] < 0)
				{
					//printf("photo -> [%d = %d - char %c]\n", i, photo[i], photo[i]);
					count++;
				}

				if ((int)photo[i] > 127)
				{
					//printf("photo -> [%d = %d - char %c]\n", i, photo[i], photo[i]);
					count++;
				}
			}

			printf("count -> [%d]\n", count);
		}

		/*
		* loop through the resultset one by one through
		* OCIStmtFetch()
		*/




		/*
		* untill we find nothing
		*/
		while (1)
		{
			status = OCIStmtFetch(stmhp, errhp,
				rows, OCI_FETCH_NEXT, OCI_DEFAULT);
			if (status == OCI_NO_DATA)
			{
				/*
				* indicates couldn't fetch anything
				*/
				break;
			}
			else
			{
				HANDLE_ERROR(errhp, status);
			}

			/*
			* print string
			*/
			if (null_ind_ename == -1)
				printf("name -> [NULL]\t");
			else
				printf("name -> [%s]\t", ename_buffer);

			/*
			* print number by converting it into int
			*/
			if (null_ind_mgr == -1)
				printf("mgr -> [NULL]\n");
			else
			{
				printf("mgr -> [%d]\n", mgr_buffer);
			}

			/*
			* print date after converting to text
			*/
			if (null_ind_hiredate == -1)
				printf("hiredate -> [NULL]\n");
			else
			{

				printf("hiredate -> [%s]\n", hire_date);
			}

			if (null_ind_photo == -1)
				printf("photo -> [NULL]\n");
			else
			{
				//photo_status = OCIRawAssignBytes(envhp, errhp, photo, 8000, &photo_raw);
				//OCIRawSize(envhp, photo_raw);


				//printf("photo_raw -> [%d]\n", *myphotolength);
				printf ("photo -> [%s]\n", photo );
				printf("photo -> [%c]\n", photo[323288]);
			}
		}
	}
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));

	delete photo;

}

/* select and print data by iterating through resultSet */
void select_print_data2(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{

	/* Statement */
	OCIStmt *stmhp;

	/* Define */
	OCIDefine *define;

	/* Buffer for employee Name */
	char ename_buffer[10];

	/* Buffer for mgr */
	sword mgr_buffer;

	/*Buffer for hiredate */
	char hire_date[19];

	/*Buffer for photo */
	sword photo_status;
	//ub1 photo[400000];
	char* photo = new char[400000];
	OCIRaw*photo_raw = (OCIRaw *)1;
	ub2 *myphotolength;

	//printf("photo -> [%c]\n", photo[323286]);
	//printf("photo -> [%c]\n", photo[323287]);
	//printf("photo -> [%c]\n", photo[323288]);

	/*
	* a simple select statement
	*/
	text * sql_statement = (text *) "select ename,mgr,hiredate,photo from ocispec where ename = 'SMITH_'";
	//(text *) "select ename,mgr,hiredate,photo from ocispec where ename = :ENAME";
	//(text *) "select grid from on_line.antenna_gain where id = '{011D4E0A-1943-4549-A961-86FC1E317074}'";


	//**********************************************************************************
	//**********************************************************************************
	//**********************************************************************************

	/*
	* additional local variables
	*/

	ub4 rows = 1;
	ub4 fetched = 1;
	ub4 status = OCI_SUCCESS;

	sb2 null_ind_ename = 0;

	/* null indicator for ename */
	sb2 null_ind_mgr = 0;

	/* null indicator for mgr */
	sb2 null_ind_hiredate = 0;

	/* null indicator for mgr */
	sb2 null_ind_photo = 0;

	/* null indicator for hiredate */

	/*
	* Now we are going to start the Milestone of a Simple Query of the
	* database and loop through the resultSet This would include
	* following steps
	*
	* 1. Initialize and Allocate the Statement Handle 2. Prepare the
	* Statement 3. Define Output variables to recieve the output of the
	* select statement 4. Execute the statement 5. Fetch the resultset
	* and Print values
	*
	*/
	memset(ename_buffer, 0, sizeof(ename_buffer));
	memset(hire_date, 0, sizeof(hire_date));
	memset(photo, 0, sizeof(photo));

	//printf("photo -> [323286 = %c]\n", photo[323286]);
	//printf("photo -> [323286 = %d]\n", photo[323286]);
	//printf("photo -> [323287 = %c]\n", photo[323287]);
	//printf("photo -> [323287 = %d]\n", photo[323287]);
	//printf("photo -> [323288 = %c]\n", photo[323288]);
	//printf("photo -> [323288 = %d]\n", photo[323288]);

	/*
	* Initialize & Allocate Statement Handle
	*/

	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));


	/*
	* Prepare the statement
	*/

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp,
			sql_statement,
			strlen((const char *)sql_statement),
			OCI_NTV_SYNTAX, OCI_DEFAULT));


	/*
	* Bind a String (OCIString) variable on position 1. Datatype used
	* SQLT_VST
	*/
	//HANDLE_ERROR(errhp,
	//	OCIDefineByPos(stmhp, &define, errhp,
	//		(ub4)1, ename_buffer, 10,
	//		(ub2)SQLT_STR, &null_ind_ename, 0, 0,
	//		OCI_DEFAULT));

	///*
	//* Bind a Number (OCINumber) variable on position 2. Datatype used
	//* SQLT_VNU
	//*/
	//HANDLE_ERROR(errhp,
	//	OCIDefineByPos(stmhp, &define, errhp,
	//		(ub4)2, &mgr_buffer, sizeof(sword),
	//		(ub2)SQLT_INT, &null_ind_mgr, 0, 0,
	//		OCI_DEFAULT));

	///*
	//* Bind a Date (OCIDate) variable on position 3. Datatype used
	//* SQLT_ODT
	//*/
	//HANDLE_ERROR(errhp,
	//	OCIDefineByPos(stmhp, &define, errhp,
	//		(ub4)3, hire_date, 19,
	//		(ub2)SQLT_STR, &null_ind_hiredate, 0, 0,
	//		OCI_DEFAULT));

	///*
	//* Bind a RAW (OCIRaw) variable on position 4. Datatype used
	//* SQLT_BIN
	//*/
	//HANDLE_ERROR(errhp,
	//	OCIDefineByPos(stmhp, &define, errhp,
	//		(ub4)4, photo, 400000,
	//		(ub2)SQLT_BIN, &null_ind_photo, myphotolength, 0,
	//		OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIDefineByPos(stmhp, &define, errhp,
			(ub4)1, photo, 400000,
			(ub2)SQLT_BIN, &null_ind_photo, myphotolength, 0,
			OCI_DEFAULT));

	/*
	* Execute the simple SQL Statement
	*/

	//TODAY
	//OCIBind *bnd1p = (OCIBind *)0;	/* the first bind handle   */
	//char *ename[3] = { "SMITH", "ALLEN", "KING" };

	//HANDLE_ERROR(errhp, OCIBindByName(stmhp, &bnd1p, errhp, (text *) ":ENAME",
	//	-1, (dvoid *)ename[1],
	//	(sb4)strlen(ename[1]) + 1, SQLT_STR,
	//	(dvoid *)0, 0, (ub2 *)0, (ub4)0,
	//	(ub4 *)0, OCI_DEFAULT));
	//END TODAY

	status = OCIStmtExecute(svchp, stmhp, errhp,
		rows, (ub4)0, NULL, NULL, OCI_DEFAULT);

	//TODAY
	//	ub4 col_count = 0;
	//
	//	HANDLE_ERROR(errhp, OCIAttrGet(stmhp, OCI_HTYPE_STMT, &col_count, 0, OCI_ATTR_PARAM_COUNT, errhp));
	//
	//
	//	for (int pos = 1; pos <= col_count; pos++)
	//	{
	//		OCIParam * ptr = 0;
	//		HANDLE_ERROR(errhp, OCIParamGet(stmhp, OCI_HTYPE_STMT, errhp, (void**)&ptr, pos));
	//
	//		void * descriptorp;
	//		if (ptr == 0)
	//		{
	//			if (OCIDescriptorAlloc(envhp, &descriptorp, OCI_DTYPE_PARAM, 0, 0) != OCI_SUCCESS)
	//				descriptorp = 0;
	//		}
	//		else
	//		{
	//			descriptorp = ptr;
	//		}
	//
	//		ub4 len;
	//		char * name;
	//
	//		HANDLE_ERROR(errhp, OCIAttrGet(descriptorp, OCI_DTYPE_PARAM, &name, &len, OCI_ATTR_NAME, errhp));
	//		char * str;
	//		unsigned long* _data = reinterpret_cast<unsigned long*>(new char[sizeof(unsigned long) + len + 1]);
	//		*_data = 1;
	//		str = reinterpret_cast<char*>(_data + 1);
	//
	//
	//#pragma warning(disable: 4996)
	//		strncpy(str, name, len);
	//		str[len] = 0;
	//#pragma warning(default: 4996) // Restore warnings
	//
	//		ub2 datatype;
	//		HANDLE_ERROR(errhp, OCIAttrGet(descriptorp, OCI_DTYPE_PARAM, &datatype, 0, OCI_ATTR_DATA_TYPE, errhp));
	//
	//		ub4 size; //size of the data
	//		switch (datatype)
	//		{
	//			case SQLT_INT:
	//				break;
	//			case SQLT_UIN:
	//				break;
	//			case SQLT_NUM:
	//			case SQLT_FLT:
	//				break;
	//			case SQLT_DAT:	// DATE
	//				break;
	//			case SQLT_BIN: // RAW
	//				HANDLE_ERROR(errhp, OCIAttrGet(descriptorp, OCI_DTYPE_PARAM, &size, 0, OCI_ATTR_DATA_SIZE, errhp));
	//				break;
	//			case SQLT_BLOB:
	//				size = sizeof(OCILobLocator*);
	//				break;
	//			case SQLT_BFILE:
	//				size = sizeof(OCILobLocator*);
	//				break;
	//			case SQLT_CLOB:
	//				size = sizeof(OCILobLocator*);
	//				break;
	//			case SQLT_CHR: // VARCHAR2
	//			case SQLT_AFC: // CHAR
	//			case SQLT_RID: // ROWID
	//			default:
	//				break;
	//		}
	//	}
	//
	//END TODAY
	/*
	* Print the Resultset
	*/
	if (status == OCI_NO_DATA)
	{
		/*
		* indicates didn't fetch anything (as we're not array
		* fetching)
		*/
		fetched = 0;
	}
	else
	{
		HANDLE_ERROR(errhp, status);
	}

	if (fetched)
	{
		/*
		* print string
		*/
		if (null_ind_ename == -1)
			printf("name -> [NULL]\t");
		else
			printf("name -> [%s]\t", ename_buffer);


		/*
		* print number by converting it into int
		*/
		if (null_ind_mgr == -1)
			printf("mgr -> [NULL]\n");
		else
		{
			printf("mgr -> [%d]\n", mgr_buffer);
		}

		if (null_ind_hiredate == -1)
			printf("hiredate -> [NULL]\n");
		else
		{
			printf("hiredate -> [%s]\n", hire_date);
		}

		if (null_ind_photo == -1)
			printf("photo -> [NULL]\n");
		else
		{
			//photo_status = OCIRawAssignBytes(envhp, errhp, photo, 8000, &photo_raw);
			//OCIRawSize(envhp, photo_raw);
			//printf("photo_raw -> [%d]\n", *myphotolength); //CRASH HERE
			//printf ("photo -> [%s]\n", photo );
			printf("photo -> [%s]\n", photo);
			printf("photo -> [323286 = %c]\n", photo[323286]);
			printf("photo -> [323286 = %d]\n", photo[323286]);
			printf("photo -> [323287 = %c]\n", photo[323287]);
			printf("photo -> [323287 = %d]\n", photo[323287]);
			printf("photo -> [323288 = %c]\n", photo[323288]);
			printf("photo -> [323288 = %d]\n", photo[323288]);

			int count = 0;
			for (int i = 0; i < 400000; i++)
			{
				if ((int)photo[i] < 0)
				{
					//printf("photo -> [%d = %d - char %c]\n", i, photo[i], photo[i]);
					count++;
				}

				if ((int)photo[i] > 127)
				{
					//printf("photo -> [%d = %d - char %c]\n", i, photo[i], photo[i]);
					count++;
				}
			}

			printf("count -> [%d]\n", count);
		}

		/*
		* loop through the resultset one by one through
		* OCIStmtFetch()
		*/




		/*
		* untill we find nothing
		*/
		while (1)
		{
			status = OCIStmtFetch(stmhp, errhp,
				rows, OCI_FETCH_NEXT, OCI_DEFAULT);
			if (status == OCI_NO_DATA)
			{
				/*
				* indicates couldn't fetch anything
				*/
				break;
			}
			else
			{
				HANDLE_ERROR(errhp, status);
			}

			/*
			* print string
			*/
			if (null_ind_ename == -1)
				printf("name -> [NULL]\t");
			else
				printf("name -> [%s]\t", ename_buffer);

			/*
			* print number by converting it into int
			*/
			if (null_ind_mgr == -1)
				printf("mgr -> [NULL]\n");
			else
			{
				printf("mgr -> [%d]\n", mgr_buffer);
			}

			/*
			* print date after converting to text
			*/
			if (null_ind_hiredate == -1)
				printf("hiredate -> [NULL]\n");
			else
			{

				printf("hiredate -> [%s]\n", hire_date);
			}

			if (null_ind_photo == -1)
				printf("photo -> [NULL]\n");
			else
			{
				//photo_status = OCIRawAssignBytes(envhp, errhp, photo, 8000, &photo_raw);
				//OCIRawSize(envhp, photo_raw);


				//printf("photo_raw -> [%d]\n", *myphotolength);
				printf("photo -> [%s]\n", photo);
				printf("photo -> [%c]\n", photo[323288]);
			}
		}
	}
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));

	delete photo;

}

void call_stored_proc1(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *p_sql;
	OCIBind *p_Bind1 = (OCIBind *)0;
	OCIBind *p_Bind2 = (OCIBind *)0;

	char field2[20];


	/*
	* char field3[20];
	*/
	sword field1 = 3;
	text *mySql = (text *) "Begin StoredProcedureSample1(:MGR, :ENAME); END";

	memset(field2, 0, sizeof(field2));
	strcpy(field2, "Entry 3");

	printf("*************************************************\n");
	printf("Example 1 - Using an IN OUT Parameter\n");
	printf("*************************************************\n");


	/*
	* Initialize & Allocate Statement Handle
	*/

	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& p_sql,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(p_sql, errhp, mySql,
			(ub4)strlen((char *)mySql), OCI_NTV_SYNTAX,
			OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIBindByPos(p_sql, &p_Bind1, errhp, 1,
			(dvoid *)& field1, sizeof(sword),
			SQLT_INT, 0, 0, 0, 0, 0, OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIBindByPos(p_sql, &p_Bind2, errhp, 2,
			field2, (sizeof(field2)),
			SQLT_STR, 0, 0, 0, 0, 0, OCI_DEFAULT));

	printf(" Field2 Before:\n");
	printf(" size ---> %d\n", sizeof(field2));
	printf(" length ---> %d\n", strlen(field2));
	printf(" value ---> %s\n", field2);

	HANDLE_ERROR(errhp,
		OCIStmtExecute(svchp, p_sql, errhp, (ub4)1, (ub4)0,
			(OCISnapshot *)NULL, (OCISnapshot *)NULL,
			(ub4)OCI_COMMIT_ON_SUCCESS));

	printf(" Field2 After:\n");
	printf(" size ---> %d\n", sizeof(field2));
	printf(" length ---> %d\n", strlen(field2));
	printf(" value ---> %s\n", field2);

	HANDLE_ERROR(errhp, OCIHandleFree(p_sql, OCI_HTYPE_STMT));
}

void call_stored_proc2(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *p_sql;
	OCIBind *p_Bind1 = (OCIBind *)0;
	OCIBind *p_Bind2 = (OCIBind *)0;
	OCIBind *p_Bind3 = (OCIBind *)0;

	char field2[20] = "Entry 3";
	char field3[20];
	sword field1 = 3;
	text *mySql =
		(text *) "Begin StoredProcedureSample2(:MGR, :ENAME, :EOUT); END";


	memset(field2, 0, sizeof(field2));
	strcpy(field2, "Entry 3");

	memset(field3, 0, sizeof(field3));


	printf("*************************************************\n");
	printf("Example 2 - Using an OUT Parameter\n");
	printf("*************************************************\n");

	/*
	* Initialize & Allocate Statement Handle
	*/

	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& p_sql,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(p_sql, errhp, mySql,
			(ub4)strlen((char *)mySql), OCI_NTV_SYNTAX,
			OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIBindByPos(p_sql, &p_Bind1, errhp, 1,
			(dvoid *)& field1, sizeof(sword),
			SQLT_INT, 0, 0, 0, 0, 0, OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIBindByPos(p_sql, &p_Bind2, errhp, 2,
			field2, strlen(field2) + 1,
			SQLT_STR, 0, 0, 0, 0, 0, OCI_DEFAULT));

	HANDLE_ERROR(errhp,
		OCIBindByPos(p_sql, &p_Bind3, errhp, 3,
			field3, 20,
			SQLT_STR, 0, 0, 0, 0, 0, OCI_DEFAULT));

	printf(" Field3 Before:\n");
	printf(" size ---> %d\n", sizeof(field3));
	printf(" length ---> %d\n", strlen(field3));
	printf(" value ---> %s\n", field3);

	HANDLE_ERROR(errhp,
		OCIStmtExecute(svchp, p_sql, errhp, (ub4)1, (ub4)0,
			(OCISnapshot *)NULL, (OCISnapshot *)NULL,
			(ub4)OCI_COMMIT_ON_SUCCESS));


	printf(" Field3 After:\n");
	printf(" size ---> %d\n", sizeof(field3));
	printf(" length ---> %d\n", strlen(field3));
	printf(" value ---> %s\n", field3);

	HANDLE_ERROR(errhp, OCIHandleFree(p_sql, OCI_HTYPE_STMT));
}

/* drop table(s) required for this example */
void drop_table(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *stmhp;
	text *statement = (text *)"DROP TABLE OCISPEC";
	ub4 status = OCI_SUCCESS;

	/*
	* Initialize & Allocate Statement Handle
	*/
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	/*
	* Prepare the drop statement
	*/
	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp,
			statement, strlen((const char *)statement),
			OCI_NTV_SYNTAX, OCI_DEFAULT));

	/*
	* Execute the drop Statement
	*/
	if ((status = OCIStmtExecute(svchp, stmhp, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN DROPING TABLE(S)\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Table(s) Successfully Dropped\n");
		printf("********************************************\n");
	}
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));
}

void drop_stored_procs(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	OCIStmt *stmhp;
	OCIStmt *stmhp2;
	OCIStmt *stmhp3;

	text *create_statement = (text *)"DROP PROCEDURE StoredProcedureSample1";
	text *create_statement2 = (text *)"DROP PROCEDURE StoredProcedureSample2";
	text *create_statement3 = (text *)"DROP FUNCTION  f1";


	ub4 status = OCI_SUCCESS;
	OCITransCommit(svchp, errhp, OCI_DEFAULT);
	/*
	* Initialize & Allocate Statement Handles
	*/
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp2,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));
	HANDLE_ERROR(errhp,
		OCIHandleAlloc(envhp, (dvoid **)& stmhp3,
			OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	/*
	* Prepare the Create statements
	*/

	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp, errhp,
			create_statement,
			strlen((const char *)create_statement),
			OCI_NTV_SYNTAX, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp2, errhp, create_statement2,
			strlen((const char *)create_statement2),
			OCI_NTV_SYNTAX, OCI_DEFAULT));
	HANDLE_ERROR(errhp,
		OCIStmtPrepare(stmhp3, errhp, create_statement3,
			strlen((const char *)create_statement3),
			OCI_NTV_SYNTAX, OCI_DEFAULT));

	/*
	* Execute the Create Statement SampleProcedure1
	*/
	if ((status = OCIStmtExecute(svchp, stmhp, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN DROPPING PROCEDURE 1\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Sample Procedure 1 Successfully dropped\n");
		printf("********************************************\n");
	}

	/*
	* Execute the Create Statement Sample Procedure2
	*/
	if ((status = OCIStmtExecute(svchp, stmhp2, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN DROPPING PROCEDURE 2\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Sample Procedure 2 Successfully dropped\n");
		printf("********************************************\n");
	}

	/*
	* Execute the Create Statement Sample Procedure3
	*/
	if ((status = OCIStmtExecute(svchp, stmhp3, errhp,
		(ub4)1, (ub4)0, NULL, NULL, OCI_DEFAULT)) < OCI_SUCCESS)
	{
		printf("FAILURE IN DROPPING PROCEDURE 3\n");
		HANDLE_ERROR(errhp, status);
		return;
	}
	else
	{
		printf("********************************************\n");
		printf("MileStone : Sample Procedure 3 Successfully dropped\n");
		printf("********************************************\n");
	}


	HANDLE_ERROR(errhp, OCIHandleFree(stmhp, OCI_HTYPE_STMT));
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp2, OCI_HTYPE_STMT));
	HANDLE_ERROR(errhp, OCIHandleFree(stmhp3, OCI_HTYPE_STMT));

}

/* Clean your mess up */
void cleanup(OCISvcCtx ** svchp, OCIServer ** srvhp, OCISession ** authp,
	OCIError ** errhp, OCIEnv ** envhp)
{
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

void ReadBlob(OCISvcCtx * svchp, OCIError * errhp, OCIEnv * envhp)
{
	sword          retValue;
	OCIStmt		  *stmthp;
	int			   status;
	OCILobLocator *locator;

	//retValue = OCIInitialize((ub4)OCI_DEFAULT, (dvoid *)0, (dvoid * (*)(dvoid *, size_t)) 0, (dvoid * (*)(dvoid *, dvoid *, size_t))0, (void(*)(dvoid *, dvoid *)) 0);
	//retValue = OCIEnvInit((OCIEnv **)&envhp, OCI_DEFAULT, (size_t)0, (dvoid **)0);
	//retValue = OCIHandleAlloc((dvoid *)envhp, (dvoid **)&errhp, OCI_HTYPE_ERROR, (size_t)0, (dvoid **)0);

	/* server contexts  */
	/*OCI server handle*/
	//retValue = OCIHandleAlloc((dvoid *)envhp, (dvoid **)&srvhp, OCI_HTYPE_SERVER, (size_t)0, (dvoid **)0);
	//retValue = OCIHandleAlloc((dvoid *)envhp, (dvoid **)&svchp, OCI_HTYPE_SVCCTX, (size_t)0, (dvoid **)0);
	//retValue = OCIServerAttach(srvhp, errhp, (text *)attach_string, strlen((char *)attach_string), 0);

	/* set attribute server context in the service context*/
	//retValue = OCIAttrSet((dvoid *)svchp, OCI_HTYPE_SVCCTX, (dvoid *)srvhp, (ub4)0, OCI_ATTR_SERVER, (OCIError *)errhp);
	//retValue = OCIHandleAlloc((dvoid *)envhp, (dvoid **)&authp, (ub4)OCI_HTYPE_SESSION, (size_t)0, (dvoid **)0);
	//retValue = OCIAttrSet((dvoid *)authp, (ub4)OCI_HTYPE_SESSION, (dvoid *)username, (ub4)strlen((char *)username), (ub4)OCI_ATTR_USERNAME, errhp);
	//retValue = OCIAttrSet((dvoid *)authp, (ub4)OCI_HTYPE_SESSION, (dvoid *)password, (ub4)strlen((char *)password), (ub4)OCI_ATTR_PASSWORD, errhp);
	//retValue = OCISessionBegin(svchp, errhp, authp, OCI_CRED_RDBMS, (ub4)OCI_DEFAULT);

	//OCIAttrSet((dvoid *)svchp, (ub4)OCI_HTYPE_SVCCTX, (dvoid *)authp, (ub4)0, (ub4)OCI_ATTR_SESSION, errhp);

	//checkerr(errhp, OCIHandleAlloc((dvoid *)envhp, (dvoid **)&stmthp, OCI_HTYPE_STMT, (size_t)0, (dvoid **)0));

	{
		unsigned char  lob_buffer[1000] = { 0 };  ///hardcoded : 3470 is the actual size of the image 1
		ub4	  amount = 4096;
		ub4   lob_size = 0;
		char *append_buffer = "Our deepest fear is not that we are inadequate...";

		blob_locate("blob_test", "image_data", "image_name", "image 1", envhp, errhp, &locator, svchp);

		if ((status = OCILobGetLength(svchp, errhp, locator, &lob_size)) != OCI_SUCCESS)
			check_oci_error(errhp, status);

		const int size = lob_size;

		if ((status = OCILobRead(svchp, errhp, locator, &lob_size, 1 , lob_buffer, sizeof(lob_buffer), 0, 0, 0, SQLCS_IMPLICIT)) != OCI_SUCCESS)

		//if ((status = OCILobRead(svchp, errhp, locator, &amount, 42 /* offset */, lob_buffer, sizeof(lob_buffer), "Hi mom!", read_callback, 0, SQLCS_IMPLICIT)) != OCI_SUCCESS)
		//if ((status = OCILobRead(svchp, errhp, locator, &lob_size, 1 , lob_buffer, sizeof(lob_buffer), 0, 0, 0, SQLCS_IMPLICIT)) != OCI_SUCCESS)
			check_oci_error(errhp, status);

		printf("%*.*s\n", 100, 100, lob_buffer);

		//if ((status = OCILobGetLength(svchp, errhp, locator, &lob_size)) != OCI_SUCCESS)
		//	check_oci_error(errhp, status);

		printf("blob is %d bytes long\n", lob_size);

		amount = strlen(append_buffer);;

		if ((status = OCILobWriteAppend(svchp, errhp, locator, (ub4 *)&amount, append_buffer, amount, OCI_ONE_PIECE, NULL, NULL, 0, SQLCS_IMPLICIT)) != OCI_SUCCESS)
			check_oci_error(errhp, status);

		OCITransCommit(svchp, errhp, OCI_DEFAULT);

		if ((status = OCILobTrim(svchp, errhp, locator, lob_size)) != OCI_SUCCESS)
			check_oci_error(errhp, status);

		OCITransCommit(svchp, errhp, OCI_DEFAULT);
	}
}

///////////////////////////
//////////////////////////
//////////////////////////
