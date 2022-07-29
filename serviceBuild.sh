#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Please provide name of service to build (e.g. router, client, server, scripts)..."
    exit 1
fi 

service="$1"

servicedir="$PWD"

if [[ "$service" == "router" ]]; then
    
    context="ihelp-app/nginx"

elif [[ "$service" == "client" ]]; then

    context="ihelp-app/client"

elif [[ "$service" == "server" ]]; then

    context="ihelp-app"
    
elif [[ "$service" == "db" ]]; then

    context="ihelp-app"
    
elif [[ "$service" == "scripts" ]]; then

    context="."
    
fi

if [[ "$context" == "" ]];then
    echo "No service found. Please specify correct service name (e.g. router, client, server, scripts)..."
    exit 1
fi

echo 
echo "Building to: turbinex/ihelp-$service:${docker_tag}"
echo

DOCKER_BUILDKIT=1 docker build --no-cache -t turbinex/ihelp-$service:${docker_tag} -f $servicedir/docker/Dockerfile-$service $context

echo
echo docker push turbinex/ihelp-$service:${docker_tag}
echo 