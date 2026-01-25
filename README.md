# Kiloupabocou - Infrastructure Dockerisée

Ce projet contient l'infrastructure Docker complète pour déployer une application Symfony avec la stack ELK pour la visualisation des logs.

## Architecture

### Conteneurs Symfony

- **MySQL** : Base de données (port 3307 sur l'hôte, 3306 dans le conteneur)
- **PHP** : Conteneur PHP-FPM avec extensions Symfony
- **Nginx** : Serveur web (port 8080 sur l'hôte, 80 dans le conteneur)

### Stack ELK

- **ElasticSearch** : Moteur de recherche et stockage des logs (ports 9200, 9300)
- **LogStash** : Traitement et transformation des logs (port 5044)
- **Kibana** : Interface de visualisation (port 5601)
- **Filebeat** : Collecte des logs depuis les conteneurs

## Prérequis

- Docker (version 20.10 ou supérieure)
- Docker Compose (version 2.0 ou supérieure)

Vérifier l'installation :
```bash
docker --version
docker compose version
```

## Installation

### 1. Cloner le projet

```bash
git clone <url-du-repo>
cd W-ADS-300-LIL-3-1-kiloupabocou-3
```

### 2. Créer les fichiers de configuration

#### Fichier `.env` à la racine (pour Docker Compose)

Créez un fichier `.env` à la racine du projet avec les variables suivantes :

```bash
# Configuration MySQL
MYSQL_ROOT_PASSWORD=votre_mot_de_passe_root_securise
MYSQL_DATABASE=kiloupabocou_db
MYSQL_USER=kiloupabocou_user
MYSQL_PASSWORD=votre_mot_de_passe_securise

# Configuration Symfony (optionnel)
APP_ENV=dev
APP_SECRET=votre_secret_symfony
```

**⚠️ Important :** Le fichier `.env` est dans `.gitignore` et ne sera pas commité. Chaque développeur doit créer son propre fichier.

#### Fichier `symfony/.env` (pour Symfony)

Créez le fichier `symfony/.env` à partir du template :

```bash
cp symfony/env.template symfony/.env
```

Puis modifiez `symfony/.env` pour utiliser les mêmes valeurs que votre `.env` à la racine.

### 3. Construire les images Docker

```bash
docker compose build
```

### 4. Démarrer les conteneurs

```bash
docker compose up -d
```

### 5. Installer les dépendances Symfony

```bash
docker compose exec php composer install
```

### 6. Vérifier que tout fonctionne

```bash
# Vérifier l'état des conteneurs
docker compose ps

# Tester Symfony
curl http://localhost:8080

# Tester ElasticSearch
curl http://localhost:9200

# Tester Kibana
curl http://localhost:5601
```

## Configuration

### Base de données MySQL

Les identifiants sont définis dans le fichier `.env` :

- **Root password** : Variable `MYSQL_ROOT_PASSWORD` dans `.env`
- **Database** : Variable `MYSQL_DATABASE` dans `.env` (par défaut : `kiloupabocou_db`)
- **User** : Variable `MYSQL_USER` dans `.env` (par défaut : `kiloupabocou_user`)
- **Password** : Variable `MYSQL_PASSWORD` dans `.env`

### Projet Symfony

Le projet Symfony est configuré pour utiliser MySQL via les variables d'environnement définies dans `.env`.

## Démarrage

1. **Démarrer tous les conteneurs** :

```bash
docker compose up -d
```

2. **Vérifier que tous les conteneurs sont en cours d'exécution** :

```bash
docker compose ps
```

3. **Accéder à l'application Symfony** :

   - URL : http://localhost:8080
   - Nom de domaine configuré : `kiloupabocou.local` (à ajouter dans `/etc/hosts`)

4. **Accéder à Kibana** :
   - URL : http://localhost:5601
   - Ou via Nginx : http://kibana.kiloupabocou.local (à ajouter dans `/etc/hosts`)

## Configuration des noms de domaine locaux

Pour utiliser les noms de domaine configurés, ajoutez ces lignes dans `/etc/hosts` :

```
127.0.0.1 kiloupabocou.local
127.0.0.1 kibana.kiloupabocou.local
```

## Volumes

Les données sont persistées dans les volumes Docker suivants :

- `mysql_data` : Données MySQL
- `php_logs` : Logs PHP
- `nginx_logs` : Logs Nginx
- `elasticsearch_data` : Données ElasticSearch

## Logs

Les logs sont collectés automatiquement par Filebeat et envoyés à LogStash, qui les traite et les envoie à ElasticSearch. Vous pouvez visualiser les logs dans Kibana.

### Index ElasticSearch

Les logs sont indexés avec le pattern : `kiloupabocou-logs-YYYY.MM.DD`

## Tests


### Tests manuels

#### 1. Vérifier que tous les conteneurs sont démarrés

```bash
docker compose ps
```

Tous les conteneurs doivent être en état "Up".

#### 2. Tester l'application Symfony

```bash
curl http://localhost:8080
```

Ou ouvrez dans votre navigateur : http://localhost:8080

Vous devriez voir : "Bienvenue sur Kiloupabocou !"

#### 3. Tester MySQL

```bash
# Charger les variables d'environnement
source .env

# Tester la connexion
docker compose exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES;" ${MYSQL_DATABASE}
```

Vous devriez voir la base de données dans la liste.

#### 4. Tester ElasticSearch

```bash
curl http://localhost:9200
```

Vous devriez recevoir une réponse JSON avec les informations d'ElasticSearch.

#### 5. Tester Kibana

Ouvrez dans votre navigateur : http://localhost:5601

Kibana devrait se charger (cela peut prendre quelques minutes au premier démarrage).

#### 6. Vérifier les logs dans ElasticSearch

```bash
# Lister les index de logs
curl http://localhost:9200/_cat/indices/kiloupabocou-logs-*?v

# Voir les logs récents
curl http://localhost:9200/kiloupabocou-logs-*/_search?pretty
```

#### 7. Générer des logs pour tester la collecte

```bash
# Accéder à l'application pour générer des logs Nginx
curl http://localhost:8080

# Voir les logs Nginx directement
docker compose exec nginx tail -f /var/log/nginx/access.log

# Voir les logs PHP
docker compose exec php tail -f /var/log/php/php_errors.log
```

## Commandes utiles

### Voir les logs d'un conteneur

```bash
docker compose logs -f [nom_du_conteneur]
```

### Arrêter tous les conteneurs

```bash
docker compose down
```

### Arrêter et supprimer les volumes

```bash
docker compose down -v
```

### Reconstruire les images

```bash
docker compose build
```

### Accéder au shell d'un conteneur

```bash
docker compose exec [nom_du_conteneur] /bin/sh
```

## Structure du projet

```
.
├── docker/
│   ├── php/
│   │   └── Dockerfile
│   ├── nginx/
│   │   └── conf.d/
│   │       ├── default.conf
│   │       └── kibana.conf
│   ├── logstash/
│   │   └── config/
│   │       ├── logstash.conf
│   │       └── pipeline.yml
│   └── filebeat/
│       └── filebeat.yml
├── symfony/
│   └── [votre projet Symfony]
├── docker-compose.yml
└── README.md
```

## Dépannage

### Les conteneurs ne démarrent pas

```bash
# Voir les logs d'erreur
docker compose logs

# Vérifier que le fichier .env existe
ls -la .env symfony/.env
```

### Erreur "variable not set"

Assurez-vous que le fichier `.env` existe à la racine et contient toutes les variables nécessaires.

### Port déjà utilisé

Si les ports 8080, 3307, 5601 ou 9200 sont déjà utilisés, modifiez-les dans `docker-compose.yml`.

### Symfony retourne 404

```bash
# Vider le cache Symfony
docker compose exec php php bin/console cache:clear

# Vérifier les routes
docker compose exec php php bin/console debug:router
```

## Notes importantes

- ⚠️ **Les fichiers `.env` sont dans `.gitignore`** - Chaque développeur doit créer ses propres fichiers `.env`
- Les mots de passe doivent être changés en production
- Le projet Symfony doit être installé dans le dossier `symfony/`
- Pour installer les dépendances Symfony, utilisez le conteneur PHP :
  ```bash
  docker compose exec php composer install
  ```
