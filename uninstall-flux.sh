#!/bin/bash

kubectl delete --all Kustomization -n flux-system
kubectl delete --all GitRepository -n flux-system
helm uninstall -name flux -n flux-system
kubectl delete --all secrets -n flux-system
kubectl delete ns flux-system
