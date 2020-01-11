Kind (Kubernetes in Docker) permet de déployer un cluster Kubernetes de façon à ce que chacun des nodes du cluster tourne dans un container Docker.

Pour l'utiliser il suffit simplement d'installer *Docker* ainsi que la dernière release de Kind ([https://github.com/kubernetes-sigs/kind/releases](https://github.com/kubernetes-sigs/kind/releases)).

## Les Commandes

Une fois installé, la liste des commandes disponibles peut être obtenue avec la commande suivante:

```
$ kind
kind creates and manages local Kubernetes clusters using Docker container 'nodes'

Usage:
  kind [command]


Available Commands:
  build       Build one of [base-image, node-image]
  completion  Output shell completion code for the specified shell (bash or zsh)
  create      Creates one of [cluster]
  delete      Deletes one of [cluster]
  export      exports one of [kubeconfig, logs]
  get         Gets one of [clusters, nodes, kubeconfig]
  help        Help about any command
  load        Loads images into nodes
  version     prints the kind CLI version

Flags:
  -h, --help              help for kind
      --loglevel string   DEPRECATED: see -v instead
  -q, --quiet             silence all stderr output
  -v, --verbosity int32   info log verbosity
      --version           version for kind

Use "kind [command] --help" for more information about a command.
```

## Création d'un cluster composé d'un seul node

Il suffit de lancer la commande suivante pour créer un cluster (seulement un node ici) en quelques dizaines de secondes:

```
$ kind create cluster --name k8s
Creating cluster "k8s" ...
 ✓ Ensuring node image (kindest/node:v1.16.3) 🖼

 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-k8s"
You can now use your cluster with:

kubectl cluster-info --context kind-k8s

Have a nice day! 👋
```

Si nous listons les containers présents, nous pouvons voir qu'un container a été créé. A l'intérieur de celui-ci tournent l'ensemble des processus de Kubernetes.

```
$ docker ps
CONTAINER ID   IMAGE                COMMAND                 CREATED        STATUS
PORTS                       NAMES
6a0c88eb3534   kindest/node:v1.16.3 "/usr/local/bin/entr…"  2 minutes ago  Up About a minute
127.0.0.1:64348->6443/tcp   k8s-control-plane
```

Kind a automatiquement créé un context et l'a définit en tant que context courant.

```
$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO      NAMESPACE
*         kind-k8s     kind-k8s     kind-k8s
          minikube     minikube     minikube
```

Note: dans cet exemple un context *minikube* était déjà présent, celui-ci résultant de la mise en place de *Minikube* dans un exemple précédent.

```
$ kubectl get nodes
NAME                STATUS   ROLES    AGE     VERSION
k8s-control-plane   Ready    master   3m22s   v1.16.3
```

## HA Cluster

Kind permet également de mettre en place un cluster comportant plusieurs nodes, pour cela il faut utiliser un fichier de configuration. Par exemple, le fichier suivant définit un cluster de 6 nodes: 3 nodes de type master et 3 nodes workers.

```
# HA-config.yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: control-plane
- role: control-plane
- role: worker
- role: worker
- role: worker
```

Pour mettre en place ce nouveau cluster, il suffit de préciser le fichier de configuration dans les paramètres de lancement de la commande de création.

```
$ kind create cluster --name k8s-HA --config HA-config.yaml
Creating cluster "k8s-HA" ...
 ✓ Ensuring node image (kindest/node:v1.16.3) 🖼
 ✓ Preparing nodes 📦
 ✓ Configuring the external load balancer ⚖
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining more control-plane nodes 🎮
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-k8s-HA"
You can now use your cluster with:

kubectl cluster-info --context kind-k8s-HA

Not sure what to do next? 😅 Check out https://kind.sigs.k8s.io/docs/user/quick-start/
```

Si nous listons une nouvelles fois les containers, nous en trouvons 6 nouveaux: chacun fait touner un des nodes du cluster.

```
$ docker ps
CONTAINER ID   IMAGE                          COMMAND                  CREATED             STATUS
        PORTS                       NAMES
48cd8e8ce0c6   kindest/node:v1.16.3           "/usr/local/bin/entr…"   4 minutes ago       Up 3 minutes
        127.0.0.1:64536->6443/tcp   k8s-HA-control-plane
c86dbf899bf0   kindest/node:v1.16.3           "/usr/local/bin/entr…"   4 minutes ago       Up 3 minutes
                                    k8s-HA-worker3
7505c8469ceb   kindest/node:v1.16.3           "/usr/local/bin/entr…"   4 minutes ago       Up 3 minutes
        127.0.0.1:64537->6443/tcp   k8s-HA-control-plane2
81580fa80cb9   kindest/node:v1.16.3           "/usr/local/bin/entr…"   4 minutes ago       Up 3 minutes
                                    k8s-HA-worker
4c13a184ff3e   kindest/haproxy:2.0.0-alpine   "/docker-entrypoint.…"   4 minutes ago       Up 4 minutes
        127.0.0.1:64539->6443/tcp   k8s-HA-external-load-balancer
99dcc9f986a0   kindest/node:v1.16.3           "/usr/local/bin/entr…"   4 minutes ago       Up 3 minutes
                                    k8s-HA-worker2

510e6235b747   kindest/node:v1.16.3           "/usr/local/bin/entr…"   4 minutes ago       Up 3 minutes
        127.0.0.1:64538->6443/tcp   k8s-HA-control-plane3
6a0c88eb3534   kindest/node:v1.16.3           "/usr/local/bin/entr…"   12 minutes ago      Up 12 minute
s       127.0.0.1:64348->6443/tcp   k8s-control-plane
```

Kind a automatiquement créé un context et l'a définit en tant que context courant.

```
$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO      NAMESPACE
          kind-k8s     kind-k8s     kind-k8s
*         kind-k8s-HA  kind-k8s-HA  kind-k8s-HA
          minikube     minikube     minikube
```

Nous pouvons dont directement lister les nodes du cluster:

```
$ kubectl get nodes
NAME                    STATUS   ROLES    AGE     VERSION
k8s-ha-control-plane    Ready    master   5m30s   v1.16.3
k8s-ha-control-plane2   Ready    master   4m49s   v1.16.3
k8s-ha-control-plane3   Ready    master   4m8s    v1.16.3
k8s-ha-worker           Ready    <none>   3m29s   v1.16.3
k8s-ha-worker2          Ready    <none>   3m28s   v1.16.3
k8s-ha-worker3          Ready    <none>   3m32s   v1.16.3
```

## Cleanup

Afin de supprimer un cluster créé avec *Kind*, il suffit de lancer la commande `kind delete cluster --name CLUSTER_NAME`.

Les commandes suivantes suppriment les 2 clusters créés précédemment:

```
$ kind delete cluster --name k8s
Deleting cluster "k8s" ...

$ kind delete cluster --name k8s-HA
Deleting cluster "k8s-HA" ...
```
