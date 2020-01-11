## Mise en place de HELM 3

Afin de pouvoir installer des applications packagées dans le format définit par *Helm*, vous allez installer le client *helm* en local. Pour cela, téléchargez la dernière version de la version 3 du client *helm* depuis la page de releases suivante:

[https://github.com/helm/helm/releases](https://github.com/helm/helm/releases)

Copiez ensuite le binaire *helm* dans votre *PATH* en le renommant *helm3* de façon à éviter les conflits si vous souhaitez également utiliser un client *helm* dans la version 2

Vérifiez que le client est correctement installé:

```
$ helm3 version
version.BuildInfo{Version:"v3.0.1", GitCommit:"7c22ef9ce89e0ebeb7125ba2ebf7d421f3e82ffa", GitTreeState:"clean", GoVersion:"go1.13.4"}
```

Installez ensuite le repository officiel contenant les charts stable, aucun reposity n'étant configuré par défaut:

```
$ helm3 repo add stable https://kubernetes-charts.storage.googleapis.com
```

Notes:
- dans la version 2 de Helm, il était nécessaire de déployer un composant côté serveur, celui-ci étant responsable de la création de ressources. Helm 3 ne nécessite plus ce composant, seul le client est nécessaire, les ressources étant créés avec les droits définis dans le context utilisé
- tous les charts ne sont pas encore migrés de façon à être déployés avec Helm 3 mais dans la plupart des cas cela ne devrait pas poser de problème
