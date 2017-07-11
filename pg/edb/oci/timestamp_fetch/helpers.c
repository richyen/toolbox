OCIEnv	 *env;
OCIError *err;
OCISvcCtx *svc;


/******************************************************************************
 *                              Error Handling
 ******************************************************************************/
static void check_oci_err(OCIError *err, sword retCode)
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
				status = OCIErrorGet(err, recordno++, NULL, &errCode, (OraText *)szBuf, 512, OCI_HTYPE_ERROR);
				while(status != OCI_NO_DATA)
				{
					printf("OCI_ERROR : %s\n", szBuf);

					memset(szBuf, 0, 512);
					status = OCIErrorGet(err, recordno++, NULL, &errCode, (OraText *)szBuf, 512, OCI_HTYPE_ERROR);
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
				status = OCIErrorGet(err, recordno++, NULL, &errCode, (OraText *)szBuf, 512, OCI_HTYPE_ERROR);
				while(status != OCI_NO_DATA)
				{
					printf("OCI_ERROR : %s\n", szBuf);

					memset(szBuf, 0, 512);
					status = OCIErrorGet(err, recordno++, NULL, &errCode, (OraText *)szBuf, 512, OCI_HTYPE_ERROR);
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

static void logon(int argc, char *argv[])
{
	const char *username;
	const char *password;
	const char *server;

	if (argc == 4)
	{
		username = argv[1];
		password = argv[2];
		server   = argv[3];
	}
	else
	{
		fprintf(stderr, "usage: %s <username> <password> <server>\n", argv[0]);
		fprintf(stderr, "example:\n");
		fprintf(stderr, "%s enterprisedb mypassword //127.0.0.1:5444/edb\n");

		exit(1);
	}
	
    OCIEnvInit(&env, OCI_DEFAULT, 0, NULL);
    OCIHandleAlloc(env, (void **)&err, OCI_HTYPE_ERROR, 0, NULL);

    /* Logon to the server */
    check_oci_err(err, OCILogon2(env, err, &svc, (OraText *)username, strlen(username), (OraText *)password, strlen(password), (OraText *)server, strlen(server), OCI_LOGON2_STMTCACHE));
}
