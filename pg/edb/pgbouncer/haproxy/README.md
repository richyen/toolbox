# HAProxy with pgBouncer

Template configs for using HAProxy with pgBouncer

## What does HAProxy have to do with pgBouncer?

Several people have asked for a load-balancing solution for pgBouncer, and while no integrated solution exists, putting pgBouncer behind an HAProxy layer could create the desired behavior.

Adapted from Sushil Mohanty's [Random Database Thoughts](https://sushilmohanty.wordpress.com/2013/08/20/haproxy-scaling-postgres-read-only-database-replicas/)

## Basic steps to deploy:
1. Make sure pgBouncer is running on the desired server(s)
1. Install haproxy on proxy server
1. Configure `/etc/haproxy/haproxy.cfg` to use the pgBouncer instances
1. Put `pgsqlchk` in desired location (in the example, it's in `/opt`), and make it executable by all
1. Install `xinetd`
1. Create `/etc/xinetd.d/pgsqlchk` to allow use of `pgsqlchk` in `xinetd`
1. Start the `xinetd` service
1. Test
