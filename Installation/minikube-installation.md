# Installation de minikube

Nous utiliserons souvent Minikube dans les démos et les exercices. Minikube est un packaging tout-en-un de Kubernetes qui tourne dans une machine virtuelle. Nous détaillons ci-dessous la procédure d'installation avec VirtualBox.

Note: si vous êtes sur Windows et que vous utilisez déjà l'hyperviseur HyperV, il faudra le désactiver pour que Minikube puisse lancer une VM sur VirtualBox. Une autre option serait de lancer minikube directement avec l'hyperviseur HyperV et non pas sur VirtualBox.

## 1. Installation de VirtualBox

Depuis le lien suivant, sélectionnez le binaire VirtualBox en fonction du système d'exploitation que vous utilisez: https://www.virtualbox.org/wiki/Downloads

Il vous suffira ensuite de suivre les instructions pour procéder à l'installation.

## 2. Installation de Kubectl

Le binaire kubectl est l'outils indispensable pour communiquer avec un cluster Kubernetes depuis la ligne de commande. Son installation est très bien documentée dans la documentation officielle que vous pouvez retrouver via le lien suivant: https://kubernetes.io/docs/tasks/tools/install-kubectl/

En fonction de votre environnement, vous trouverez les différentes options qui vous permettront d'installer kubectl

- si vous êtes sur macOS:

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/darwin/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur Linux

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur Windows

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/windows/amd64/kubectl.exe
```

note: si vous n'avez pas l'utilitaire curl vous pouvez télécharger kubectl v1.13.0 depuis ce https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/windows/amd64/kubectl.exe.

Afin d'avoir les utilitaires comme curl, je vous conseille d'utiliser Git for Windows (https://gitforwindows.org), vous aurez alors Git Bash, un shell très proche de celui que l'on trouve dans un environnement Linux.

Il vous faudra ensuite mettre kubectl.exe dans le PATH.

## 3. Installation de Minikube

La dernière étape est l'installation de Minikube. Depuis le lien suivant https://github.com/kubernetes/minikube/releases, vous trouverez la dernière release de Minikube et la procédure d'installation en fonction de votre environnement. 

- si vous êtes sur macOS:

```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.34.1/minikube-darwin-amd64
$ chmod +x minikube
$ sudo mv minikube /usr/local/bin/
```

- si vous êtes sur Linux:

```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.34.1/minikube-linux-amd64
$ chmod +x minikube
$ sudo mv minikube /usr/local/bin/
```

- si vous êtes sur Windows:

```
$ curl -Lo minikube.exe https://storage.googleapis.com/minikube/releases/v0.34.1/minikube-windows-amd64
```

Il faudra ensuite ajouter minikube.exe dans votre PATH.

## 4. Vérification

Une fois que ces éléments sont installés, lancez minikube puis vérifiez que kubectl parvient à se connecter au cluster. Pour cette dernière étape on peut par exemple essayer de lister les Pods qui tournent (nous reviendrons sur cette notion de Pods très prochainement).

- si vous êtes sur macOS ou Linux

```
$ minikube start
```

puis listez les Pods

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
