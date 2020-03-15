## Installation de Kubectl

Sur la machine locale, il est nécessaire d'installer le binaire kubectl. C'est l'outil indispensable pour communiquer avec un cluster Kubernetes depuis la ligne de commande.

Son installation est très simple:

- si vous êtes sur *Linux*, utilisez les commandes suivantes:

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur *macOS*, utilisez les commandes suivantes pour récupérer le binaire

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur *Windows*, récupérez le binaire avec la commande suivante

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/windows/amd64/kubectl.exe
```

note: si vous n'avez pas l'utilitaire curl vous pouvez télécharger kubectl v1.17.0 depuis ce https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/windows/amd64/kubectl.exe.

Afin d'avoir les utilitaires comme curl, je vous conseille d'utiliser Git for Windows (https://gitforwindows.org), vous aurez alors Git Bash, un shell très proche de celui que l'on trouve dans un environnement Linux.

Il vous faudra ensuite mettre kubectl.exe dans le PATH.
