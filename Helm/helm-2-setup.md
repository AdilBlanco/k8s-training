## Mise en place de HELM 2

Afin de pouvoir installer des applications packagées dans le format définit par HELM, vous allez installer le client helm en local et initialiser le daemon tiller qui tournera dans un Pod dans votre cluster.

### 1. Installation du client

Téléchargez la dernière version de la version 2 du client *helm* depuis la page de releases suivante:

[https://github.com/helm/helm/releases](https://github.com/helm/helm/releases)

Copiez ensuite le binaire *helm* dans votre *PATH*.

### 2. Initialisation du daemon

Afin de lancez le daemon tiller avec des droits d'administration, nous allons créer un ServiceAccount et lui donner les droits de cluster-admin via un ClusterRoleBinding

```
$ kubectl apply -f - <<EOF
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
EOF
```

Vous pouvez ensuite lancer tiller en lui donnant les droits du ServiceAccount créé précédemment:

```
$ helm init --service-account tiller
```

Vérifiez que le Pod relatif au daemon tiller a bien été lancé.

```
$ kubectl get po -n kube-system -l name=tiller
NAME                             READY   STATUS    RESTARTS   AGE
tiller-deploy-5f4fc5bcc6-d4z62   1/1     Running   0          3m32s
```

Dans les exercices qui suivent, vous utiliserez helm pour déployer des applications et packager vos propres applications.

Note:
- la version 3 de Helm est disponible depuis fin 2019. Contrairement à la version 2 que vous venez de mettre en place, la version 3 ne nécessite pas le daemon Tiller côté serveur
- tous les charts ne sont pas encore migrés de façon à être déployés avec Helm 3 mais dans la plupart des cas cela ne devrait pas poser de problème. Pendant cette phase de migration, il peut être intéressant d'installer les 2 versions en local
