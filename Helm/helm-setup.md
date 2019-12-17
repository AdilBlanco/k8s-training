## Mise en place de HELM

Afin de pouvoir installer des applications packagées dans le format définit par *Helm*, vous allez installer le client *helm* en local/. Pour cela, téléchargez le client *helm* depuis la page de releases suivante:

[https://github.com/helm/helm/releases](https://github.com/helm/helm/releases)

Copiez ensuite le binaire *helm* dans votre *PATH*.

Note: dans la version 2 de Helm, il était nécessaire de déployer un composant côté serveur, celui-ci étant responsable de la création de ressources. Helm 3 ne nécessite plus ce composant, seul le client est nécessaire, les ressources étant créés avec les droits définis dans le context utilisé.

Vérifiez que le client est correctement installé:

```
$ helm version
version.BuildInfo{Version:"v3.0.1", GitCommit:"7c22ef9ce89e0ebeb7125ba2ebf7d421f3e82ffa", GitTreeState:"clean", GoVersion:"go1.13.4"}
```

Installez ensuite le repository officiel contenant les charts stable, aucun reposity n'étant configuré par défaut:

```
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com
```
