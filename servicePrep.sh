#!/bin/bash

services=( ihelp-app ihelp-contracts )

# test your github connection
ssh git@github.com > /dev/null 2>&1
ec=$?
echo $ec
if [[ "$ec" != "1" ]];then
    echo "Please add your ssh public key to your github account so you can pull the ihelp repos down..."
    exit 1
fi

version_tag="master"

for service in "${services[@]}"
do

   echo $service

    git clone git@github.com:ihelp-finance/$service.git $service
    cd $service
    git checkout $version_tag
    cd ../
    
done
