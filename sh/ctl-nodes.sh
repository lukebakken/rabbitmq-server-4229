#!/usr/bin/env bash

set -o errexit
set -o nounset

readonly dir="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

readonly rmq_host_name="$(hostname)"
readonly rmq_ver='3.9.13'
readonly rmq_dir="$dir/rabbitmq_server-$rmq_ver"

readonly rabbitmqctl_cmd="$rmq_dir/sbin/rabbitmqctl"

declare -i IDX=0

for IDX in 0 1 2
do
    rmq_node_name="rabbit$IDX@$rmq_host_name"
    {
        for rabbitmqctl_arg in "$@"
        do
            "$rabbitmqctl_cmd" -n "$rmq_node_name" "$rabbitmqctl_arg"
        done
    } &
done

wait
