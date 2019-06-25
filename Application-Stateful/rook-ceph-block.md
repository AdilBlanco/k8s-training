Dans cette mise en pratique, nous allons déployer **Rook** et utiliser du block storage,  via **Ceph**, pour persister une base **MongoDB**.

## Déploiement de rook

Vous allez commencer par récupérer le repository *git* du projet et vous positionner dans la branche correspondant à la release 1.0:

```
$ git clone https://github.com/rook/rook.git
$ cd rook
$ git checkout release-1.0
$ cd cluster/examples/kubernetes/ceph
```

Utilisez ensuite les commandes suivantes pour déployer l'opérateur Rook et ses dépendances:

```
$ kubectl create -f common.yaml
$ kubectl create -f operator.yaml
```

Vérifiez que toutes les ressources ont été créées correctement dans le namespace *rook-ceph*, vous devriez rapidement obtenir un résultat similaire à celui ci-dessous:


```
$ kubectl get pod -n rook-ceph
NAME                                  READY   STATUS    RESTARTS   AGE
rook-ceph-agent-45wlx                 1/1     Running   0          3m56s
rook-ceph-agent-tdhwv                 1/1     Running   0          3m56s
rook-ceph-agent-xwpbg                 1/1     Running   0          3m56s
rook-ceph-operator-765ff54667-t9vc8   1/1     Running   0          4m20s
rook-discover-29pf8                   1/1     Running   0          3m56s
rook-discover-5r49d                   1/1     Running   0          3m56s
rook-discover-6zssx                   1/1     Running   0          3m56s
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

```
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  cephVersion:
    image: ceph/ceph:v14.2.1-20190430
    allowUnsupported: false
  dataDirHostPath: /var/lib/rook
  mon:
    count: 3
    allowMultiplePerNode: false
  dashboard:
    enabled: true
  network:
    hostNetwork: false
  rbdMirroring:
    workers: 0
  annotations:
  resources:
  storage: # cluster level storage configuration and selection
    useAllNodes: true
    useAllDevices: false
    deviceFilter:
    location:
    config:
      storeType: filestore
    directories:
    - path: /var/lib/rook
```

Utilisez ensuite la commande suivante pour créer un cluster Ceph.

```
$ kubectl create -f cluster.yaml
```

Après quelques minutes, de nouveaux Pods, en charge du storage dans le cluster Ceph, seront déployés. Vérifiez le à l'aide de la commande suivante:

```
$ kubectl get pod -n rook-ceph
NAME                                           READY   STATUS      RESTARTS   AGE
rook-ceph-agent-45wlx                          1/1     Running     0          8m38s
rook-ceph-agent-tdhwv                          1/1     Running     0          8m38s
rook-ceph-agent-xwpbg                          1/1     Running     0          8m38s
rook-ceph-mgr-a-5bb54b889d-lzt5g               1/1     Running     0          76s
rook-ceph-mon-a-687b99fb8c-9qcnr               1/1     Running     0          2m28s
rook-ceph-mon-b-6cd94cd8d4-mkh6s               1/1     Running     0          2m20s
rook-ceph-mon-c-6b8f4dbc79-7p7pc               1/1     Running     0          111s

rook-ceph-operator-765ff54667-t9vc8            1/1     Running     0          9m2s
rook-ceph-osd-0-748468f68c-wq8tb               1/1     Running     0          45s
rook-ceph-osd-1-869b95b88b-mlsk7               1/1     Running     0          44s
rook-ceph-osd-2-77bfb5686c-zkbk6               1/1     Running     0          44s
rook-ceph-osd-prepare-worker-pool-fd4n-vvsng   0/2     Completed   0          52s
rook-ceph-osd-prepare-worker-pool-fdh9-g57x5   0/2     Completed   0          52s
rook-ceph-osd-prepare-worker-pool-fdhz-788fj   0/2     Completed   0          52s
rook-discover-29pf8                            1/1     Running     0          8m38s
rook-discover-5r49d                            1/1     Running     0          8m38s
rook-discover-6zssx
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
  fstype: xfs
reclaimPolicy: Retain
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
$ kubectl create -f pvc-rook-ceph-block.yaml
```

La création d'un PersistentVolumeClaim, utilisant la storageClass définie précédemment, déclenche la création d'un PersistentVolume de manière automatique. Le PVC est alors bindé au PV, comme vous pourrez le vérifier avec la commande suivante:

```
$ kubectl get pv,pvc
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
               STORAGECLASS      REASON   AGE
persistentvolume/pvc-94e87c13-77e0-11e9-9f29-2ec8fcc5238f   1Gi        RWO            Retain           Bound    default/mongo-pvc   rook-ceph-block            56s

NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORA
GECLASS      AGE
persistentvolumeclaim/mongo-pvc   Bound    pvc-94e87c13-77e0-11e9-9f29-2ec8fcc5238f   1Gi        RWO            rook-ceph-block   69s
```

## Création d'un Deployment MongoDB

Nous allons maintenant créer un Deployment utilisant le PVC précédent.

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

Copiez le contenu de cette spécification dans le fichier *mongo.yaml* et créez les ressources avec la commande suivante:

```
$ kubectl apply -f mongo.yaml
```

## Test de la connection

Avec un client Mongo (ligne de commande, Compass, ...) testez la connection. Les données écrites dans la base *Mongo* sont persistées (et répliquées) dans le cluster de stockage *Ceph* déployé dans Kubernetes.
