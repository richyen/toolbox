#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>

#ifndef OCI_ORACLE
#include <oci.h>
#include <edboci.h>
#endif
static OCIEnv       *env;

void checkerr(OCIError *errhp, sword retCode)
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
        OCIErrorGet(errhp, 1, NULL, &errCode, (OraText *)szBuf, 512, OCI_HTYPE_ERROR);
        printf("OCI_SUCCESS_WITH_INFO : %05d\n", (int) errCode);
        printf("OCI_SUCCESS_WITH_INFO : %s\n", szBuf);
      }
      break;

    case OCI_RESERVED_FOR_INT_USE:
      printf("OCI_RESERVED_FOR_INT_USE\n");
      break;

    case OCI_NO_DATA:
      printf("OCI_NO_DATA\n");
      break;

    case OCI_ERROR:
      {
        extern sword OCIPGErrorGet(dvoid *hndlp, ub4 recordno, OraText *errcodep,ub4 errbufsiz, OraText *bufp, ub4 bufsiz, ub4 type);

        OCIErrorGet(errhp, 1, NULL, &errCode, (OraText *)szBuf, 512, OCI_HTYPE_ERROR);
        printf("OCI_ERROR   : %05d\n", (int) errCode);
        printf("OCI_ERROR   : %s\n", szBuf);
#ifdef PG
        {
          OraText sqlstate[5+1];
          OraText pgtext[1024];

          OCIPGErrorGet(errhp, 1, sqlstate, sizeof(sqlstate), pgtext, sizeof(pgtext), OCI_HTYPE_ERROR);
          printf("PG SQLSTATE : %s\n", sqlstate);
          printf("PG TEXT     : %s\n", pgtext);
        }
#endif

      }
      break;

    case OCI_INVALID_HANDLE:
      printf("OCI_INVALID_HANDLE\n");
      break;

    case OCI_NEED_DATA:
      printf("OCI_NEED_DATA\n");
      break;

    case OCI_STILL_EXECUTING:
      printf("OCI_STILL_EXECUTING\n");
      break;
  }
}

  static sword
newConnection(OCIError ** err, OCISvcCtx **svc)
{
  ub4		   version;
  OraText    releaseString[1024];
  char	  *username = getenv("oci_user");
  char	  *password = getenv("oci_pass");
  char	  *dbname   = getenv("oci_db");
  sword	   major, minor, update, patch, port;

  OCIHandleAlloc((dvoid *)env, (dvoid **)err, OCI_HTYPE_ERROR, 0, 0);

  checkerr(*err, OCILogon(env, *err, svc, (text *) username, strlen(username), (text *) password, strlen(password), (text *) dbname, strlen(dbname)));
  OCIServerRelease(*svc, *err, releaseString, sizeof(releaseString), OCI_HTYPE_SVCCTX, &version);

  printf("%s\n", releaseString);

  OCIClientVersion(&major, &minor, &update, &patch, &port);

  printf("Client version: major(%d) minor(%d) update(%d) patch(%d) port(%d)\n", major, minor, update, patch, port);

  return OCI_SUCCESS;
}

void dumpNRows( OCIEnv *env, OCISvcCtx *svc, OCIError *error_handle, const char *sql, int rowCount)
{
  OCIStmt	  *stmt;
  char	   name[10][80];
  char	   text[10][200+1];
  sb2		   nameInd[10], textInd[10];
  OCIDefine *defnp;

  checkerr(error_handle, OCIHandleAlloc( env, (dvoid **)&stmt, OCI_HTYPE_STMT, 0, (0)));
  checkerr(error_handle, OCIStmtPrepare( stmt, error_handle, (OraText *) sql, strlen( sql ), OCI_NTV_SYNTAX, 0 ));
  checkerr(error_handle, OCIDefineByPos( stmt, &defnp, error_handle, 1, name, sizeof(name[0]), SQLT_STR, nameInd, (0), (0), 0));
  checkerr(error_handle, OCIDefineByPos( stmt, &defnp, error_handle, 2, text, sizeof(text[0]), SQLT_STR, textInd, (0), (0), 0));
  checkerr(error_handle, OCIStmtExecute( svc, stmt, error_handle, 0, 0, (0), (0), 0 ));

  while(OCIStmtFetch(stmt, error_handle, rowCount, OCI_FETCH_NEXT, OCI_DEFAULT) == OCI_SUCCESS)
  {
    int i;

    for (i = 0; i < rowCount; i++)
      fprintf(stderr, "%-30s : %s\n", nameInd[i] >= 0 ? name[i] : "<null>", textInd[i] >= 0 ? text[i] : "<null>");
  }

  checkerr(error_handle, OCIHandleFree( stmt, OCI_HTYPE_STMT ));
}

