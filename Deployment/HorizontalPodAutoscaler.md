# HorizontalPodAutoscaler

Dans cet exercice, nous allons utiliser une ressource de type *HorizontalPodAutoscaler* afin d'augmenter, ou de diminuer, automatiquement le nombre de réplicas d'un Deployment en fonction de l'utilisation du CPU.

## Création d'un Deployment

Copiez le contenu suivant dans le fichier *deploy.yaml*.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: w3
spec:
  selector:
    matchLabels:
      app: w3
  replicas: 1
  template:
    metadata:
      labels:
        app: w3
    spec:
      containers:
        - image: nginx:1.16-alpine
          name: w3
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
  name: w3
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: w3
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
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Différentes ressources sont créées lors de l'installation du *metrics-server*, nous reviendrons sur celles-ci dans la suite du cours.

```
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
```

## Accès aux métrics

Au bout de quelques dizaines de secondes, le *metrics-server* commencera à collecter des metrics. Vous pouvez le vérifier avec la commande suivante qui récupère la consommation CPU et mémoire des nodes:

- Exemple avec un cluster constitué de plusieurs nodes:

```
$ kubectl top nodes
NAME            CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
workers-3ha6f   50m          2%     628Mi           20%
workers-3ha6x   92m          4%     644Mi           20%
workers-3ha6y   52m          2%     739Mi           23%
```

## Création de la ressource HorizontalPodAutoscaler

Nous allons maintenant définir un *HorizontalPodAutoscaler* qui sera en charge de modifier le nombre de réplicas du Deployment si celui-ci utilise plus de 10% du CPU qui lui est alloué (10% est une valeur très faible choisit simplement pour cet exemple, dans un contexte hors exercice, cette valeur sera plus élevée).

Dans le fichier *hpa.yaml*, copiez le contenu suivant:

```
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: w3
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 10
```

Créez ensuite cette ressource:

```
$ kubectl apply -f hpa.yaml
```

Vérifiez que l'HorizontalPodAutoscaler a été créé correctement:

```
$ kubectl get hpa
NAME   REFERENCE       TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
hpa    Deployment/w3   0%/10%   1         10        0          9s
```

Note: il est possible que pendant quelques secondes la valeur de la colonne *TARGET* soit "<unknown>/10%", le temps que le hpa puisse récupérer les métrics de consommation des ressources.

## Test

Pour envoyer un grand nombre de requête sur le service *w3*, nous allons utiliser l'outils [Apache Bench](http://httpd.apache.org/docs/current/programs/ab.html).

Avec la commande suivante, lancez le Pod *ab* dont le rôle est d'envoyer des requêtes sur le service *w3* depuis l'intérieur du cluster:


```
$ kubectl run ab --restart='Never' --image=lucj/ab -- -n 150000 -c 50 http://w3/
```

Vous pouvez suivre l'évolution du nombre de requêtes envoyées avec la commande suivante:

```
$ kubectl logs -f ab
```

Depuis un autre terminal, observez l'évolution de la consommation du CPU et l'augmentation du nombre de réplicas (cela peux prendre quelques minutes)

```
$ kubectl get -w hpa
NAME   REFERENCE       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa    Deployment/w3   0%/10%    1         10        1          3m45s
hpa    Deployment/w3   26%/10%   1         10        1          4m54s
hpa    Deployment/w3   26%/10%   1         10        3          5m10s
hpa    Deployment/w3   74%/10%   1         10        3          5m56s
hpa    Deployment/w3   74%/10%   1         10        6          6m11s
hpa    Deployment/w3   74%/10%   1         10        10         6m26s
hpa    Deployment/w3   25%/10%   1         10        10         6m57s
hpa    Deployment/w3   0%/10%    1         10        10         7m58s
hpa    Deployment/w3   0%/10%    1         10        10         12m
hpa    Deployment/w3   0%/10%    1         10        1          13m
```

Note: l'option *-w* (watch)  met à jour régulièrement le résultat de la commande.

Une fois que les requêtes sont toutes envoyées, le nombre de réplicas diminue. Cette phase sera cependant un peu plus longue que celle observée lors de l'augmentation du nombre de réplicas.

## Cleanup

Supprimez les différentes ressources créées dans cet exercice:

```
$ kubectl delete -f deploy.yaml -f svc.yaml -f hpa.yaml
$ kubectl delete pod ab
```

Supprimez également le metrics-server avec la commande suivante:

```
$ kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```