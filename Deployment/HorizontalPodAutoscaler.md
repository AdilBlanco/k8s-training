# HorizontalPodAutoscaler

Dans cet exercice, nous allons utiliser une ressource de type *HorizontalPodAutoscaler* afin d'augmenter, ou de diminuer, automatiquement le nombre de réplicas d'un Deployment en fonction de l'utilisation du CPU.

## Création d'un Deployment

Copiez le contenu suivant dans le fichier *deploy.yaml*.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: www
spec:
  selector:
    matchLabels:
      app: www
  replicas: 1
  minReadySeconds: 15
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: www
    spec:
      containers:
        - image: nginx:1.16-alpine
          name: www
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 200m
```

Créez ensuite ce Deployment avec la commande suivante:

```
$ kubectl apply -f deploy.yaml
```

## Création d'un Service

Copiez le contenu suivant dans le fichier *svc.yaml*.

```
apiVersion: v1
kind: Service
metadata:
  name: www
spec:
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30100
  selector:
    app: www
```

Créez ensuite ce Service avec la commande suivante:

```
$ kubectl apply -f svc.yaml
```

## Installation du Metrics server

Avant de créer la ressource *HorizontalPodAutoscaler*, nous avons besoin de mettre en place le *metrics-server* qui sera en charge de récupérer les metrics de consommation des Pods (CPU / mémoire) des Pods. Ces metrics seront ensuite utilisées par le *HorizontalPodAutoscaler* pour augmenter ou diminuer automatiquement le nombre de Pods du Deployment.

- Si vous utilisez Minikube

le lancement du *metrics-server* peut se faire simplement avec la commande suivante:

```
$ minikube addons enable metrics-server
```

- Si vous n'utilisez pas Minikube

il est nécessaire de déployer le process *metrics-server* à partir du repository GitHub que vous pouvez cloner avec la commande suivante:

```
$ git clone https://github.com/kubernetes-incubator/metrics-server.git
$ cd metrics-server
```

Attention, à cause de l'issue https://github.com/kubernetes-incubator/metrics-server/issues/131, il faudra ensuite modifier le fichier *deploy/1.8+/metrics-server-deployment.yaml* en définissant la clé *command* et les 3 élements qui suivent:

```
...
      containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.4
        command:
        - /metrics-server
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP
        imagePullPolicy: Always
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp
```

Vous pourrez ensuite créer l'ensemble des ressources avec la commande suivante:

```
$ kubectl apply -f deploy/1.8+/
```

Au bout de quelques dizaines de secondes, le metrics-server commencera à collecter des metrics. Vous pouvez le vérifier avec la commande suivante qui récupère la consommation CPU et mémoire des nodes:

```
$ kubectl top nodes
NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
workers-bmp2   60m          3%     746Mi           24%
workers-bmpp   52m          2%     899Mi           28%
workers-bmps   58m          2%     821Mi           26%
```

## Création de la ressource HorizontalPodAutoscaler

Nous allons maintenant définir un *HorizontalPodAutoscaler* qui sera en charge de modifier le nombre de réplicas du Deployment si celui-ci utilise plus de 20% du CPU qui lui est alloué.

Dans le fichier *hpa.yaml*, copiez le contenu suivant:

```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: www
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: www
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 20
```


Créez ensuite cette ressource avec la commande suivante:

```
$ kubectl apply -f hpa.yaml
```

Vérifiez que l'HorizontalPodAutoscaler a été créé correctement:

```
$ kubectl get hpa
NAME   REFERENCE        TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
www    Deployment/www   <unknown>/20%   1         10        1          13s
```

## Test

Utilisez la commande suivante pour envoyer des requètes en continu sur le service, en remplaçant *NODE_IP* par l'adresse IP de l'une des machines de votre cluster.

```
$ while true;do curl -s NODE_IP:30100 > /dev/null; done
```

Note: vous pouvez également utiliser l'utilitaire [Apache Bench](http://httpd.apache.org/docs/current/programs/ab.html) pour envoyer des requêtes sur le service, par exemple avec la commande suivante:

```
$ ab -n 100000 -c 50 http://NODE_IP:30100/
```

Depuis un autre terminal, observez l'évolution de la consommation du CPU et l'augmentation du nombre de réplicas (cela peux prendre quelques minutes)

```
$ kubectl get -w hpa
NAME   REFERENCE        TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
www    Deployment/www   48%/20%   1         10        3          5m24s
```

Arrêtez l'envoi de requêtes et observez que le nombre de réplicas revient à la normale.

## Cleanup

Supprimez le *Deployment* et le *HorizontalPodAutoscaler* avec les commandes suivantes:

```
$ kubectl apply -f deploy.yaml
$ kubectl apply -f hpa.yaml
```

Placez-vous dans le répertoire *metrics-server* et supprimez les ressources associées avec la commande suivante:

```
$ kubectl delete -f deploy/1.8+/
```
