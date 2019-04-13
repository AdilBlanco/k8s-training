Dans cette mise en pratique, nous allons déployer **Rook** et utiliser du block storage,  via **Ceph**, pour persister une base **MongoDB**.

## Déploiement de rook

Utilisez les commandes suivantes pour déployer le Rook Operator sur le cluster.

```
$ git clone https://github.com/rook/rook.git
$ cd rook
$ git checkout release-0.9
$ cd cluster/examples/kubernetes/ceph
$ kubectl create -f operator.yaml
```

Vérifiez que toutes les ressources ont été créées correctement dans le namespace *rook-ceph-system*:

```
$ kubectl get all -n rook-ceph-system
```

Vous devriez rapidement obtenir un résultat proche de celui ci-dessous:

```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/rook-ceph-agent-8p75x                 1/1     Running   0          34s
pod/rook-ceph-agent-djllc                 1/1     Running   0          34s
pod/rook-ceph-agent-rjhss                 1/1     Running   0          34s
pod/rook-ceph-operator-5f4ff4d57d-7gkhf   1/1     Running   0          89s
pod/rook-discover-8jsz9                   1/1     Running   0          34s
pod/rook-discover-9slj5                   1/1     Running   0          34s
pod/rook-discover-sb7cj                   1/1     Running   0          34s

NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/rook-ceph-agent   3         3         3       3            3           <none>          35s
daemonset.apps/rook-discover     3         3         3       3            3           <none>          35s

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/rook-ceph-operator   1/1     1            1           90s

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/rook-ceph-operator-5f4ff4d57d   1         1         1       90s
```

## Création d'un cluster Ceph

Pré-requis:
- si vous utilisez Minikube, il faudra au préalable modifier la valeur de *dataDirHostPath* et la setter à */data/rook* dans le fichier cluster.yaml
- si vous utilisez le cloud provider *DigitalOcean*, il faudra remplacer *bluestore* par *filestore* dans la clé *storeType* dans le fichier cluster.yaml

```
storage:
  useAllNodes: true
  useAllDevices: false
  storeConfig:      
    storeType: filestore
```

Utilisez ensuite la commande suivante pour créer un cluster Ceph.

```
$ kubectl create -f cluster.yaml
```

## StorageClass

La spécification suivante définie une StorageClass permettant l'utilisation de stockage de type block dans le cluster Ceph.

```
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: rook-ceph-block
provisioner: ceph.rook.io/block
parameters:
  blockPool: replicapool
  clusterNamespace: rook-ceph
```

Copiez le contenu dans le fichier *sc-rook-ceph-block.yaml* et créez la StorageClass avec la commande :

```
$ kubectl create -f sc-rook-ceph-block.yaml
```

## Création d'un PVC

La spécification suivante définie un PersistentVolumeClaim utilisant la storageClass *rook-ceph-block* créée précédemment.

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-pvc
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

Copiez le contenu ci-dessus dans un fichier *pvc-rook-ceph-block.yaml* et créez la resource :

```
$ kubectl apply -f pvc-rook-ceph-block.yaml
```

## Création d'un Deployment MongoDB

La spécification suivante définie :
- un Deployment avec 1 Pod, celui-ci contenant un containeur basé sur MongoDB.
  Ce container utilise le PVC créé précédemment, et monté sur /data/db
- un Service de type NodePort exposant mongo sur le port 31017 des machines du cluster

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
spec:
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - image: mongo:4.0
        name: mongo
        ports:
        - containerPort: 27017
          name: mongo
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        persistentVolumeClaim:
          claimName: mongo-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
  labels:
    app: mongo
spec:
  selector:
    app: mongo
  type: NodePort
  ports:
    - port: 27017
      nodePort: 31017
```

Copiez le contenu de cette spécification dans le fichier *deploy-mongo.yaml* et créez les ressources avec la commande suivante:

```
$ kubectl apply -f deploy-mongo.yaml
```

## Test de la connection

Avec un client Mongo (ligne de commande, Compass, ...) testez la connection. Les données écrites dans la base *Mongo* sont persistées (et répliquées) dans le cluster de stockage *Ceph* déployé dans Kubernetes.
