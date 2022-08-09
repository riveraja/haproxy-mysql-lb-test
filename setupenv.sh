#!/bin/bash

if [[ $1 = "start" ]]; then
    docker-compose up -d

    sleep 60

    for IMG in $(docker-compose ps -a | grep Up | grep replica | awk '{print $1}'); do docker exec -it $IMG bash -c "mysql -uroot -pt00r < /sqlscripts/replication.sql"; done

    docker exec -it mysql_source bash -c "mysql -uroot -pt00r < /sqlscripts/user.sql"

    echo "Execute docker-compose logs haproxy1 and check if the backends are up. Alternatively open your browser and browse to <IP>:80/haproxy/stats with user: mysqlstats and pwd: secret"
fi

if [[ $1 = "down" ]]; then
    docker-compose down
fi
