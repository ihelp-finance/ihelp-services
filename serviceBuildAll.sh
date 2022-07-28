#!/bin/bash

services=( client server db router scripts )

for service in "${services[@]}"
do

    echo ""
    echo "BUILDING: $service"
    ./serviceBuild.sh $service
    echo ""

done
