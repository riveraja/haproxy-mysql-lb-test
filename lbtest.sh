#!/bin/bash

for COUNT in {1..5}; do docker exec -it mysql_source mysql -uroot -pt00r -hhaproxy1 -P3307 -e "select @@hostname"; done
