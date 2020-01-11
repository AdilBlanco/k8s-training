Minikube est une solution de cluster en local qui provisionne une machine virtuelle et lance les processus de Kubernetes à l'intér!eur de celle-ci.

## 1. Installation d'un hyperviseur

Installez un hyperviseur sur votre machine locale. En fonction de l'OS, différents hyperviseurs sont supportés:

- si vous êtes sur macOS, vous pouvez utiliser l'un des hyperviseurs suivants:

  * VirtualBox (https://www.virtualbox.org/wiki/Downloads)
  * VMware Fusion (https://www.vmware.com/products/fusion)
  * HyperKit (https://github.com/moby/hyperkit)

- si vous êtes sur Linux, vous pouvez utiliser l'un des hyperviseurs suivants:

  * VirtualBox (https://www.virtualbox.org/wiki/Downloads)
  * KVM (http://www.linux-kvm.org/)

  Note: Minikube supporte également une option --vm-driver=none qui exécute les composants Kubernetes sur la machine hôte et non dans une VM. L’utilisation de ce pilote nécessite Docker et un environnement Linux mais pas d'hyperviseur.

- si vous êtes sur Windows, vous pouvez utiliser l'un des hyperviseurs suivants:

  * VirtualBox (https://www.virtualbox.org/wiki/Downloads)
  * Hyper-V (https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/quick_start/walkthrough_install)


## 2. Installation de Minikube

Depuis le lien suivant https://github.com/kubernetes/minikube/releases, vous trouverez la dernière release de Minikube et la procédure d'installation en fonction de votre environnement. 

- si vous êtes sur macOS:

```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
$ chmod +x minikube
$ sudo mv minikube /usr/local/bin/
```

- si vous êtes sur Linux:

```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
$ chmod +x minikube
$ sudo mv minikube /usr/local/bin/
```

- si vous êtes sur Windows:

```
$ curl -Lo minikube.exe https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64
```

Il faudra ensuite ajouter minikube.exe dans votre PATH.

## 3. Lancement

Lancez ensuite minikube en utilisant la commande correspondant à votre système d'exploitation:

- si vous êtes sur macOS ou Linux

```
$ minikube start
```

- si vous êtes sur Windows

```
$ ./minikube.exe start
```

## 4. Accès au cluster

Assurez-vous d'avoir installé le binaire *kubectl* (cf exercice précédent), celui-ci est indispensable pour communiquer avec un cluster Kubernetes depuis la ligne de commande.

Lancez ensuite la commande suivante afin de lister les nodes du cluster:

```
$ kublectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
minikube   Ready    master   24m   v1.17.0
```

Le résultat de cette commande montre que kubectl a bien réussi à se connecter au cluster, celui-ci ne comportant qu'un seul node.