static OCILobLocator *getLocator(OCIError *err, OCISvcCtx *svc, OCIEnv *env, int pkey)
{
  const char	  *query = "SELECT lob_binary FROM binary_table WHERE pkey = :pkey";
  OCILobLocator *result;
  OCIStmt		  *stmt;
  OCIBind		  *bind;
  OCIDefine	  *define;

  checkerr(err, OCIHandleAlloc( env, (dvoid **)&stmt, OCI_HTYPE_STMT, 0, (0)));
  checkerr(err, OCIStmtPrepare(stmt, err, (const OraText *) query, strlen(query), OCI_NTV_SYNTAX, 0));
  checkerr(err, OCIBindByName(stmt, &bind, err, (OraText *) ":pkey", strlen(":pkey"), &pkey, sizeof(pkey), SQLT_INT, NULL, NULL, NULL, 0, 0, OCI_DEFAULT));

  checkerr(err, OCIDescriptorAlloc(env, (void **) &result, OCI_DTYPE_LOB, 0, NULL));
  checkerr(err, OCIDefineByPos(stmt, &define, err, 1, &result, sizeof(result), SQLT_BLOB, 0, 0, 0, OCI_DEFAULT));

  checkerr(err, OCIStmtExecute(svc, stmt, err, 1, 0, 0, 0, 0));

  checkerr(err, OCIHandleFree( stmt, OCI_HTYPE_STMT ));

  return result;
}

static sb4 readCallback(void *context, const void *buffer, ub4 len, ub1 piece)
{
  switch (piece)
  {
    case OCI_FIRST_PIECE:  printf("callback - len = %d, piece = OCI_FIRST_PIECE\n", len); break;
    case OCI_NEXT_PIECE:   printf("callback - len = %d, piece = OCI_NEXT_PIECE\n", len); break;
    case OCI_LAST_PIECE:   printf("callback - len = %d, piece = OCI_LAST_PIECE\n", len); break;
    default:               printf("callback - len = %d, UNEXPECTED piece = %d\n", len, piece); break;
  }

  return OCI_CONTINUE;
}

static void readLob(OCIError *err, OCISvcCtx *svc, OCILobLocator *locator)
{
  ub4		length, bytes;
  void   *buffer;
  FILE   *out;

  checkerr(err, OCILobGetLength(svc, err, locator, &length));

  printf("length: %d\n", length);

  buffer = malloc(length);

  bytes = length;

  checkerr(err, OCILobRead(svc, err, locator, &bytes, 0, buffer, length, NULL, readCallback, 0, SQLCS_IMPLICIT));

  /*
   * Write the data out to /tmp/out.oci so we can verify that we read what
   * we think we should have
   */
  if ((out = fopen("/tmp/out.oci", "wb")) != NULL)
  {
    fwrite(buffer, bytes, 1, out);
    fclose(out);
  }
}

static void writeLob(OCIError *err, OCISvcCtx *svc, OCILobLocator *locator, const char *fname)
{
  struct stat stats;

  if (stat(fname, &stats) != 0)
  {
    fprintf(stderr, "can't stat %s\n", fname);
    exit(1);
  }
  else
  {
    FILE *in = fopen(fname, "rb");
    ub4	  amount = stats.st_size;
    void *buf = malloc(amount);

    if (in && buf)
    {
      fread(buf,  stats.st_size, 1, in);

      checkerr(err, OCILobTrim(svc, err, locator, 0));
      checkerr(err, OCILobWriteAppend(svc, err, locator, &amount, buf, amount, OCI_ONE_PIECE, NULL, NULL, 0, SQLCS_IMPLICIT));

      fclose(in);
      free(buf);
    }
  }
}

int main(int argc, char *argv[])
{
  OCIError  *err;
  OCISvcCtx *svc;
  ub1		   emptystringmode = EDB_EMPTY_STRINGS_EMPTY;
  OCILobLocator *locator;

  printf("Running - process %d\n\n", getpid());

  OCIEnvInit((OCIEnv **)&env, OCI_DEFAULT, 0, 0);

  newConnection(&err, &svc);

  checkerr(err, OCIAttrSet(env, OCI_HTYPE_ENV, &emptystringmode, 0, EDB_ATTR_EMPTY_STRINGS, err));

  locator = getLocator(err, svc, env, atoi(argv[1]));

  writeLob(err, svc, locator, argv[2]);

  readLob(err, svc, locator);

  return 0;
}
