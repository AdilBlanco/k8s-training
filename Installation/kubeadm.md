Dans cette mise en pratique, vous allez mettre en place un cluster Kubernetes à l'aide de *kubeadm*.

# Quelques prérequis

##  Hardware Requirements

Pour la mise en place d'un cluster avec kubeadm, il est nécessaire d'avoir une ou plusieurs machines avec les spécifications suivantes:

- Système d'exploitation

  * Ubuntu 16.04+
  * Debian 9+
  * CentOS 7
  * Red Hat Enterprise Linux (RHEL) 7
  * Fedora 25+
  * HypriotOS v1.0.1+
  * Container Linux (tested with 1800.6.0)

- 2 GB RAM minimum par machine
- 2 CPUs minimum par machine

Dans cet exemple nous considérerons 3 machines virtuelles basées sur Ubuntu 18.04, sur lesquelles nous avons un accès ssh via une clé d'authentification. Ces machines sont nommées node1, node2 et node3.

## Kubectl

Assurez-vous d'avoir installé *kubectl* sur votre machine locale (cf exercice précédent). Ce binaire permet de communiquer avec un cluster Kubernetes depuis la ligne de commande.

# Configuration

L'étape de configuration consiste à installer les logiciels nécessaires sur une infrastructure déjà provisionnée.

Il y a différentes façon de réaliser cette configuration:
- en se connectant manuellement en ssh sur chaque machine
- en utilisant un utilitaire de configuration, comme *Ansible*, *Chef*, *Puppet*

Nous lancerons ici des commandes via ssh mais n'hésitez pas à passer par une autre méthode si vous le souhaitez.

## Installation des prérequis

Sur chaque machine, nous allons installer les éléments suivants:
- un runtime de container (nous utiliserons Docker)
- le binaire *kubeadm* pour la création du cluster
- le binaire *kubelet* pour la supervision des containers

Pour cela, vous pouvez utiliser la commande suivante (en ayant au préalable positionné les variables d'environnement IP1, IP2, IP3 avec les IP des nodes respectifs). Dans l'exemple envisagé ici, nous avons accès root via une clé ssh.

```
for IP in $IP1 $IP2 $IP3; do
ssh -o "StrictHostKeyChecking=no" root@$IP << EOF /bin/bash
  curl https://get.docker.com | sh
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
  apt-get update && apt-get install -y kubelet kubeadm
EOF
done
```

## Initialisation du cluster

Lancer la commance suivante afin d'initialiser le cluster, à l'aide de *kubeadm*, depuis *node1*:

```
$ ssh root@$IP1 kubeadm init
````

La mise en place de l'ensemble des composants du master prendra quelques minutes. A la fin vous obtiendrez la commande à lancez depuis les autres VMs afin de les ajouter au cluster.

## Ajout de nodes

Vous pouvez copier/coller la commande de *join* obtenue précédemment, ou bien la récupérer avec la commande suivante:

```
$ JOIN_CMD=$(ssh root@$IP1 kubeadm token create --print-join-command)
```

Lancez la ensuite sur les nodes *node2* et *node3* afin de les ajouter au cluster:

```
$ for IP in $IP2 $IP3; do ssh root@$IP $JOIN_CMD; done
```

## Récupération du context

Afin de pouvoir dialoguer avec le cluster que vous venez de mettre en place, vi le binaire *kubectl* que vous avez installé sur votre machine locale, il est nécessaire de récupérer le fichier de configuration du cluster. Utilisez pour cela les commandes suivantes depuis votre machine locale:

```
$ scp root@$IP1:/etc/kubernetes/admin.conf do-kube-config
$ export KUBECONFIG=do-kube-config
```

Listez alors les nodes du cluster, ils apparaitront avec le status *NotReady*.

```
$ kubectl get nodes
NAME      STATUS     ROLES    AGE     VERSION
node1     NotReady   master   2m57s   v1.17.0
node2     NotReady   <none>   33s     v1.17.0
node3     NotReady   <none>   29s     v1.17.0
```

## Installation d'un addons pour le networking entre les Pods

La commande suivante permet d'installer les composants nécessaires pour la communication entre les Pods qui seront déployés sur le cluster.

```
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

Note: il y a plusieurs solutions de networking qui peuvent être utilisées, la solution envisagée ici est Weave Net. L'article suivant donne une bonne comparaison des solutions les plus utilisées: [objectif-libre.com/fr/blog/2018/07/05/comparatif-solutions-reseaux-kubernetes/](objectif-libre.com/fr/blog/2018/07/05/comparatif-solutions-reseaux-kubernetes/)

## Vérification de l'état de santé des nodes

Maintenant que la solution de networking a été installée, les nodes sont dans l'état *Ready*.

```
$ kubectl get nodes
NAME     STATUS   ROLES    AGE   VERSION
node1    Ready    master   4m    v1.17.0
node2    Ready    <none>   3m    v1.17.0
node3    Ready    <none>   3m    v1.17.0
```

Le cluster est prêt à être utilisé.
