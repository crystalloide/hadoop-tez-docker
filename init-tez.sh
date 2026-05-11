#!/bin/bash
# =============================================================================
# init-tez.sh — Initialisation automatique de Tez sur HDFS
# Exécuté une seule fois au 1er lancement par le service "tez-init"
# =============================================================================
set -e

export HADOOP_HOME=/opt/hadoop
export PATH=${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:$PATH
export JAVA_HOME=${JAVA_HOME:-$(dirname $(dirname $(readlink -f $(which java))))}

HDFS_TEZ_PATH="/apps/tez/tez.tar.gz"
LOCAL_TEZ_ARCHIVE="/opt/tez/tez.tar.gz"
MAX_RETRIES=72   # 72 × 5s = 6 minutes max
RETRY=0

# -----------------------------------------------------------------------------
# 1. Attente que le NameNode sorte du safe mode
# -----------------------------------------------------------------------------
echo "================================================================"
echo " Tez-Init : attente de la disponibilité du NameNode HDFS..."
echo "================================================================"

until hdfs dfsadmin -safemode get 2>/dev/null | grep -q "Safe mode is OFF"; do
  RETRY=$((RETRY + 1))
  if [ "${RETRY}" -ge "${MAX_RETRIES}" ]; then
    echo "ERREUR : timeout — le NameNode n'est pas sorti du safe mode après $((MAX_RETRIES * 5))s"
    exit 1
  fi
  echo "  → safe mode encore actif, tentative ${RETRY}/${MAX_RETRIES} (attente 5s)..."
  sleep 5
done

echo "  ✓ HDFS disponible — safe mode OFF"

# -----------------------------------------------------------------------------
# 2. Création des répertoires HDFS nécessaires
# -----------------------------------------------------------------------------
echo ""
echo "Création des répertoires HDFS..."

hdfs dfs -mkdir -p /apps/tez
hdfs dfs -mkdir -p /tmp/tez/staging
hdfs dfs -chmod -R 1777 /tmp/tez
hdfs dfs -chmod 755 /apps/tez

echo "  ✓ /apps/tez créé"
echo "  ✓ /tmp/tez/staging créé"

# -----------------------------------------------------------------------------
# 3. Upload du tarball Tez sur HDFS (idempotent)
# -----------------------------------------------------------------------------
echo ""
if hdfs dfs -test -f "${HDFS_TEZ_PATH}" 2>/dev/null; then
  echo "  ✓ Tez déjà présent sur HDFS (${HDFS_TEZ_PATH}), aucun upload nécessaire."
else
  echo "Upload de Tez vers HDFS : ${HDFS_TEZ_PATH}"
  echo "  (peut prendre quelques instants selon la taille du fichier...)"
  hdfs dfs -put "${LOCAL_TEZ_ARCHIVE}" "${HDFS_TEZ_PATH}"
  echo "  ✓ Upload terminé"
fi

# Vérification de l'intégrité
HDFS_SIZE=$(hdfs dfs -du -s "${HDFS_TEZ_PATH}" 2>/dev/null | awk '{print $1}')
LOCAL_SIZE=$(stat -c%s "${LOCAL_TEZ_ARCHIVE}" 2>/dev/null || echo "0")
echo "  → Taille locale  : ${LOCAL_SIZE} octets"
echo "  → Taille sur HDFS: ${HDFS_SIZE} octets"

# -----------------------------------------------------------------------------
echo ""
echo "================================================================"
echo " Tez-Init : TERMINÉ avec succès !"
echo " Le cluster Hadoop est prêt à exécuter des jobs via Tez."
echo "================================================================"
