#!/bin/sh

pushd ../

printf "\nInstalling K8S Services & Deployments ...\n"
kubectl apply -f apis/httpbin.yaml
# kubectl apply -f apis/petstore.yaml
# kubectl apply -f apis/petstore-v2.yaml
printf "\n"

printf "\nInstalling APIDocs ...\n"
kubectl apply -f apis/gloo-portal-test-api-api-doc-spec-cm.yaml
kubectl apply -f apis/test-api.yaml
printf "\n"

printf "\nInstalling API Products ...\n"
kubectl apply -f apis/test-product.yaml
printf "\n"

printf "\nInstalling Portal ...\n"
kubectl apply -f portal/test-portal-portal.yaml
printf "\n"

sleep 2

printf "\nInstalling Portal Environment ...\n"
kubectl apply -f environment/test-environment.yaml
printf "\n"
 
popd
