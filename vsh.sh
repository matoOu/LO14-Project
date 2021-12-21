#!/bin/bash

declare -r mode=${1:1}
declare -r server_name=$2
declare -r port=$3
declare -r args=$(echo $* | cut -d " " -f4-)

function send_cmd() {
  echo $1 | nc $server_name $port
}

function browse() {
send_cmd "browse $args"
nc $server_name $port
}

function extract() {
#####
}

function check_server() {
if ! nc -zv $server_name $port 2>/dev/null; then
echo "server at address $server_name is not listening on port $port"
exit 1
fi
}

case $mode in
list)
check_server
send_cmd "list"
;;

extract)
check_server
extract $args
;;

browse)
check_server
browse $args
;;

*)

echo "type vsh mode ip port archive"
echo "we have -list -extract -browse -create"
;;
esac
