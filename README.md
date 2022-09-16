# HAProxy + MySQL Replication Cluster setup

## Deploy the instances

### Use the bash script
Sample terminal output:
```
$ ./setupenv.sh start
Creating network "haproxy-test_default" with the default driver
Creating mysql_replica3 ... done
Creating mysql_replica1 ... done
Creating mysql_replica2 ... done
Creating haproxy1       ... done
Creating mysql_source   ... done
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.
Execute docker-compose logs haproxy1 and check if the backends are up. Alternatively open your browser and browse to <IP>:80/haproxy/stats with user: mysqlstats and pwd: secret
```

### Check if all backends are `RUNNING`
Sample terminal output:
```
$ docker-compose logs -f haproxy1
Attaching to haproxy1
haproxy1    | [NOTICE]   (1) : New worker (8) forked
haproxy1    | [NOTICE]   (1) : Loading success.
haproxy1    | [WARNING]  (8) : Server mysqlro-back/mysql2 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 2 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
haproxy1    | [WARNING]  (8) : Server mysqlro-back/mysql3 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
haproxy1    | [WARNING]  (8) : Server mysqlro-back/mysql4 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 1ms. 0 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
haproxy1    | [ALERT]    (8) : backend 'mysqlro-back' has no server available!
haproxy1    | [WARNING]  (8) : Server mysqlrw-back/mysql1 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 0 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
haproxy1    | [ALERT]    (8) : backend 'mysqlrw-back' has no server available!
haproxy1    | [WARNING]  (8) : Server mysqlro-back/mysql4 is UP, reason: Layer7 check passed, code: 0, check duration: 1ms. 1 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
haproxy1    | [WARNING]  (8) : Server mysqlrw-back/mysql1 is UP, reason: Layer7 check passed, code: 0, check duration: 1ms. 1 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
haproxy1    | [WARNING]  (8) : Server mysqlro-back/mysql2 is UP, reason: Layer7 check passed, code: 0, check duration: 1ms. 2 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
haproxy1    | [WARNING]  (8) : Server mysqlro-back/mysql3 is UP, reason: Layer7 check passed, code: 0, check duration: 2ms. 3 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
```

### HAProxy Web View

![HAProxy Web](/docs/assets/haproxy-webview.png)

## Test load balancing on port 3307

### Using sysbench

Create the container image:
```bash
$ cd sb-docker/
$ DOCKER_BUILDKIT=1 docker build . -t sysbench-docker
```

Create the schema:
```bash
$ docker run \
--rm=true \
--name=sb-schema \
--network=haproxy-test_default \
sysbench-docker \
mysql \
--user=root \
--password=t00r \
--host=haproxy1 \
--port=3306 \
-e "CREATE DATABASE sbtest"
```

Prepare the sysbench database:

```bash
$ docker run \
--rm=true \
--name=sb-prepare \
--network=haproxy-test_default \
sysbench-docker \
sysbench \
--db-ps-mode=disable \
--db-driver=mysql \
--oltp-table-size=100000 \
--oltp-tables-count=1 \
--threads=12 \
--mysql-host=haproxy1 \
--mysql-port=3306 \
--mysql-user=root \
--mysql-password=t00r \
--mysql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/parallel_prepare.lua \
prepare
```

Run the benchmark for MySQL:

```bash
$ docker run \
--rm=true \
--name=sb-run \
--network=haproxy-test_default \
sysbench-docker \
sysbench \
--db-ps-mode=disable \
--db-driver=mysql \
--report-interval=2 \
--mysql-table-engine=innodb \
--oltp-table-size=100000 \
--oltp-tables-count=1 \
--threads=12 \
--time=60 \
--mysql-host=haproxy1 \
--mysql-port=3307 \
--mysql-user=root \
--mysql-password=t00r \
--mysql-db=sbtest \
/usr/share/sysbench/tests/include/oltp_legacy/select.lua \
run
```
