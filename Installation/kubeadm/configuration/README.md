Deployment of Kubernetes
------------------------

The playbooks perform the followning tasks:

* installation of docker daemon
* installation of binaries needed by kubernetes (kubeadm, kubectl, kubelet)

Inventory
---------

The inventory.ini file defines the host the server needs to be deployed on, for example:

```
[nodes]
k8s-node-1 ansible_host=178.128.43.239
k8s-node-2 ansible_host=209.97.142.174
k8s-node-3 ansible_host=206.189.112.198
```

Pre-installation
----------------

* Install python

```
$ ansible-playbook -i inventory.ini -u root pre-install.yml
```

Deployment
----------

* Install Docker daemon

```
$ ansible-playbook -i inventory.ini -u root -t daemon deploy.yml
```

* Install kubeadm

```
$ ansible-playbook -i inventory.ini -u root -t kubeadm deploy.yml
```
