FROM apache/hadoop:3.4.2

USER root

ENV TEZ_VERSION=0.10.5
ENV TEZ_HOME=/opt/tez

# Téléchargement et installation de Apache Tez
# RUN curl -fSL "https://archive.apache.org/dist/tez/${TEZ_VERSION}/apache-tez-${TEZ_VERSION}-bin.tar.gz" \
RUN curl -fSL "https://downloads.apache.org/tez/${TEZ_VERSION}/apache-tez-${TEZ_VERSION}-bin.tar.gz" \
        -o /tmp/tez.tar.gz \
    && mkdir -p ${TEZ_HOME} \
    && tar -xzf /tmp/tez.tar.gz -C ${TEZ_HOME} --strip-components=1 \
    # Conserver l'archive originale pour l'upload HDFS
    && cp /tmp/tez.tar.gz ${TEZ_HOME}/tez.tar.gz \
    && rm /tmp/tez.tar.gz \
    && chown -R hadoop:hadoop ${TEZ_HOME}

# Copier tez-site.xml dans le répertoire de configuration Hadoop
COPY tez-site.xml /opt/hadoop/etc/hadoop/tez-site.xml

# Ajouter les jars Tez au HADOOP_CLASSPATH (nécessaire pour le client et les AMs)
RUN echo "export HADOOP_CLASSPATH=\${HADOOP_CLASSPATH}:${TEZ_HOME}/*:${TEZ_HOME}/lib/*" \
    >> /opt/hadoop/etc/hadoop/hadoop-env.sh \
    && chown hadoop:hadoop /opt/hadoop/etc/hadoop/tez-site.xml

USER hadoop
