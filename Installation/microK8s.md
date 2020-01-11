![Logo](./images/local/microk8s-logo.png)

MicroK8s est un outil axé sur la simplicité et l'expérience développeur. Il est notamment très adapté pour l'IoT, l'Edge computing, ... C'est une distribution légère, qui fournit de nombreux add-ons, composants pré-packagés donnant à Kubernetes des capacités supplémentaires: de la simple gestion DNS à l'apprentissage automatique avec Kubeflow.

![Kelsey](./images/local/microk8s-1.png)

Sur Windows, MacOS ou Linux, MicroK8s peut facilement être installé dans une machine virtuelle. Nous utiliserons [Multipass](https://multipass.run) un outils très pratique qui permet de lancer facilement des machines virtuelles Ubuntu sur Mac, Linux, ou Windows.

Note: l'installation de Multipass et l'illustration des différentes commandes ont été détaillées dans un exercice précédent, n'hésitez pas à vous reporter.


### 1. Création d'une VM Ubuntu

Utilisez la commande suivante pour créer une VM Ubuntu 18.04 avec Multipass, cela ne prendra que quelques dizaines de secondes:

```
$ multipass launch --name microk8s --mem 4G
```

### 2. Installation de microk8s dans la VM

Utilisez la commande suivante pour lancer l'installation de microk8s dans la VM que vous venez de provisionner:

```
$ multipass exec microk8s -- sudo snap install microk8s --classic
```

### 3. Fichier de configuration

Récupérez, sur votre machine locale, le fichier de configuration généré par microk8s:

```
$ multipass exec microk8s -- sudo microk8s.config > microk8s.yaml
```

Utilisez ensuite la commande suivante afin de positionner la variable d'environnement KUBECONFIG de façon à ce qu'elle pointe vers le path absolu du fichier de configuration:

```
$ export KUBECONFIG=$PWD/microk8s.yaml
```

### 4. Test

Le cluster est maintenant prêt à être utilisé:

```
$ kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
microk8s   Ready    <none>   12s   v1.17.0
```
