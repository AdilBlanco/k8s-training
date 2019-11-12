# Mise en place de HELM

Afin de pouvoir installer des applications packagées dans le format définit par HELM, vous allez installer le client *helm* en local et initialiser le daemon *tiller* qui tournera dans un Pod dans votre cluster.

## 1. Installation du client

Téléchargez le client *helm* depuis la page de releases suivante:

[https://github.com/helm/helm/releases](https://github.com/helm/helm/releases)

Copiez ensuite le binaire *helm* dans votre *PATH*.

## 2. Initialisation du daemon

Afin de lancez le daemon *tiller* avec des droits d'administration, nous allons créer un *ServiceAccount* et lui donner les droits de *cluster-admin* via un *ClusterRoleBinding*

Copiez la spécification ci-dessous dans un fichier *rbac.yaml*

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

puis créez ces différentes ressources:

```
$ kubectl apply -f rbac.yaml
```

Vous pouvez ensuite lancez *tiller* en lui donnant les droits du ServiceAccount créé précédemment:

```
$ helm init --service-account tiller
```

Vérifiez que le Pod relatif au daemon *tiller* a bien été lancé.

```
$ kubectl get po -n kube-system -l name=tiller
NAME                             READY   STATUS    RESTARTS   AGE
tiller-deploy-5f4fc5bcc6-d4z62   1/1     Running   0          3m32s
```

Dans les exercices qui suivent, vous utiliserez *helm* pour déployer des applications et packager vos propres applications.
