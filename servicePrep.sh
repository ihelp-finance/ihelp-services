#!/bin/bash

services=( ihelp-app ihelp-contracts )

version_tag="master"

for service in "${services[@]}"
do

   echo $service

    git clone https://github.com/iHelp-Finance/$service.git $service
    
    cd $service
    git checkout $version_tag
    cd ../
    
done
