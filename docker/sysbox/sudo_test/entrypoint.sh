#!/usr/bin/env bash

check_docker_is_alive () {
  while (! docker stats --no-stream &>>/dev/null ); do
    # Docker takes a few seconds to initialize.
    sleep 1
  done
}
export -f check_docker_is_alive

sudo dockerd -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock &>>/dev/null &
 # Time out after 1m to avoid waiting on docker forever.
timeout 60s bash -c check_docker_is_alive
eval "$@"
