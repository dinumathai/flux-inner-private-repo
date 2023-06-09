#!/bin/bash

if [ ! -v REPO_USER_ID ]; then
  echo "Environment variable REPO_USER_ID is missing"
  exit 1
fi
if [ ! -v REPO_PASSWORD ]; then
  echo "Environment variable REPO_PASSWORD is missing"
  exit 1
fi


# Create a file `.gitconfig` with the below content.
echo [url \"https://$REPO_USER_ID:$REPO_PASSWORD@dev.azure.com\"] > .gitconfig
echo "        insteadOf = https://myproj@dev.azure.com" >> .gitconfig

#  Create namespace `flux-system` and secrets `azure-repo-auth` and `kustomize-controller-git-config` in it.
kubectl create ns flux-system
kubectl create secret generic azure-repo-auth \
    --from-literal=username=$REPO_USER_ID \
    --from-literal=password=$REPO_PASSWORD \
    --namespace=flux-system
kubectl create secret generic kustomize-controller-git-config -n flux-system --from-file=./.gitconfig

# Install flux
helm upgrade -i -name flux --namespace=flux-system flux2-2.7.0.tgz -f values.yaml

# 2 sec delay for the CRD to get created fully
sleep 2

kubectl apply -f my-proj-git-repo.yaml
kubectl apply -f my-proj-kustomization.yaml

echo "To display the status use command: kubectl get kustomization -n flux-system"
