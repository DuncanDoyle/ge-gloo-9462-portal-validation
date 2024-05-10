#!/bin/sh

export GLOO_EDGE_VERSION="1.16.8"
export GLOO_EDGE_PORTAL_VERSION="1.4.1"

export GLOO_EDGE_HELM_VALUES_FILE="gloo-edge-helm-values.yaml"
export GLOO_EDGE_PORTAL_HELM_VALUES_FILE="ge-portal-helm-values.yaml"

if [ -z "$GLOO_EDGE_LICENSE_KEY" ]
then
   echo "Gloo Edge License Key not specified. Please configure the environment variable 'GLOO_EDGE_LICENSE_KEY' with your Gloo Edge License Key."
   exit 1
fi

printf "\nInstalling Gloo Edge $GLOO_EDGE_VERSION ...\n"
helm upgrade --install gloo glooe/gloo-ee --namespace gloo-system --create-namespace --set-string license_key=$GLOO_EDGE_LICENSE_KEY -f $GLOO_EDGE_HELM_VALUES_FILE --version $GLOO_EDGE_VERSION
printf "\n"

printf "\nInstalling Gloo Edge Portal $GLOO_EDGE_PORTAL_VERSION ...\n"
helm upgrade --install gloo-portal gloo-portal/gloo-portal --namespace gloo-portal --create-namespace -f $GLOO_EDGE_PORTAL_HELM_VALUES_FILE --version $GLOO_EDGE_PORTAL_VERSION
printf "\n"
