#!/bin/bash
set -e

db_timeout=30
db_user=root

function wait_for_database() {
    local counter=0
    while (( ${counter} < ${db_timeout} )); do
        let counter=counter+1
        mysql_status="$(mysql -N                    \
                              -B                    \
                              --user=${db_user}     \
                              --host=localhost      \
                              -e "SELECT 'ready';"  \
                              2> /dev/null)"

        if [[ ${mysql_status} == "ready" ]]; then break; fi

        sleep 1s
    done

    echo "${mysql_status}"
}

mysqld --initialize --user=mysql --datadir=/var/lib/mysql

TEMP_FILE='/tmp/mysql-first-time.sql'
cat > "$TEMP_FILE" <<-EOSQL
    DROP USER '${db_user}'@'localhost';
    CREATE USER '${db_user}'@'localhost';
    GRANT ALL ON *.* TO '${db_user}'@'localhost' WITH GRANT OPTION ;
    CREATE USER '${db_user}'@'%' ;
    GRANT ALL ON *.* TO '${db_user}'@'%' WITH GRANT OPTION ;
    DROP DATABASE IF EXISTS test ;
    FLUSH PRIVILEGES ;
EOSQL

chown -R mysql:mysql /var/lib/mysql

mysqld --datadir=/var/lib/mysql --user=mysql --init-file=$TEMP_FILE &

mysql_status=$(wait_for_database)

if [[ ${mysql_status} == "ready" ]]; then
    echo "Database successfully configured"
else
    echo "Error: MySQL server didn't respond within ${db_timeout}s"
    exit 1
fi

exit 0
