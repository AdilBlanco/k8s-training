Dans cette mise en pratique, nous allons déployer **Rook** et utiliser du block storage,  via **Ceph**, pour persister une base **MongoDB**.

## Déploiement de rook

Utilisez les commandes suivantes pour déployer le Rook Operator sur le cluster.

```
git clone https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
kubectl create -f operator.yaml
```

## Création d'un cluster Ceph

Utilisez la commande suivante pour créer un cluster Ceph.

Note: si vous utilisez Minikube, il faudra au préalable modifier la valeur de **dataDirHostPath** et la setter à **/data/rook** dans le fichier cluster.yaml

```
kubectl create -f cluster.yaml
```

## StorageClass

La spécification suivante définie une StorageClass permettant l'utilisation de stockage de type block dans le cluster Ceph.

```
apiVersion: ceph.rook.io/v1beta1
kind: Pool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: rook-ceph-block
provisioner: ceph.rook.io/block
parameters:
  pool: replicapool
  clusterNamespace: rook-ceph
```

Copiez le contenu dans le fichier sc-rook-ceph-block.yaml et créez la StorageClass avec la commande :

```
kubectl create -f sc-rook-ceph-block.yaml
```

## Création d'un PVC

La spécification suivante définie un PersistentVolumeClaim utilisant la storageClass **rook-ceph-block** proposée par Rook.

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

Copiez le contenu ci-dessus dans un fichier pvc-rook-ceph-block.yaml et créez la resource :

```
kubectl apply -f pvc-rook-ceph-block.yaml
```

## Création d'un Deployment MongoDB

La spécification suivante définie :
- un Deployment avec 1 Pod, celui-ci contenant un containeur basé sur MongoDB.
  Ce container utilise le PVC créé précédemment, et monté sur /data/db
- un Service de type NodePort exposant mongo sur le port 31017 des machines du cluster

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: mongo
spec:
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

Copiez le contenu de cette spécification dans le fichier **deploy-mongo.yaml** et créez les ressources avec la commande suivante:

```
kubectl apply -f deploy-mongo.yaml
```

## Test de la connection

Avec un client Mongo (ligne de commande, Compass, ...) tester la connection.
