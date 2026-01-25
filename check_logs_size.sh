#!/bin/bash

# Script pour vérifier la taille des logs et des données stockées

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "📊 Vérification de la taille des logs et données"
echo "================================================"
echo ""

# Charger les variables d'environnement depuis .env si disponible
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Vérifier si Docker est en cours d'exécution
if ! docker info &>/dev/null; then
    echo -e "${RED}⚠️  Docker n'est pas en cours d'exécution${NC}"
    exit 1
fi

# Vérifier si les conteneurs sont en cours d'exécution
if ! docker ps | grep -q kiloupabocou_mysql; then
    echo -e "${YELLOW}⚠️  Les conteneurs ne sont pas démarrés${NC}"
    echo "   Lancez : docker compose up -d"
    exit 1
fi

echo "1. Taille des logs Nginx :"
echo "--------------------------"
if docker exec kiloupabocou_nginx sh -c "du -sh /var/log/nginx/* 2>/dev/null | head -5"; then
    total_nginx=$(docker exec kiloupabocou_nginx sh -c "du -sh /var/log/nginx 2>/dev/null" | awk '{print $1}')
    echo -e "   ${GREEN}Total logs Nginx : $total_nginx${NC}"
else
    echo "   Aucun log trouvé"
fi
echo ""

echo "2. Taille des logs PHP :"
echo "------------------------"
if docker exec kiloupabocou_php sh -c "du -sh /var/log/php/* 2>/dev/null | head -5"; then
    total_php=$(docker exec kiloupabocou_php sh -c "du -sh /var/log/php 2>/dev/null" | awk '{print $1}')
    echo -e "   ${GREEN}Total logs PHP : $total_php${NC}"
else
    echo "   Aucun log trouvé"
fi
echo ""

echo "3. Taille de la base de données MySQL :"
echo "----------------------------------------"
if docker exec kiloupabocou_mysql mysql -u${MYSQL_USER:-root} -p${MYSQL_ROOT_PASSWORD} -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;" 2>/dev/null; then
    db_size=$(docker exec kiloupabocou_mysql mysql -u${MYSQL_USER:-root} -p${MYSQL_ROOT_PASSWORD} -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '${MYSQL_DATABASE:-kiloupabocou_db}';" 2>/dev/null | tail -1)
    echo -e "   ${GREEN}Taille de ${MYSQL_DATABASE:-kiloupabocou_db} : ${db_size} MB${NC}"
else
    echo "   Impossible de vérifier (besoin des variables d'environnement)"
fi
echo ""

echo "4. Taille des données ElasticSearch :"
echo "--------------------------------------"
if docker exec kiloupabocou_elasticsearch curl -s http://localhost:9200/_cat/indices/kiloupabocou-logs-*?v&h=index,store.size,docs.count 2>/dev/null | head -20; then
    # Calculer la taille totale en convertissant les unités (kb, mb, gb)
    es_info=$(docker exec kiloupabocou_elasticsearch curl -s "http://localhost:9200/_cat/indices/kiloupabocou-logs-*?v&h=index,store.size" 2>/dev/null)
    total_bytes=0
    while IFS= read -r line; do
        if [[ $line =~ ([0-9.]+)([kmg]b) ]]; then
            size=${BASH_REMATCH[1]}
            unit=${BASH_REMATCH[2]}
            case $unit in
                kb) total_bytes=$(echo "$total_bytes + $size * 1024" | bc -l 2>/dev/null || echo "$total_bytes") ;;
                mb) total_bytes=$(echo "$total_bytes + $size * 1024 * 1024" | bc -l 2>/dev/null || echo "$total_bytes") ;;
                gb) total_bytes=$(echo "$total_bytes + $size * 1024 * 1024 * 1024" | bc -l 2>/dev/null || echo "$total_bytes") ;;
            esac
        fi
    done <<< "$es_info"
    
    # Afficher la taille totale
    if command -v bc &> /dev/null && [ -n "$total_bytes" ]; then
        total_mb=$(echo "scale=2; $total_bytes / 1024 / 1024" | bc)
        total_gb=$(echo "scale=2; $total_bytes / 1024 / 1024 / 1024" | bc)
        if (( $(echo "$total_gb >= 1" | bc -l) )); then
            echo -e "   ${RED}⚠️  Taille totale des index : ${total_gb} GB${NC}"
        else
            echo -e "   ${GREEN}Taille totale des index : ${total_mb} MB${NC}"
        fi
    else
        echo -e "   ${YELLOW}⚠️  Utilisez la colonne 'store.size' ci-dessus pour voir les tailles${NC}"
    fi
else
    echo "   Impossible de vérifier"
fi
echo ""

echo "5. Taille du volume MySQL (sur disque) :"
echo "-----------------------------------------"
mysql_vol=$(docker volume inspect w-ads-300-lil-3-1-kiloupabocou-3_mysql_data --format '{{ .Mountpoint }}' 2>/dev/null)
if [ -n "$mysql_vol" ]; then
    echo "   Volume : $mysql_vol"
    echo "   (Pour voir la taille exacte : sudo du -sh $mysql_vol)"
fi
echo ""

echo "6. Taille du volume ElasticSearch (sur disque) :"
echo "------------------------------------------------"
es_vol=$(docker volume inspect w-ads-300-lil-3-1-kiloupabocou-3_elasticsearch_data --format '{{ .Mountpoint }}' 2>/dev/null)
if [ -n "$es_vol" ]; then
    echo "   Volume : $es_vol"
    echo "   (Pour voir la taille exacte : sudo du -sh $es_vol)"
fi
echo ""

echo "💡 Recommandations :"
echo "   - Les logs peuvent grandir indéfiniment"
echo "   - ElasticSearch stocke tous les logs collectés"
echo "   - Utilisez './cleanup_logs.sh' pour nettoyer les anciens logs"
echo ""
