# Docker Image: MySQL Server

Fork of official MySQL Docker image that instantiates DB at build rather than run time.

## What's different?

 * MySQL server is configured at build time rather than setup time.
 * Root user has no password rather than configurable password.

## Why

Using the official image, you have to instantiate an empty database and then create schemas and populate them using external scripts. I want the schemas and population to be handled when building the Docker image. This is because an environment using a MySQL Docker container should only need to be capable of running a Dockerfile.

The absence of a root password is because I have no need of this on a development environment. Obviously this makes it unsuitable for production or if sensitive information is being used on a development environment.

## Example

This is a basic example of a Dockerfile and simple database install script.

### Directory structure

```
.
├── Dockerfile
└── install.sh
```

### Dockerfile

```docker
FROM    andystanton/mysql:5.6
ADD     ./install.sh /tmp/install.sh
RUN     /tmp/install.sh
EXPOSE  3306
CMD     ["mysqld", "--datadir=/var/lib/mysql", "--user=mysql"]
```

### install.sh

```sh
#!/bin/bash

# start mysql server as a background process so we can modify it
mysqld --datadir=/var/lib/mysql --user=mysql &

# wait for mysqld to start
counter=0
while (( ${counter} < "30" )); do
    let counter=counter+1
    mysql_status="$(mysql -N -B -uroot -hlocalhost -e "SELECT 'ready';" 2> /dev/null)"
    if [[ ${mysql_status} == "ready" ]]; then break; fi
    sleep 1s
done

# error if db doesn't come up
if [[ ${mysql_status} != "ready" ]]; then 
  echo "Database did not start within 30 seconds"
  exit 1
fi

# Perform custom operations to create and populate database. liquibase or flyway > command line mysql
mysql -hlocalhost -uroot -e "CREATE DATABASE foo;"
mysql -hlocalhost -uroot -Dfoo -e "CREATE TABLE bar (some_column INT);"

# shut down mysqld
mysqladmin -uroot shutdown

exit 0
```

### Building the Docker image

```sh
docker build -t andystanton/mysql-test .
```

### Running a container from the image

```sh
docker run -d -t --name mysql-test -p 3306:3306 andystanton/mysql-test
```

### Accessing the database

If you have mysql command line tools installed on the host machine, you can verify it's worked as follows.

You need to know your Docker host IP address. On Linux this will be localhost. With boot2docker, you can find this out by running ```boot2docker ip```.

```sh
mysql -h<docker_host_ip> -uroot
```

You can then run:

```
mysql> describe foo.bar;
```

Which should give this result:

```
+-------------+---------+------+-----+---------+-------+
| Field       | Type    | Null | Key | Default | Extra |
+-------------+---------+------+-----+---------+-------+
| some_column | int(11) | YES  |     | NULL    |       |
+-------------+---------+------+-----+---------+-------+
1 row in set (0.01 sec)
```
