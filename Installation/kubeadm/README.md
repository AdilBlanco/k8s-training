Mise en place d'un cluster avec kubeadm

Dans cet exercice, vous allez choisir l'une des options suivantes pour mettre en place un cluster Kubernetes composé de 3 VMs.
- en local sur VirtualBox avec Vagrant et Ansible
- sur le cloud provider DigitalOcean avec Terraform et Ansible
- sur le cloud provider Exoscale avec Terraform et Ansible

Note: l'utilisation d'un cloud provider (DigitalOcean ou Exoscale) nécessite la création d'un compte au préalable et du crédit de quelques euros afin de pouvoir créer des machines virtuelles sur l'infrastructure cible.

# Prérequis

## Clone du repository

Commencez par cloner le répertoire contenant les exercices:

```
$ git clone https://gitlab.com/lucj/k8s-exercices
```

## Installation de Kubectl

Le binaire kubectl est l'outils indispensable pour communiquer avec un cluster Kubernetes depuis la ligne de commande. Son installation est très bien documentée dans la documentation officielle que vous pouvez retrouver via le lien suivant: https://kubernetes.io/docs/tasks/tools/install-kubectl/

En fonction de votre environnement, vous trouverez les différentes options qui vous permettront d'installer kubectl

- si vous êtes sur macOS:

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/darwin/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur Linux

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

- si vous êtes sur Windows

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/windows/amd64/kubectl.exe
```

note: si vous n'avez pas l'utilitaire curl vous pouvez télécharger kubectl v1.14.0 depuis ce https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/windows/amd64/kubectl.exe.

Afin d'avoir les utilitaires comme curl, je vous conseille d'utiliser Git for Windows (https://gitforwindows.org), vous aurez alors Git Bash, un shell très proche de celui que l'on trouve dans un environnement Linux.

Il vous faudra ensuite mettre kubectl.exe dans le PATH.

# Provisionning

## 1ère option: VirtualBox

### Prérequis

Assurez-vous d'avoir [VirtualBox](https://www.virtualbox.org/) et [Vagrant](https://www.vagrantup.com/) installé sur votre machine.

### Fichier de configuration

Dans le répertoire *Installation/kubeadm/provisionning/Vagrant/*, vous trouverez le fichier *Vagrantfile* contenant les instructions suivantes:

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 1
  end

  nodes_number = 3
  (1..nodes_number).each do |i|
    hostname = "node-#{i}"
    ip = "192.168.33.#{9+i}"
    config.vm.define hostname do |node|
      node.vm.hostname = hostname
      node.vm.box = "ubuntu/bionic64"
      node.vm.network "private_network", ip: ip
    end
  end
end
```

### Création des machines virtuelles

Toujours depuis ce répertoire, lancez le provisionning des 3 machines virtuelles avec la commande suivante:

```
$ vagrant up
````

Vous pouvez maintenant passer à l'étape de configuration.

## 2nd option: DigitalOcean

### Prérequis

Assurez-vous d'avoir [Terraform](https://terraform.io) installé sur votre machine (il s'agit d'un binaire à télécharger et à mettre dans votre PATH).

Depuis l'interface de [DigitalOcean](https://digitalocean.com), créez un compte et récupérer le token permettant d'utiliser l'API.

### Création des machines virtuelles

Depuis le répertoire *Installation/kubeadm/provisionning/DigitalOcean*, lancez la commande suivante afin d'initialisé le provider (afin que Terraform puisse communiquer avec l'API de DigitalOcean).

```
$ terraform init
```

Lancez ensuite la commande suivante afin de tester la configuration:

```
$ terraform plan
```

Notes:
- cette commande dialogue avec l'API de DigitalOcean et s'assure que les éléments fournit sont corrects, elle ne va cependant pas jusqu'à la création des ressources
- vous devrez fournir le token récupéré à l'étape précédente

Si tout est ok, lancez la commande suivante pour créer les ressources

```
$ terraform apply
```

Une fois les VMs provisionnées, vous pouvez passer à l'étape de configuration.

## 3ème option: Exoscale

### Prérequis

1. Assurez-vous d'avoir [Terraform](https://terraform.io) installé sur votre machine (il s'agit d'un binaire à télécharger et à mettre dans votre PATH).

2. Depuis l'interface de [Exoscale](https://exoscale.com), créez un compte et récupérer la clé et le secret permettant d'utiliser l'API.

3. Dans le répertoire *Installation/kubeadm/provisionning/Exoscale*, créez le folder *.terraform/plugins/(darwin|linux|windows)_amd64/* et placez y le provider Exoscale téléchargé depuis [https://github.com/exoscale/terraform-provider-exoscale/releases](https://github.com/exoscale/terraform-provider-exoscale/releases).

### Création des machines virtuelles

Depuis le répertoire *Installation/kubeadm/provisionning/Exoscale*, lancez la commande suivante afin d'initialiser le provider (afin que Terraform puisse communiquer avec l'API de Exoscale).

```
$ terraform init
```

Lancez ensuite la commande suivante afin de tester la configuration:

```
$ terraform plan
```

Notes:
- cette commande dialogue avec l'API de DigitalOcean et s'assure que les éléments fournit sont corrects, elle ne va cependant pas jusqu'à la création des ressources
- vous devrez fournir le token récupéré à l'étape précédente

Si tout est ok, lancez la commande suivante pour créer les ressources

```
$ terraform apply
```

Une fois les VMs provisionnées, vous pouvez passer à l'étape de configuration.

# Configuration

## Prérequis

Assurez-vous que [Ansible](https://www.ansible.com/) est installé sur votre machine.

## Spécification du provider

Depuis le folder *configuration*, exportez le provider que vous avez utilisé précédemment (VirtualBox, DigitalOcean ou Exoscale):

```
export PROVIDER="DigitalOcean OU Exoscale OU VirtualBox"
```

## Configuration des VMs

Toujours depuis le folder *configuration*, lancez les commandes suivantes afin d'installer sur chaque VM les éléments nécessaire pour mettre en place un cluster Kubernetes.

```
$ ansible-playbook -i inventories/$PROVIDER/inventory.tpl -u root pre-install.yml
$ ansible-playbook -i inventories/$PROVIDER/inventory.tpl -u root -t daemon deploy.yml
$ ansible-playbook -i inventories/$PROVIDER/inventory.tpl -u root -t kube deploy.yml
```

# Mise en place d'un cluster Kubernetes avec *kubeadm*

## Initialisation

Sur le *node-1*, lancez la commande suivante:

```
$ kubeadm init
````

## Ajout de nodes

La mise en place de l'ensemble des composants du master prendra quelques minutes. A la fin vous obtiendrez la commande à lancez depuis les autres VMs pour les ajouter au cluster.
Copiez cette commande et lancez la depuis *node-2* et *node-3*.

## Récupération du context

Afin de pouvoir dialoguer avec le cluster que vous venez de mettre en place, il est nécessaire de récupérer la configuration de celui-ci. Utilisez pour cela les commandes suivantes.

```
$ scp root@MASTER_IP:/etc/kubernetes/admin.conf $PROVIDER-kube-config
$ sudo chown $(id -u):$(id -g) $PROVIDER-kube-config
$ export KUBECONFIG=$PROVIDER-kube-config
```

# Install network addon

```
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

# Check cluster nodes

```
$ kubectl cluster-info
$ kubectl get nodes
```
