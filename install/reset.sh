#!/bin/sh

# Remove all installed resources

pushd ../
kubectl delete -f portal/test-portal-portal.yaml
kubectl delete -f environment/test-environment.yaml

kubectl delete -f apis/test-product.yaml
kubectl delete -f apis/test-api.yaml
kubectl delete -f apis/gloo-portal-test-api-api-doc-spec-cm.yaml
kubectl delete -f apis/httpbin.yaml

popd