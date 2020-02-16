Dans cet exercice, nous allons mettre à jour un cluster Kubernetes depuis la version 1.16.4 vers la version 1.17.0

## Prérequis

Avoir accès à un cluster dans la version 1.16.4 créé avec *kubeadm*.

Si vous souhaitez créer un cluster local 1.16.4 rapidement, vous pouvez lancer les commandes suivantes qui utilise l'outils Multipass ([https://multipass.run](https://multipass.run)) présenté au début du cours.

```
$ curl -sfL https://files.techwhale.io/mpk8s.sh -o mpk8s.sh
$ ./mpk8s.sh -v 1.16.4-00
```

En quelques minutes vous aurez un cluster dans la version souhaitez que vous pourrez utiliser dans cet exercice.

```
$ export KUBECONFIG=$PWD/mpk8s.cfg

$ kubectl get nodes
NAME    STATUS   ROLES    AGE     VERSION
k8s-1   Ready    master   4m43s   v1.16.4
k8s-2   Ready    <none>   4m20s   v1.16.4
k8s-3   Ready    <none>   4m14s   v1.16.4
```

## Mise à jour du node master

Nous allons commencer par mettre à jour le node master.

### Mise à jour de kubeadm

Depuis un shell root sur le node master, lancez la commande suivante afin de lister les versions de *kubeadm* actuellement disponibles:

```
root@k8s-1:~# apt update && apt-cache policy kubeadm
kubeadm:
  Installed: 1.16.4-00
  Candidate: 1.17.0-00
  Version table:
     1.17.0-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
 *** 1.16.4-00 500
        500 https://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
        100 /var/lib/dpkg/status
...
```

Il est possible que vous obteniez un résultat différent, les mises à jour de Kubernetes étant relativement fréquentes. Nous utiliserons ici la version 1.17.0-00.


Utilisez la commande suivante afin de mettre à jour *kubeadm* sur le master:

```
root@master:~# apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.17.0-00 && \
apt-mark hold kubeadm
```

### Passage du node en mode Drain

En utilisant la commande suivante depuis votre machine locale, passez le node master en *drain* de façon à ce que les Pods applicatifs (si il y en a) soient re-schédulés sur les autres nodes du cluster.

```
$ kubectl drain k8s-1 --ignore-daemonsets
node/k8s-1 cordoned
evicting pod "coredns-5644d7b6d9-k75l9"
pod/coredns-5644d7b6d9-k75l9 evicted
node/k8s-1 evicted
```

Depuis un shell sur le node master, vous pouvez à présent lancer la simulation de la mise à jour avec la commande suivante:

Note: la variable d'environnement KUBECONFIG est positoionnée au préalable afin que le binaire *kubectl* présent sur le node master puisse communiquer avec le cluster local

```
root@k8s-1:~# export KUBECONFIG=/etc/kubernetes/admin.conf

root@k8s-1:~# kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.16.4
[upgrade/versions] kubeadm version: v1.17.0
[upgrade/versions] Latest stable version: v1.17.0
[upgrade/versions] Latest version in the v1.16 series: v1.16.4

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       AVAILABLE
Kubelet     3 x v1.16.4   v1.17.0

Upgrade to the latest stable version:

COMPONENT            CURRENT   AVAILABLE
API Server           v1.16.4   v1.17.0
Controller Manager   v1.16.4   v1.17.0
Scheduler            v1.16.4   v1.17.0
Kube Proxy           v1.16.4   v1.17.0
CoreDNS              1.6.2     1.6.5
Etcd                 3.3.15    3.4.3-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.17.0
```

Si vous avez un résultat similaire à celui ci-dessus, c'est que la simulation de mise à jour s'est passé correctement. Vous pouvez alors lancer la mise à jour avec la commande suivante:

```
root@k8s-1:~# kubeadm upgrade apply v1.17.0
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade/version] You have chosen to change the cluster version to "v1.17.0"
[upgrade/versions] Cluster version: v1.16.4
[upgrade/versions] kubeadm version: v1.17.0
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.17.0". Enjoy!
[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

### Passage du node en mode Uncordon

Modifiez le node master de façon à le rendre de nouveau "schedulable".

```
$ kubectl uncordon k8s-1
node/k8s-1 uncordoned
```

Note: dans le cas d'un cluster avec plusieurs master, il faudrait également mettre à jour les autres masters en lançant la commande suivante sur chacun d'entres eux:

```
$ kubeadm upgrade OTHER_MASTER_NODE
```

### Mise à jour de kubelet et kubectl

Depuis un shell sur le node master, utilisez la commande suivante afin de mettre à jour *kubelet* et *kubectl*:

```
root@k8s-1:~# apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.17.0-00 kubectl=1.17.0-00 && \
apt-mark hold kubelet kubectl
```

Redémarrez ensuite *kulelet*

```
root@k8s-1:~# systemctl restart kubelet
```

## Mise à jour des nodes workers

Effectuez les actions suivantes sur chacun des nodes worker (*k8s-2* et *k8s-3*)

### Mise à jour de kubeadm

La commande suivante permet d'installer la version 1.17.0 du binaire *kubeadm*:

```
root@k8s-2:~# apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.17.0-00 && \
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
[upgrade] Skipping phase. Not a control plane node.
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.17" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
```

### Mise à jour de kubelet et kubectl

Mettez ensuite à jour les binaires *kubelet* et *kubectl*:

```
root@k8s-2:~# apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.17.0-00 kubectl=1.17.0-00 && \
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

Le cluster est maintenant disponible dans la version 1.17.0

```
$ kubectl get nodes
NAME    STATUS   ROLES    AGE    VERSION
k8s-1   Ready    master   10m    v1.17.0
k8s-2   Ready    <none>   10m    v1.17.0
k8s-3   Ready    <none>   10m    v1.17.0
```
