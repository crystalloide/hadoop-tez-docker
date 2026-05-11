# Cluster Hadoop 3.4.2 + Apache Tez 0.10.5

## Structure du projet

```
.
├── Dockerfile                          ← Image custom (Hadoop + Tez pré-installé)
├── docker-compose-cluster-latest.yml  ← Cluster complet avec init automatique
├── config                              ← Variables d'env → XML Hadoop (mapreduce.framework.name=yarn-tez)
├── tez-site.xml                        ← Configuration Tez (intégrée à l'image)
├── init-tez.sh                         ← Script one-shot : upload du tarball Tez sur HDFS
└── test.sh                             ← Votre script de test (monté dans resourcemanager)
```
### Hadoop : installation lancement et utilisation dans gitpod

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/crystalloide/hadoop-tez-docker)

##### https://github.com/crystalloide/Hadoop-docker

Projet 2026 
________________________________________________________________________________________________

#### Apache Hadoop

    Apache Hadoop est un framework qui permet le traitement distribué de grands ensembles de données sur des clusters d'ordinateurs,
    à l'aide de modèles de programmation simples. 
    
    Il est conçu pour passer d'un seul serveur à des milliers de machines, chacune offrant calcul et stockage en local. 
    
    Plutôt que de s'appuyer sur du matériel pour offrir une haute disponibilité, la bibliothèque elle-même est conçue pour détecter 
    et gérer les pannes au niveau de la couche application, 
    fournissant ainsi un service hautement disponible au-dessus d'un cluster d'ordinateurs, dont chacun peut être sujet à des pannes.

#### Démarrage rapide
    Un cluster Hadoop peut être créé en extrayant l'image Docker appropriée et en spécifiant les configurations requises.

##### Sous Linux : clonage du projet : 
```sh
cd ~
sudo rm -Rf hadoop-tez-docker

git clone https://github.com/crystalloide/hadoop-tez-docker

cd hadoop-tez-docker

```
    
## Démarrage

```bash
# 1. Construire l'image et démarrer le cluster
docker compose -f docker-compose-cluster-latest.yml up --build
```

```bash
# 2. Suivre les logs de l'init Tez
docker compose -f docker-compose-cluster-latest.yml logs -f tez-init
```

À la fin de `tez-init`, vous devriez voir :
```
Tez-Init : TERMINÉ avec succès !
Le cluster Hadoop est prêt à exécuter des jobs via Tez.
```

## Vérifier l'installation

```bash
# Vérifier que le tarball est bien sur HDFS
docker exec namenode hdfs dfs -ls /apps/tez/

# Vérifier la conf MapReduce (doit afficher "yarn-tez")
docker exec namenode hdfs getconf -confKey mapreduce.framework.name
```


## Lancer un job MapReduce via Tez

```bash
docker exec -it namenode bash

# Exemple : WordCount via Tez
hdfs dfs -mkdir -p /input
echo "hello world hello tez" | hdfs dfs -put - /input/test.txt

yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
    wordcount /input /output
```

Le job sera automatiquement exécuté par Tez grâce à `mapreduce.framework.name=yarn-tez`.

## IHM Web

| Service         | URL                        |
|-----------------|----------------------------|
| NameNode HDFS   | http://localhost:9870       |
| ResourceManager | http://localhost:8088       |

## Comment ça fonctionne

1. **Build** : le `Dockerfile` télécharge Tez depuis `archive.apache.org`, l'extrait
   dans `/opt/tez/` et ajoute les jars au `HADOOP_CLASSPATH` via `hadoop-env.sh`.
2. **Config** : `tez-site.xml` est copié dans l'image à `/opt/hadoop/etc/hadoop/`.
   Le fichier `config` positionne `mapreduce.framework.name=yarn-tez`.
3. **Init** : le service `tez-init` attend que le NameNode sorte du safe mode
   (healthcheck Docker), puis uploade `/opt/tez/tez.tar.gz` sur HDFS à
   `/apps/tez/tez.tar.gz` (opération idempotente). Le service s'arrête ensuite.
