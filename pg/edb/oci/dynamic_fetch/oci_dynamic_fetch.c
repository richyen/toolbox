#include <stdio.h>
#include <stdlib.h>
#include <oci.h>

#ifdef _WIN32
/* Modify the path to refer your OCILib */
#pragma comment( lib, "edboci.lib" )
#endif /* _WIN32 */

#define MAXCOLLEN   40

int empno           = 0;
ub4 empno_len       = 4;
sb2 empno_ind       = 0;
ub2 empno_rcode     = 0;

char ename[MAXCOLLEN+1];
ub4 ename_len       = 3;
sb2 ename_ind       = 0;
ub2 ename_rcode     = 0;

int age             = 0;
sb4 oci_get_number_define_data( dvoid *octxp, OCIDefine *defnp, ub4 iter,
                                dvoid **bufpp, ub4 **alenp, ub1 *piecep,
                                dvoid **indp, ub2 **rcodep );

sb4 oci_get_varchar2_define_data( dvoid *octxp, OCIDefine *defnp, ub4 iter,
                                  dvoid **bufpp, ub4 **alenp, ub1 *piecep,
                                  dvoid **indp, ub2 **rcodep );
void check_oci_env_err( OCIEnv *envp, sword retCode );
void check_oci_err( OCIError *errhp, sword retCode );

int main( int nargs, char *args[] )
{
    OCIEnv          *envp;
    OCIError        *errhp;
    OCISvcCtx       *svchp;
    OraText         *username = (OraText *) "enterprisedb";
    OraText         *password = (OraText *) "edb";
    OraText         *dbname = (OraText *) "//127.0.0.1:5444/edb";

    OCIStmt         *stmtp;
    char            *stmt = "SELECT * FROM EMP";
    OCIDefine       *defp;

    /*
     * Initialize the environment handle
     */

    OCIEnvInit( &envp, OCI_DEFAULT, 0, NULL );


    /*
     * Allocate necessary handles
     */

    OCIHandleAlloc( envp, &errhp, OCI_HTYPE_ERROR, 0, NULL );


    /*
     * Logon to the server
     */

    check_oci_err( errhp, OCILogon2( envp, errhp, &svchp, username,
                                     strlen(username), password,
                                     strlen(password), dbname,
                                     strlen(dbname), OCI_LOGON2_STMTCACHE ) );


    /*
     * Define dynamic example
     */

    OCIHandleAlloc( envp, &stmtp, OCI_HTYPE_STMT, 0, NULL );
    check_oci_err( errhp, OCIStmtPrepare( stmtp, errhp, stmt, strlen(stmt),
                                          OCI_NTV_SYNTAX, OCI_DEFAULT ) );

    check_oci_err( errhp, OCIDefineByPos( stmtp, &defp, errhp, 1, NULL, 4, SQLT_INT,
                                          NULL, NULL, NULL, OCI_DYNAMIC_FETCH ) );

    check_oci_err( errhp, OCIDefineDynamic( defp, errhp, NULL, oci_get_number_define_data ) );

    check_oci_err( errhp, OCIDefineByPos( stmtp, &defp, errhp, 2, NULL, 40, SQLT_STR,
                                          NULL, NULL, NULL, OCI_DYNAMIC_FETCH ) );

    check_oci_err( errhp, OCIDefineDynamic( defp, errhp, NULL, oci_get_varchar2_define_data ) );

    check_oci_err( errhp, OCIDefineByPos( stmtp, &defp, errhp, 3, (dvoid *) &age, (sword) sizeof(age), SQLT_INT, (dvoid *) 0, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT ) );

    check_oci_err( errhp, OCIStmtExecute( svchp, stmtp, errhp, 1, 0, NULL, NULL,
                                          OCI_DEFAULT ) );


    printf( "\n--------------------------------------------------\n" );
    printf( "empno          = %d\n", empno );
    printf( "empno_len      = %d\n", empno_len );
    printf( "empno_ind      = %d\n", empno_ind );
    printf( "empno_rcode    = %d\n", empno_rcode );

    printf( "\n--------------------------------------------------\n" );
    printf( "ename          = %s\n", ename );
    printf( "ename_len      = %d\n", ename_len );
    printf( "ename_ind      = %d\n", ename_ind );
    printf( "ename_rcode    = %d\n", ename_rcode );

    printf( "\n--------------------------------------------------\n" );
    printf( "age          = %d\n", age );


    check_oci_err( errhp, OCIStmtFetch( stmtp, errhp, 1, OCI_FETCH_NEXT, OCI_DEFAULT ) );


    printf( "\n--------------------------------------------------\n" );
    printf( "empno          = %d\n", empno );
    printf( "empno_len      = %d\n", empno_len );
    printf( "empno_ind      = %d\n", empno_ind );
    printf( "empno_rcode    = %d\n", empno_rcode );

    printf( "\n--------------------------------------------------\n" );
    printf( "ename          = %s\n", ename );
    printf( "ename_len      = %d\n", ename_len );
    printf( "ename_ind      = %d\n", ename_ind );
    printf( "ename_rcode    = %d\n", ename_rcode );

    printf( "\n--------------------------------------------------\n" );
    printf( "age          = %d\n", age );


    /*
     * Logoff from the server
     */

    check_oci_err( errhp, OCILogoff( svchp, errhp ) );


    /*
     * Free all handles
     */

    OCIHandleFree( errhp, OCI_HTYPE_ERROR );
    OCIHandleFree( envp, OCI_HTYPE_ENV );

    return 0;
}

