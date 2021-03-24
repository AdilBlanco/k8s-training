Dans cet exercice, nous allons mettre à jour un cluster Kubernetes depuis la version 1.18.12 vers la version 1.19.4

## Prérequis

Avoir accès à un cluster dans la version 1.18.12 créé avec *kubeadm*.

Si vous souhaitez créer un cluster local 1.18.12 rapidement, vous pouvez lancer les commandes suivantes qui utilisent l'outils Multipass ([https://multipass.run](https://multipass.run)) présenté au début du cours.

```
$ curl -O https://luc.run/k8s.sh && chmod +x k8s.sh
$ ./k8s.sh -v 1.18.12-00 -w 2
```

En quelques minutes vous aurez un cluster dans la version souhaitée, celui-ci étant constitué d'un node master et de 2 nodes worker.

```
$ export KUBECONFIG=$PWD/k8s.cfg

$ kubectl get nodes
NAME    STATUS   ROLES    AGE     VERSION
k8s-1   Ready    master   4m43s   v1.18.12
k8s-2   Ready    <none>   4m20s   v1.18.12
k8s-3   Ready    <none>   4m14s   v1.18.12
```

## Mise à jour du node master

La mise à jour commence par les nodes master (un seul dans le cadre de cet exercice)

### Mise à jour de kubeadm

Depuis un shell root sur le node master, lancez la commande suivante afin de lister les versions de *kubeadm* actuellement disponibles:

```
root@k8s-1:~# apt update && apt-cache policy kubeadm
kubeadm:
  Installed: 1.18.12-00
  Candidate: 1.19.4-00
  Version table:
     1.19.4-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
     1.19.3-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
     1.19.2-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
     1.19.1-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
     1.19.0-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
 *** 1.18.12-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
        100 /var/lib/dpkg/status
     1.18.10-00 500
        500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
...
```

Il est possible que vous obteniez un résultat différent, les mises à jour de Kubernetes étant relativement fréquentes. Nous utiliserons ici la version 1.19.4-00.


Utilisez la commande suivante afin de mettre à jour *kubeadm* sur le node master:

```
root@master:~# apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.19.4-00 && \
apt-mark hold kubeadm
```

### Passage du node en mode Drain

En utilisant la commande suivante depuis votre machine locale, passez le node master en *drain* de façon à ce que les Pods applicatifs (si il y en a) soient re-schédulés sur les autres nodes du cluster.

```
$ kubectl drain k8s-1 --ignore-daemonsets
node/k8s-1 cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-proxy-ccfxj, kube-system/weave-net-txz8m
node/k8s-1 drained
```

Depuis un shell root sur le node master, vous pouvez à présent lancer la simulation de la mise à jour avec la commande suivante:

```
root@k8s-1:~# kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.18.12
[upgrade/versions] kubeadm version: v1.19.4
[upgrade/versions] Latest stable version: v1.19.4
[upgrade/versions] Latest stable version: v1.19.4
[upgrade/versions] Latest version in the v1.18 series: v1.18.12
[upgrade/versions] Latest version in the v1.18 series: v1.18.12

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT        AVAILABLE
kubelet     3 x v1.18.12   v1.19.4

Upgrade to the latest stable version:

COMPONENT                 CURRENT    AVAILABLE
kube-apiserver            v1.18.12   v1.19.4
kube-controller-manager   v1.18.12   v1.19.4
kube-scheduler            v1.18.12   v1.19.4
kube-proxy                v1.18.12   v1.19.4
CoreDNS                   1.6.7      1.7.0
etcd                      3.4.3-0    3.4.13-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.19.4

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
```

Si vous avez un résultat similaire à celui ci-dessus, c'est que la simulation de mise à jour s'est déroulée correctement. Vous pouvez alors lancer la mise à jour avec la commande suivante:

```
root@k8s-1:~# kubeadm upgrade apply v1.19.4
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade/version] You have chosen to change the cluster version to "v1.19.4"
[upgrade/versions] Cluster version: v1.18.12
[upgrade/versions] kubeadm version: v1.19.4
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[upgrade/prepull] Pulling images required for setting up a Kubernetes cluster
[upgrade/prepull] This might take a minute or two, depending on the speed of your internet connection
[upgrade/prepull] You can also perform this action in beforehand using 'kubeadm config images pull'
...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.19.4". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

### Passage du node en mode Uncordon

Modifiez le node master de façon à le rendre de nouveau "schedulable".

```
$ kubectl uncordon k8s-1
node/k8s-1 uncordoned
```

Note: dans le cas d'un cluster avec plusieurs master, il faudrait également mettre à jour kubeadm sur les autres masters puis lancer la commande suivante sur chacun d'entres eux:

```
$ kubeadm upgrade NODE_IDENTIFIER
```

### Mise à jour de kubelet et kubectl

Depuis un shell sur le node master, utilisez la commande suivante afin de mettre à jour *kubelet* et *kubectl*:

```
root@k8s-1:~# apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.19.4-00 kubectl=1.19.4-00 && \
apt-mark hold kubelet kubectl
```

Redémarrez ensuite *kulelet*

```
root@k8s-1:~# systemctl restart kubelet
```

## Mise à jour des nodes workers

Effectuez les actions suivantes sur chacun des nodes worker (*k8s-2* et *k8s-3*). Les instructions suivantes détaillent les actions à effectuer sur le node k8s-2, il faudra ensuite faire la même chose sur le node k8s-3.

### Mise à jour de kubeadm

La commande suivante permet d'installer la version 1.19.4 du binaire *kubeadm*:

```
root@k8s-2:~# apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.19.4-00 && \
apt-mark hold kubeadm
```

Préparez le node pour le maintenance en la passant en mode *drain*, les Pods tournant sur le node seront reschédulés sur les autres nodes du cluster.

```
$ kubectl drain k8s-2 --ignore-daemonsets
```

### Mise à jour de la configuration de kubelet

Lancez la commande suivante afin de mettre à jour la configuration de *kubelet*.

```
root@k8s-2:~# kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
```

### Mise à jour de kubelet et kubectl

Mettez ensuite à jour les binaires *kubelet* et *kubectl* vers la version 1.19.4:

```
root@k8s-2:~# apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.19.4-00 kubectl=1.19.4-00 && \
apt-mark hold kubelet kubectl
```

Puis redémarrez *kubelet* à l'aide de la commande suivante:

```
root@k8s-2:~# systemctl restart kubelet
```

Vous pouvez ensuite rendre le node "schedulable":

```
$ kubectl uncordon k8s-2
```

Les nodes *k8s-1* et *k8s-2* sont maintenant à jour. Effectuez à présent l'ensemble de ces actions sur le node *k8s-3*.

## Test

Le cluster est maintenant disponible dans la version 1.19.4

```
$ kubectl get nodes
NAME    STATUS   ROLES    AGE   VERSION
k8s-1   Ready    master   12m   v1.19.4
k8s-2   Ready    <none>   12m   v1.19.4
k8s-3   Ready    <none>   12m   v1.19.4
```
