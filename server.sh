#!/bin/bash

declare -r FIFO=fifo
declare -r port=$1

if ! [[ $# = 1 && $port =~ ^[0-9]+$ ]]; then
  echo "You have entered an invalid port, please choose another one"
  exit 1
fi

#nettoyage
function clean() {
  rm -f fifo;
}
trap clean EXIT

function interaction() {
  local mode args
  while true; do
  read mode args || exit -1
  bash vsh_server.sh $mode $args
  exit $?
done
}

echo "Port $port is up and running ..."
while true; do
  interaction < "FIFO" | netcat -l -k $port > "$FIFO"
done
