# HAProxy + MySQL Replication Cluster setup

## Deploy the instances

```
docker-compose up -d
```

## Setup replication on each replica

```
CHANGE REPLICATION SOURCE TO SOURCE_HOST='mysql_source', SOURCE_USER='root', SOURCE_PASSWORD='t00r', SOURCE_AUTO_POSITION=1;
START REPLICA;
```

## Add the haproxy user

```
CREATE USER 'haproxyuser'@'%';
```

## Test load balancing on port 3307

```
for COUNT in {1..5}; do docker exec -it mysql_source mysql -uroot -pfloat -hhaproxy1 -P3307 -e "select @@hostname"; done
```

## Use the bash script
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

## Check if all backends are UP
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

## Test load balancing on port 3307

Sample terminal output:
```
$ ./lbtest.sh
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+
| @@hostname |
+------------+
| replica3   |
+------------+
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+
| @@hostname |
+------------+
| replica1   |
+------------+
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+
| @@hostname |
+------------+
| replica2   |
+------------+
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+
| @@hostname |
+------------+
| replica3   |
+------------+
mysql: [Warning] Using a password on the command line interface can be insecure.
+------------+
| @@hostname |
+------------+
| replica1   |
+------------+
```