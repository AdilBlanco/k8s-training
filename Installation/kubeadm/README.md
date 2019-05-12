Mise en place d'un cluster avec kubeadm

Dans cet exercice, vous allez choisir l'une des options suivantes pour mettre en place un cluster Kubernetes composé de 3 VMs.
- en local sur VirtualBox avec Vagrant et Ansible
- sur le cloud provider DigitalOcean avec Terraform et Ansible
- sur le cloud provider Exoscale avec Terraform et Ansible

Note: l'utilisation d'un cloud provider (DigitalOcean ou Exoscale) nécessite la création d'un compte au préalable et de le créditer de quelques euros afin de pouvoir créer des machines virtuelles sur l'infrastructure cible.

# Prérequis

## Clone du repository

Commencez par cloner le répertoire contenant les exercices:

```
$ git clone https://gitlab.com/lucj/k8s-exercices
```

## Installation de Kubectl

Le binaire kubectl est l'outil indispensable pour communiquer avec un cluster Kubernetes depuis la ligne de commande. Son installation est très bien documentée dans la documentation officielle que vous pouvez retrouver via le lien suivant: https://kubernetes.io/docs/tasks/tools/install-kubectl/

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

Attention: n'utilisez pas cette option si la machine hôte n'à pas au moins 6 giga de RAM disponibles

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
      v.cpus = 2
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

  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /root/.ssh/authorized_keys

      # kubelet requires swap off
      swapoff -a
      # keep swap off after reboot
      sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
      # Use systemd as the default docker cgroup driver
      # sed -i '0,/ExecStart=/s//Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs"\\n&/' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    SHELL
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

Créez un compte depuis l'interface de [DigitalOcean](https://digitalocean.com).

Depuis le menu *API* générez un TOKEN. Une fois créé, copiez ce TOKEN, celui-ci vous sera demandé dans la suite afin de communiquer avec l'API de DigitalOcean et gérer les éléments de l'infrastructure depuis la ligne de commande.

![DO-token](./images/do_token.png)

Depuis le menu *Security* suivez la procédure pour ajouter une clé ssh. Une fois créée, copiez le *fingerprint* de cette clé, celui-ci vous sera demandé dans la suite afin de permettre une connection ssh sans mot de passe sur les machines qui seront provisionnées.

![DO-ssh](./images/do-ssh.png)

### Création des machines virtuelles

Placez vous dans le répertoire *Installation/kubeadm/provisionning/DigitalOcean*. Créez un fichier *terraform.tfvars* et placez-y les valeurs du TOKEN et du fingerprint de la clé ssh.

Exemple de fichier *terraform.tfvars*:

```
token = "3hvjy0qn8e3w7qm8xhwuoulnsyqath2okzvhvc9ywvsxz5ifbs32yyoair5bgfke8"
ssh_key = "a3:51:45:f1:a3:6e:cc:e3:32:1d:99:23:13:12:fe:f1"
```

Lancez ensuite la commande suivante afin d'initialiser le provider (afin que Terraform puisse communiquer avec l'API de DigitalOcean).

```
$ terraform init
```

Lancez ensuite la commande suivante afin de tester la configuration:

```
$ terraform plan
```

Notes:
- cette commande dialogue avec l'API de DigitalOcean et s'assure que les éléments fournit sont corrects, elle ne va cependant pas jusqu'à la création des ressources
- vous devrez fournir le token récupéré à l'étape précédente ainsi que le fingerprint de la clé ssh.

Si tout est ok, lancez la commande suivante pour créer les ressources

```
$ terraform apply
```

Une fois les VMs provisionnées, vous pouvez les visualiser dans l'interface web de DigitalOcean.

![Droplets](./images/droplets.png)

Vous pouvez alors passer à l'étape de configureration.

## 3ème option: Exoscale

### Prérequis

1. Assurez-vous d'avoir [Terraform](https://terraform.io) installé sur votre machine (il s'agit d'un binaire à télécharger et à mettre dans votre PATH).

