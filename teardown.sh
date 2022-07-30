#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Please provide network name for deployment you want to teardown..."
    exit 1
fi 

network="$1"

# SET THE K8S CONTEXT
if [[ "$kubecontext" == "" ]];then
  kubecontext="ihelp-cluster-local"
fi
kubectl="kubectl --context=$kubecontext"

echo ""
echo "TEARING DOWN $network..."
echo ""

echo $kubectl delete all --all -n "ihelp-$network"
$kubectl delete all --all -n "ihelp-$network"
