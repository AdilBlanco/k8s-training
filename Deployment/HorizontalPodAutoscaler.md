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

Avant de créer la ressource *HorizontalPodAutoscaler*, nous avons besoin de mettre en place le *metrics-server* qui sera en charge de récupérer les metrics de consommation des Pods (CPU / mémoire). Ces metrics seront ensuite utilisées par le *HorizontalPodAutoscaler* pour augmenter ou diminuer automatiquement le nombre de Pods du Deployment en fonction de la charge.

- Si vous utilisez Minikube

le lancement du *metrics-server* peut se faire simplement avec la commande suivante:

```
$ minikube addons enable metrics-server
```

- Si vous n'utilisez pas Minikube

il est nécessaire de déployer le process *metrics-server* avec la commande suivante:

```
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```

:fire: Quelques cas particuliers:

### DigitalOcean

Si vous utilisez un cluster managé sur DigitalOcean il est nécessaire de modifier le deployment du metrics-server de façon à ce qu'il contienne la spécification suivante (ajout de la clé *command*):

```
...
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.6
        command:
          - /metrics-server
          - --logtostderr
          - --kubelet-insecure-tls=true
          - --kubelet-preferred-address-types=InternalIP
          - --v=2
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
...
```

Vous pourrez ajouter cette clé *command* en éditant le Deployment avec la commande suivante:

```
$ kubectl edit deploy/metrics-server -n kube-system
```

### Docker Desktop

Si vous utilisez un cluster créé avec Docker Desktop, il est nécessaire de modifier le deployment du metrics-server de façon à ce qu'il contienne la spécification suivante (ajout de l'option *--kubelet-insecure-tls* sous la clé *arg*)

```
...
spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-insecure-tls
        image: k8s.gcr.io/metrics-server-amd64:v0.3.6
...
```

Vous pourrez ajouter cette option en éditant le Deployment avec la commande suivante:

```
$ kubectl edit deploy/metrics-server -n kube-system
```

## Accès aux métrics

Au bout de quelques dizaines de secondes, le metrics-server commencera à collecter des metrics. Vous pouvez le vérifier avec la commande suivante qui récupère la consommation CPU et mémoire des nodes:

- Exemple avec un cluster constitué de plusieurs nodes:

```
$ kubectl top nodes
NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
workers-bmp2   60m          3%     746Mi           24%
workers-bmpp   52m          2%     899Mi           28%
workers-bmps   58m          2%     821Mi           26%
```

- Exemple avec un cluster créé avec Docker Desktop:

```
NAME             CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
docker-desktop   309m         7%     1143Mi          60%
```

## Création de la ressource HorizontalPodAutoscaler

Nous allons maintenant définir un *HorizontalPodAutoscaler* qui sera en charge de modifier le nombre de réplicas du Deployment si celui-ci utilise plus de 10% du CPU qui lui est alloué (10% est une valeur très faible choisit simplement pour cet exemple, dans un contexte de production, cette valeur sera plus élevée).

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
  targetCPUUtilizationPercentage: 10
```

Créez ensuite cette ressource avec la commande suivante:

```
$ kubectl apply -f hpa.yaml
```

Vérifiez que l'HorizontalPodAutoscaler a été créé correctement:

```
$ kubectl get hpa
NAME   REFERENCE        TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
www    Deployment/www   <unknown>/10%   1         10        1          13s
```

## Test

Pour envoyer un grand nombre de requête sur le service, nous allons utiliser l'outils [Apache Bench](http://httpd.apache.org/docs/current/programs/ab.html).

Utilisez la commande suivante en remplaçant *NODE_IP* par l'adresse IP de l'un des nodes de votre cluster (vous pouvez obtenir les IPs des nodes à l'aide de `$ kubectl get nodes -o wide`):

Note: assurez vous d'avoir installer Docker sur votre machine au préalable

```
$ docker run lucj/ab -n 100000 -c 50 http://NODE_IP:30100/
```

Depuis un autre terminal, observez l'évolution de la consommation du CPU et l'augmentation du nombre de réplicas (cela peux prendre quelques minutes)

```
$ kubectl get -w hpa
NAME   REFERENCE        TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
www    Deployment/www   48%/10%   1         10        3          5m24s
```

Note: l'option *-w* (watch)  met à jour régulièrement le résultat de la commande.

Arrêtez l'envoi de requêtes et observez que le nombre de réplicas diminue. Cette phase sera cependant un peu plus longue que celle observée lors de l'augmentation du nombre de réplicas.

## Cleanup

Supprimez le *Deployment* et le *HorizontalPodAutoscaler* avec les commandes suivantes:

```
$ kubectl delete -f deploy.yaml
$ kubectl delete -f hpa.yaml
```

Supprimez ensuite le metrics-server avec la commande suivante:

```
$ kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```