/********************************************************************
 *
 *                  NUMBER Bind Callbacks
 *
 ********************************************************************/
sb4 oci_get_number_define_data( dvoid *octxp, OCIDefine *defnp, ub4 iter,
                                dvoid **bufpp, ub4 **alenp, ub1 *piecep,
                                dvoid **indp, ub2 **rcodep )
{
    printf( "\nNUMBER Define Callback\n" );
    printf( "-----------------------------------------------------\n\n" );

    printf( "iter       = %d\n", iter );
    printf( "piecep     = " );
    switch( (*piecep) )
    {
    case OCI_ONE_PIECE:     printf( "OCI_ONE_PIECE\n" );     break;
    case OCI_FIRST_PIECE:   printf( "OCI_FIRST_PIECE\n" );   break;
    case OCI_NEXT_PIECE:    printf( "OCI_NEXT_PIECE\n" );    break;
    case OCI_LAST_PIECE:    printf( "OCI_LAST_PIECE\n" );    break;
    }


    (*piecep)   = OCI_ONE_PIECE;
    (*bufpp)    = &empno;
    (*alenp)    = &empno_len;
    (*indp)     = &empno_ind;
    (*rcodep)   = &empno_rcode;

    return OCI_CONTINUE;
}

/********************************************************************
 *
 *                  VARCHAR2 Callbacks
 *
 ********************************************************************/
sb4 oci_get_varchar2_define_data( dvoid *octxp, OCIDefine *defnp, ub4 iter,
                                  dvoid **bufpp, ub4 **alenp, ub1 *piecep,
                                  dvoid **indp, ub2 **rcodep )
{
    printf( "\nVARCHAR2 Define Callback\n" );
    printf( "-----------------------------------------------------\n\n" );

    printf( "iter       = %d\n", iter );
    printf( "piecep     = " );
    switch( (*piecep) )
    {
    case OCI_ONE_PIECE:     printf( "OCI_ONE_PIECE\n" );     break;
    case OCI_FIRST_PIECE:   printf( "OCI_FIRST_PIECE\n" );   break;
    case OCI_NEXT_PIECE:    printf( "OCI_NEXT_PIECE\n" );    break;
    case OCI_LAST_PIECE:    printf( "OCI_LAST_PIECE\n" );    break;
    }


    if( (*piecep) == OCI_FIRST_PIECE )
    {
        (*piecep)   = OCI_FIRST_PIECE;

        ename_len   = 3;
        memset( ename, 0, sizeof(ename) );
        (*bufpp)    = ename;
        (*alenp)    = &ename_len;
        (*indp)     = &ename_ind;
        (*rcodep)   = &ename_rcode;
    }
    else
    {
        ename_len   = sizeof(ename) - 3;
        (*piecep)   = OCI_LAST_PIECE;
        (*bufpp)    = (char *)(ename + 3);
        (*alenp)    = &ename_len;
    }


    return OCI_CONTINUE;
}





/******************************************************************************
 *
 *                          Environment Error Handling
 *
 ******************************************************************************/
void check_oci_env_err( OCIEnv *envp, sword retCode )
{
    char    szBuf[512];
    sb4     errCode;


    switch( retCode )
    {
    case OCI_SUCCESS:
        break;

    case OCI_SUCCESS_WITH_INFO:
        {
            memset( szBuf, 0, 512 );
            OCIErrorGet( envp, 1, NULL, &errCode, szBuf, 512, OCI_HTYPE_ENV );
            printf( "OCI_SUCCESS_WITH_INFO : %s\n", szBuf );
        }
        break;

    case OCI_RESERVED_FOR_INT_USE:
        break;

    case OCI_NO_DATA:
            printf( "OCI_NO_DATA\n", szBuf );
        break;

    case OCI_ERROR:
        {
            memset( szBuf, 0, 512 );
            OCIErrorGet( envp, 1, NULL, &errCode, szBuf, 512, OCI_HTYPE_ENV );
            printf( "OCI_ERROR : %s\n", szBuf );
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
void check_oci_err( OCIError *errhp, sword retCode )
{
    char    szBuf[512];
    sb4     errCode;
    sword   status;
    ub4     recordno;


    switch( retCode )
    {
    case OCI_SUCCESS:
        break;

    case OCI_SUCCESS_WITH_INFO:
        {
            recordno = 1;

            memset( szBuf, 0, 512 );
            status = OCIErrorGet( errhp, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR );
            while( status != OCI_NO_DATA )
            {
                printf( "OCI_ERROR : %s\n", szBuf );

                memset( szBuf, 0, 512 );
                status = OCIErrorGet( errhp, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR );
            }
        }
        break;

    case OCI_RESERVED_FOR_INT_USE:
        break;

    case OCI_NO_DATA:
            printf( "OCI_NO_DATA\n", szBuf );
        break;

    case OCI_ERROR:
        {
            recordno = 1;

            memset( szBuf, 0, 512 );
            status = OCIErrorGet( errhp, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR );
            while( status != OCI_NO_DATA )
            {
                printf( "OCI_ERROR : %s\n", szBuf );

                memset( szBuf, 0, 512 );
                status = OCIErrorGet( errhp, recordno++, NULL, &errCode, szBuf, 512, OCI_HTYPE_ERROR );
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
