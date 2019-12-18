Nous utiliserons souvent Minikube dans les démos et les exercices. Minikube est un packaging tout-en-un de Kubernetes qui tourne dans une machine virtuelle. Nous détaillons ci-dessous la procédure d'installation avec VirtualBox.

Note: si vous êtes sur Windows et que vous utilisez déjà l'hyperviseur HyperV, il faudra le désactiver pour que Minikube puisse lancer une VM sur VirtualBox. Une autre option serait de lancer minikube directement avec l'hyperviseur HyperV et non pas sur VirtualBox.

## 1. Installation d'un hyperviseur

Installez un hyperviseur sur votre machine locale. En fonction de l'OS, différents hyperviseurs sont supportés:

- si vous êtes sur macOS, vous pouvez installer l'un des hyperviseurs suivants:

  * VirtualBox (https://www.virtualbox.org/wiki/Downloads)
  * VMware Fusion (https://www.vmware.com/products/fusion)
  * HyperKit (https://github.com/moby/hyperkit)

- si vous êtes sur Linux, vous pouvez installer l'un des hyperviseurs suivants:

  * VirtualBox (https://www.virtualbox.org/wiki/Downloads)
  * KVM (http://www.linux-kvm.org/)

  Note: Minikube supporte également une option --vm-driver=none qui exécute les composants Kubernetes sur la machine hôte et non dans une VM. L’utilisation de ce pilote nécessite Docker et un environnement Linux mais pas d'hyperviseur.

- si vous êtes sur Windows, vous pouvez installer l'un des hyperviseurs suivants:

  * VirtualBox (https://www.virtualbox.org/wiki/Downloads)
  * Hyper-V (https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/quick_start/walkthrough_install)


## 2. Installation de Minikube

La dernière étape est l'installation de Minikube. Depuis le lien suivant https://github.com/kubernetes/minikube/releases, vous trouverez la dernière release de Minikube et la procédure d'installation en fonction de votre environnement. 

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

## 3. Vérification

Une fois que ces éléments sont installés, lancez minikube puis vérifiez que kubectl parvient à se connecter au cluster. Pour cette dernière étape on peut par exemple essayer de lister les Pods qui tournent (nous reviendrons sur cette notion de Pods très prochainement).

- si vous êtes sur macOS ou Linux

```
$ minikube start
```

Listez ensuite les Pods

```
$ kubectl get pods
No resources found.
```

- si vous êtes sur Windows

```
$ ./minikube.exe start
```

puis listez les Pods

```
$ ./kubectl.exe get pods
No resources found.
```

Note: le résultat obtenu par la dernière commande ("No resources found.") est correct et montre que kubectl a bien réussi à se connecter au cluster Kubernetes, il n'a cependant pas trouvé de Pod actifs car nous n'en n'avons pas encore lancé.
