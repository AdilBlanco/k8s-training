![Logo](./images/local/microk8s-logo.png)

MicroK8s est un outil axé sur la simplicité et l'expérience développeur. Il est notamment très adapté pour l'IoT, l'Edge computing, ... C'est une distribution légère, qui fournit de nombreux add-ons, composants pré-packagés donnant à Kubernetes des capacités supplémentaires: de la simple gestion DNS à l'apprentissage automatique avec Kubeflow.

![Kelsey](./images/local/microk8s-1.png)

Sur Windows, MacOS ou Linux, MicroK8s peut facilement être installé dans une machine virtuelle. Nous utiliserons [Multipass](https://multipass.run) un outils très pratique qui permet de lancer facilement des machines virtuelles Ubuntu sur Mac, Linux, ou Windows. En fonction de l'OS, Multipass pourra utiliser un hypervieur parmi Hyper-V, HyperKit, KVM, ou VirtualBox de manière native afin d'optimiser le temps de démarrage.

### 1. Installation de Multipass

Vous trouverez sur le site [https://multipass.run](https://multipass.run) la procédure d'installation de Multipass en fonction de votre OS ainsi que les commandes de bases (nous utiliserons certaines d'entre elles dans la suite).

![Multipass](./images/local/multipass.png)

### 2. Création d'une VM Ubuntu

Utilisez la commande suivante pour créer une VM Ubuntu 18.04 avec Multipass, cela ne prendra que quelques dizaines de secondes:

```
$ multipass launch --name microk8s --mem 4G
```

### 3. Installation de microk8s dans la VM

Utilisez la commande suivante pour lancer l'installation de microk8s dans la VM que vous venez de provisionner:

```
$ multipass exec microk8s -- sudo snap install microk8s --classic
```

### 4. Fichier de configuration

Récupérez, sur votre machine locale, le fichier de configuration généré par microk8s:

```
$ multipass exec microk8s -- sudo microk8s.config > microk8s.yaml
```

Utilisez ensuite la commande suivante afin de setter la variable d'environnement KUBECONFIG de façon à ce qu'elle pointe vers le path absolu du fichier de configuration récupéré précédemment:

```
$ export KUBECONFIG=$PWD/microk8s.yaml
```

### 5. Test

Le cluster est maintenant prêt à être utilisé:

```
$ kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   12s   v1.17.0
```
