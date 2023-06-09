# Setup Flux2 with Private HTTPS git repo as Resources
The documents explains how to set up flux with Private HTTPS git repo as `resources` in kustomize yaml.

In the example - The `kustomization.yaml` in `https://myproj@dev.azure.com/myproj/poc/_git/the-overlay-repo` has a reference in `resources` to another private repo as shown below.
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- https://myproj@dev.azure.com/myproj/poc/_git/release-base?ref=v0.0.1
```

## The idea !!!

__Problem__ : As of now Kustomization controller(the one handled `Kustomization` CRD objects) of Flux2 does not have option to refer private git repository.

__Solution/Hack__: We are changing the Kustomization controller deployment through helm `values.yaml`. We are running the Kustomization controller process as root user and injecting a file `/root/.gitconfig` - that will replace the private repo URL with basic auth credentials.

## How to Install Flux2 ?

### Prerequisite

The below environment variables are exported and the [my-proj-git-repo.yaml](my-proj-git-repo.yaml) and [my-proj-kustomization.yaml](my-proj-kustomization.yaml) refers to correct repo `url` and `path`.
```sh
export REPO_USER_ID=xxxxx
export REPO_PASSWORD=xxxxx
```

### Install flux

```sh
./install-flux.sh
```
### Uninstall flux

```sh
./uninstall-flux.sh
```

## What happens in install-flux.sh

1. Validated Environment variables `REPO_USER_ID` and `REPO_PASSWORD` are present.

2. Create a file `.gitconfig` with the below content.
```sh
[url "https://$REPO_USER_ID:$REPO_PASSWORD@dev.azure.com"]
        insteadOf = https://myproj@dev.azure.com
```

3. Create namespace `flux-system` and secrets `azure-repo-auth` and `kustomize-controller-git-config` in it.
```sh
kubectl create ns flux-system

kubectl create secret generic azure-repo-auth \
    --from-literal=username=$REPO_USER_ID \
    --from-literal=password=$REPO_PASSWORD \
    --namespace=flux-system

kubectl create secret generic kustomize-controller-git-config -n flux-system --from-file=./.gitconfig
```

4. Install flux
```sh
helm upgrade -i -name flux --namespace=flux-system flux2-2.7.0.tgz -f values.yaml
```
Refer [values.yaml](values.yaml) for little more detail.

5. Create `GitRepository` and `Kustomization` CRD object
```yaml
# kubectl apply -f my-proj-git-repo.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: my-proj-git-repo
  namespace: flux-system
spec:
  interval: 3m0s
  timeout: 60s
  ref:
    branch: main
  secretRef:
    name: azure-repo-auth
  url: https://myproj@dev.azure.com/myproj/poc/_git/the-overlay-repo # Add proper url
```

```yaml
# kubectl apply -f my-proj-kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: my-proj-kustomization
  namespace: flux-system
spec:
  force: false
  interval: 3m0s
  path: mypath # Add proper path
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-proj-git-repo
```
