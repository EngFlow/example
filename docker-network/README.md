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

The test should pass. If you look at the log, it'll show:

```
exec ${PAGER:-/usr/bin/less} "$0" || exit 1
Executing tests from //:docker-network-test
whoami: cannot find name for user ID 1000
-----------------------------------------------------------------------------
JUnit4 Test Runner
. | DEBUG | Network name: bridge-f7d98cfa-f2b8-46cb-a2fa-24bd9138925e
 | DEBUG | Server address: 172.25.0.4
 | DEBUG | Waiting for server...

psql: could not connect to server: Connection refused
	Is the server running on host "172.25.0.4" and accepting
	TCP/IP connections on port 5432?

 | DEBUG | Waiting for server...

psql: could not connect to server: Connection refused
	Is the server running on host "172.25.0.4" and accepting
	TCP/IP connections on port 5432?

 | DEBUG | Waiting for server...

psql: could not connect to server: Connection refused
	Is the server running on host "172.25.0.4" and accepting
	TCP/IP connections on port 5432?

 | DEBUG | Waiting for server...

psql: FATAL:  role "foo" does not exist

 | DEBUG | Server running
 | DEBUG | Server replied:

psql: FATAL:  role "foo" does not exist


Time: 6.895

OK (1 test)


BazelTestRunner exiting with a return value of 0
JVM shutdown hooks (if any) will run now.
The JVM will exit once they complete.

-- JVM shutdown starting at 2021-07-26 07:53:39 --
```
