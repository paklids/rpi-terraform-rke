## Setting up Kadalu to present GlusterFS distributed storage to the rest of the cluster (this is the hardest part)

Get Kadalu running inside the cluster

```
kubectl apply -f https://github.com/kadalu/kadalu/releases/download/0.7.7/kadalu-operator-rke.yaml
```

Be patient while this gets setup. To confirm it is running check `kubectl get pods -n kadalu`

Edit the `sample-storage-config.yaml` to meet your needs then lauch - this will create & offer the PVC to the cluster

```
kubectl apply -f sample-storage-config.yaml
```

(this last command may take some time to complete - use `kubectl get pvc` & `kubectl describe pvc` to check)

## Using MetalLB to present services on a local network virtual IP address

(see https://metallb.universe.tf/installation/ for more)

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

Then edit and apply the config.yaml (see elsewhere in this repo)

```
kubectl apply -f metallb/config.yaml
```

## Install the Minecraft Helm chart

Install Helm to leverage it's amazing power (On a mac you can simply `brew install helm`)

Edit the values.yaml to match your needs. Note the sections `persistence.dataDir.existingClaim` and `minecraftServer.serviceType`

```
helm install minecraft -f values.yaml itzg/minecraft
```

or make changes to the `values.yaml`

```
helm upgrade minecraft -f values.yaml itzg/minecraft
```

## Edit minecraft data on the fly

perform mantenance on the minecraft data inside the Persistent Volume

```
kubectl apply -f test-volume.yaml
kubectl exec --stdin --tty pod-pvc-test -- /bin/sh
```

If you need to rsync world data to from some other server then you'll need to install rsync & ssh within that pod-pvc-test container

```
apk add rsync openssh
```

## Publish your server using Dynamic DNS

You'll still need to set up port forwarding on your router to point to the private virtual IP & port that you've already set

Now edit the `values.yaml` for the ddclient (similar to ddclient.conf) & publish that

```
helm install ddclient k8s-at-home/ddclient --values ddclient/values.yaml
```
