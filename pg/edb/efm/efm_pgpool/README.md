Test case for EFM/pgpool investigation (2018-10-15).  To run this, do the following:

* `docker-compose build`
    * You may need to build the `epas10:latest` image first (see [ppas_and_docker](https://github.com/richyen/ppas_and_docker/blob/master/epas/10/Dockerfile))
* `docker-compose up`
* `./post_compose.sh`
* `docker exec -it witness /usr/edb/efm-3.2/bin/efm cluster-status efm`
* `docker exec -it witness psql -p9999 -c "show pool_nodes"`
* `docker exec -it witness /usr/edb/efm-3.2/bin/efm promote edb`

Further attempts to `docker exec -it witness psql -p9999 -c "show pool_nodes"` will hang.  Looking in the `witness` container reveals that `pgpool` procs are Zombied
