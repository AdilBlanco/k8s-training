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
        - image: nginx:1.14-alpine
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

## Metrics server

Afin de pouvoir récupérer les metrics des containers, il est nécessaire de déployer le process *metrics-server* avec la commande suivante:

```
$ git clone https://github.com/kubernetes-incubator/metrics-server.git
$ cd metrics-server
$ kubectl apply -f deploy/1.8+/
```

Note: si vous utilisez Minikube, le lancement du *metrics-server* utilisez la commande suivante:

```
$ minikube addons enable metrics-server
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
