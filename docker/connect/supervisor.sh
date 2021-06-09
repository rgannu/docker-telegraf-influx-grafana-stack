#!/usr/bin/env bash
set -eo pipefail

mkdir -p /var/log/supervisor

supervisord -n &
pid="$!"

wait ${pid}