2. Depuis l'interface de [Exoscale](https://exoscale.com), créez un compte et récupérer la clé et le secret permettant d'utiliser l'API.

3. Créez un couple clé privée / clé publique et upoadez la depuis l'interface web

4. Depuis le répertoire *Installation/kubeadm/provisionning/Exoscale*, installez le provisionner *Exoscale*:

- Si vous êtes sous macOS

```
$ mkdir -p .terraform/plugins/darwin_amd64/
$ curl -LO https://github.com/exoscale/terraform-provider-exoscale/releases/download/v0.10.0/terraform-provider-exoscale_0.10.0_darwin_amd64.tar.gz
$ tar -xvf terraform-provider-exoscale_0.10.0_darwin_amd64.tar.gz
$ mv terraform-provider-exoscale_v0.10.0 .terraform/plugins/darwin_amd64/
```

- Si vous êtes sous Linux

```
$ mkdir -p .terraform/plugins/linux_amd64/
$ curl -LO https://github.com/exoscale/terraform-provider-exoscale/releases/download/v0.10.0/terraform-provider-exoscale_0.10.0_linux_amd64.tar.gz
$ tar -xvf terraform-provider-exoscale_0.10.0_linux_amd64.tar.gz
$ mv terraform-provider-exoscale_v0.10.0 .terraform/plugins/linux_amd64/
```

- Si vous êtes sous Windows

```
$ mkdir -p .terraform/plugins/windows_amd64/
$ curl -LO https://github.com/exoscale/terraform-provider-exoscale/releases/download/v0.10.0/terraform-provider-exoscale_0.10.0_windows_amd64.tar.gz
$ tar -xvf terraform-provider-exoscale_0.10.0_windows_amd64.tar.gz
$ mv terraform-provider-exoscale_v0.10.0 .terraform/plugins/windows_amd64/
```

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
- cette commande dialogue avec l'API de Exoscale et s'assure que les éléments fournit sont corrects, elle ne va cependant pas jusqu'à la création des ressources
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
export PROVIDER="DigitalOcean / Exoscale / VirtualBox"
```

## Configuration des VMs

Toujours depuis le folder *configuration*, lancez les commandes suivantes afin d'installer sur chaque VM les pré-requis nécessaires à la mise en place d'un cluster Kubernetes:
- installation d'un runtime de container (Docker par défaut)
- installation de Kubeadm pour la création du cluster
- installation de Kubelet pour la supervision des containers

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

Listez alors les nodes du cluster, ils apparaitront avec le status *NotReady*.

```
$ kubectl get nodes
NAME     STATUS     ROLES    AGE     VERSION
node-1   NotReady   master   9m59s   v1.14.1
node-2   NotReady   <none>   76s     v1.14.1
node-3   NotReady   <none>   73s     v1.14.1
```

## Installation d'un addons pour le networking entre les Pods

La commande suivante permet d'installer les composants nécessaires pour la communication entre les Pods qui seront déployés sur le cluster.

```
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

Note: il y a plusieurs solutions de networking qui peuvent être utilisées, la solution envisagées ici est Weave Net. L'article suivant donne une bonne comparaison des solutions les plus utilisées: [objectif-libre.com/fr/blog/2018/07/05/comparatif-solutions-reseaux-kubernetes/](objectif-libre.com/fr/blog/2018/07/05/comparatif-solutions-reseaux-kubernetes/)

## Vérification de l'état de santé des nodes

Maintenant que la solution de netorking a été installée, les nodes sont dans l'état *Ready*.

```
$ kubectl get nodes
NAME     STATUS   ROLES    AGE     VERSION
node-1   Ready    master   11m     v1.14.1
node-2   Ready    <none>   2m40s   v1.14.1
node-3   Ready    <none>   2m37s   v1.14.1
```

Le cluster est prêt à être utilisé.
