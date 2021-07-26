# Example: Docker networking with sibling containers

## Contents

This example shows how can a Java test, which runs in a Docker container, start further containers
and have them communicate over a local (bridge) network.

This Java test:

- runs in a Docker container
- starts another container (a "sibling container") that is a PostgreSQL server
- starts another container which talks to the first (PostgreSQL client)

## Build the action execution image

```sh
docker build -t docker_jdk_psql .
```

Then push this to a Docker registry where the EngFlow worker can pull it from.

## Configure the server

Run your EngFlow service with:

- [`--allow_docker=true`](https://docs.engflow.com/docs/re/config/options.html#allow_docker)
- [`--docker_allow_network_access=true`](https://docs.engflow.com/docs/re/config/options.html#docker_allow_network_access)
- [`--docker_allow_sibling_containers=true`](https://docs.engflow.com/docs/re/config/options.html#docker_allow_sibling_containers)

## Build and test

Update the `DOCKER_JDK_PSQL` reference in the `BUILD` file.

Then:

```sh
bazel --ignore_all_rc_files test          \
  --remote_executor=<ENGFLOW_ENDPOINT>    \
  --spawn_strategy=remote                 \
  --host_platform=//:platform             \
  --platforms=//:platform                 \
  --host_javabase=//:jdk                  \
  --javabase=//:jdk                       \
  --test_output=errors                    \
  (... extra flags for auth, etc. ...)    \
  --                                      \
  //:docker-network-test
```

The test should pass. The logs will show:

```
exec ${PAGER:-/usr/bin/less} "$0" || exit 1
Executing tests from //:docker-network-test
whoami: cannot find name for user ID 1000
-----------------------------------------------------------------------------
JUnit4 Test Runner
. | DEBUG | Network name: bridge-8743470f-a035-49b8-8cd1-95eb0f7ff19d
 | DEBUG | Server address: 172.27.0.3
 | DEBUG | Waiting for server...

psql: could not connect to server: Connection refused
	Is the server running on host "172.27.0.3" and accepting
	TCP/IP connections on port 5432?

 | DEBUG | Waiting for server...

psql: could not connect to server: Connection refused
	Is the server running on host "172.27.0.3" and accepting
	TCP/IP connections on port 5432?

 | DEBUG | Waiting for server...

psql: could not connect to server: Connection refused
	Is the server running on host "172.27.0.3" and accepting
	TCP/IP connections on port 5432?

 | DEBUG | Waiting for server...
                                    List of databases
       Name       |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
------------------+----------+----------+------------+------------+-----------------------
 circle_test      | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres         | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0        | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
                  |          |          |            |            | postgres=CTc/postgres
 template1        | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
                  |          |          |            |            | postgres=CTc/postgres
 template_postgis | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
(5 rows)



 | DEBUG | Server running
 | DEBUG | Server replied:
                                    List of databases
       Name       |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
------------------+----------+----------+------------+------------+-----------------------
 circle_test      | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres         | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0        | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
                  |          |          |            |            | postgres=CTc/postgres
 template1        | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
                  |          |          |            |            | postgres=CTc/postgres
 template_postgis | postgres | UTF8     | en_US.utf8 | en_US.utf8 | 
(5 rows)




Time: 6.863

OK (1 test)


BazelTestRunner exiting with a return value of 0
JVM shutdown hooks (if any) will run now.
The JVM will exit once they complete.

-- JVM shutdown starting at 2021-07-26 08:05:47 --
```

