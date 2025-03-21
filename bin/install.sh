#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

OS=`uname`
SPARK_VERSION=2.4.3
ELASTICSEARCH_VERSION=6.8.1
HBASE_VERSION=1.4.10
POSTGRES_VERSION=42.0.0
MYSQL_VERSION=5.1.41
PIO_DIR=$HOME/PredictionIO
USER_PROFILE=$HOME/.profile
PIO_FILE=PredictionIO-*.tar.gz
TEMP_DIR=/tmp

DISTRO_DEBIAN="Debian/Ubuntu"
DISTRO_OTHER="Other"

PGSQL="PostgreSQL"
MYSQL="MySQL"
ES_PGSQL="Elasticsearch + PostgreSQL"
ES_HB="Elasticsearch + HBase"

# Ask a yes/no question, with a default of "yes".
confirm () {
  echo -ne $@ "[Y/n] "
  read -r response

  case ${response} in
    [yY][eE][sS]|[yY]|"")
      true
      ;;
    [nN][oO]|[nN])
      false
      ;;
    *)
      confirm $@
      ;;
  esac
}

echo -e "\033[1;32mWelcome to PredictionIO !\033[0m"

# Detect OS
if [[ "$OS" = "Darwin" ]]; then
  echo "Mac OS detected!"
  SED_CMD="sed -i ''"
elif [[ "$OS" = "Linux" ]]; then
  echo "Linux OS detected!"
  SED_CMD="sed -i"
else
  echo -e "\033[1;31mYour OS $OS is not yet supported for automatic install :(\033[0m"
  echo -e "\033[1;31mPlease do a manual install!\033[0m"
  exit 1
fi

if [[ $USER ]]; then
  echo "Using user: $USER"
else
  echo "No user found - this is OK!"
fi

if [[ "$OS" = "Linux" && $(cat /proc/1/cgroup) == *cpu:/docker/* ]]; then
  # Docker
  # REQUIRED: No user input for Docker!
  echo -e "\033[1;33mDocker detected!\033[0m"
  echo -e "\033[1;33mForcing Docker defaults!\033[0m"
  pio_dir=${PIO_DIR}
  vendors_dir=${pio_dir}/vendors

  spark_dir=${vendors_dir}/spark-${SPARK_VERSION}
  elasticsearch_dir=${vendors_dir}/elasticsearch-${ELASTICSEARCH_VERSION}
  hbase_dir=${vendors_dir}/hbase-${HBASE_VERSION}
  zookeeper_dir=${vendors_dir}/zookeeper

  echo "--------------------------------------------------------------------------------"
  echo -e "\033[1;32mOK, looks good!\033[0m"
  echo "You are going to install PredictionIO to: $pio_dir"
  echo -e "Vendor applications will go in: $vendors_dir\n"
  echo "Spark: $spark_dir"
  echo "Elasticsearch: $elasticsearch_dir"
  echo "HBase: $hbase_dir"
  echo "ZooKeeper: $zookeeper_dir"
  echo "--------------------------------------------------------------------------------"

  # Java Install
  echo -e "\033[1;36mStarting Java install...\033[0m"

  sudo add-apt-repository ppa:openjdk-r/ppa
  sudo apt-get update
  sudo apt-get install openjdk-8-jdk libgfortran3 -y

  echo -e "\033[1;32mJava install done!\033[0m"

  JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
elif [[ "$1" == "-y" ]]; then
  # Non-interactive
  echo -e "\033[1;33mNon-interactive installation requested!\033[0m"
  echo -e "\033[1;33mForcing defaults!\033[0m"
  pio_dir=${PIO_DIR}
  vendors_dir=${pio_dir}/vendors
  source_setup=${ES_HB}

  spark_dir=${vendors_dir}/spark-${SPARK_VERSION}
  elasticsearch_dir=${vendors_dir}/elasticsearch-${ELASTICSEARCH_VERSION}
  hbase_dir=${vendors_dir}/hbase-${HBASE_VERSION}
  zookeeper_dir=${vendors_dir}/zookeeper

  echo "--------------------------------------------------------------------------------"
  echo -e "\033[1;32mOK, looks good!\033[0m"
  echo "You are going to install PredictionIO to: $pio_dir"
  echo -e "Vendor applications will go in: $vendors_dir\n"
  echo "Spark: $spark_dir"
  echo "Elasticsearch: $elasticsearch_dir"
  echo "HBase: $hbase_dir"
  echo "ZooKeeper: $zookeeper_dir"
  echo "--------------------------------------------------------------------------------"

  # Java Install
  echo -e "\033[1;36mStarting Java install...\033[0m"

  # todo: make java installation platform independent
  sudo add-apt-repository ppa:openjdk-r/ppa
  sudo apt-get update
  sudo apt-get install openjdk-8-jdk libgfortran3 python-pip -y
  sudo pip install predictionio

  echo -e "\033[1;32mJava install done!\033[0m"

  JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
else
  # Interactive
  while true; do
    echo -e "\033[1mWhere would you like to install PredictionIO?\033[0m"
    read -e -p "Installation path ($PIO_DIR): " pio_dir
    pio_dir=${pio_dir:-$PIO_DIR}

    read -e -p "Vendor path ($pio_dir/vendors): " vendors_dir
    vendors_dir=${vendors_dir:-$pio_dir/vendors}

    echo -e "\033[1mPlease choose between the following sources (1, 2, 3 or 4):\033[0m"
    select source_setup in "$PGSQL" "$MYSQL" "$ES_PGSQL" "$ES_HB"; do
      case ${source_setup} in
        "$PGSQL")
          break
          ;;
        "$MYSQL")
          break
          ;;
        "$ES_PGSQL")
          break
          ;;
        "$ES_HB")
          break
          ;;
        *)
          ;;
      esac
    done

    spark_dir=${vendors_dir}/spark-${SPARK_VERSION}
    elasticsearch_dir=${vendors_dir}/elasticsearch-${ELASTICSEARCH_VERSION}
    hbase_dir=${vendors_dir}/hbase-${HBASE_VERSION}
    zookeeper_dir=${vendors_dir}/zookeeper

    echo "--------------------------------------------------------------------------------"
    echo -e "\033[1;32mOK, looks good!\033[0m"
    echo "You are going to install PredictionIO to: $pio_dir"
    echo -e "Vendor applications will go in: $vendors_dir\n"
    echo "Spark: $spark_dir"
    case $source_setup in
      "$PGSQL")
        # PostgreSQL installed by apt-get so no path is printed beforehand
        break
        ;;
      "$MYSQL")
        # MySQL installed by apt-get so no path is printed beforehand
        break
        ;;
      "$ES_PGSQL")
        # PostgreSQL installed by apt-get so no path is printed beforehand
        echo "Elasticsearch: $elasticsearch_dir"
        break
        ;;
      "$ES_HB")
        echo "Elasticsearch: $elasticsearch_dir"
        echo "HBase: $hbase_dir"
        echo "ZooKeeper: $zookeeper_dir"
        break
        ;;
    esac
    echo "--------------------------------------------------------------------------------"
    if confirm "\033[1mIs this correct?\033[0m"; then
      break;
    fi
  done

  echo -e "\033[1mSelect your linux distribution:\033[0m"
  select distribution in "$DISTRO_DEBIAN" "$DISTRO_OTHER"; do
    case $distribution in
      "$DISTRO_DEBIAN")
        break
        ;;
      "$DISTRO_OTHER")
        break
        ;;
      *)
        ;;
    esac
  done

  # Java Install
  if [[ ${OS} = "Linux" ]] && confirm "\033[1mWould you like to install Java?\033[0m"; then
    case ${distribution} in
      "$DISTRO_DEBIAN")
        echo -e "\033[1;36mStarting Java install...\033[0m"

        echo -e "\033[33mThis script requires superuser access!\033[0m"
        echo -e "\033[33mYou will be prompted for your password by sudo:\033[0m"

        sudo add-apt-repository ppa:openjdk-r/ppa
        sudo apt-get update
        sudo apt-get install openjdk-8-jdk libgfortran3 python-pip -y
        sudo pip install predictionio

        echo -e "\033[1;32mJava install done!\033[0m"
        break
        ;;
      "$DISTRO_OTHER")
        echo -e "\033[1;31mYour distribution not yet supported for automatic install :(\033[0m"
        echo -e "\033[1;31mPlease install Java manually!\033[0m"
        exit 2
        ;;
      *)
        ;;
    esac
  fi

  # Try to find JAVA_HOME
  echo "Locating JAVA_HOME..."
  if [[ "$OS" = "Darwin" ]]; then
    JAVA_VERSION=`echo "$(java -version 2>&1)" | grep "java version" | awk '{ print substr($3, 2, length($3)-2); }'`
    JAVA_HOME=`/usr/libexec/java_home`
  elif [[ "$OS" = "Linux" ]]; then
    JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
  fi
  echo "Found: $JAVA_HOME"

  # Check JAVA_HOME
  while [ ! -f "$JAVA_HOME/bin/javac" ]; do
    echo -e "\033[1;31mJAVA_HOME is incorrect!\033[0m"
    echo -e "\033[1;33mJAVA_HOME should be a directory containing \"bin/javac\"!\033[0m"
    read -e -p "Please enter JAVA_HOME manually: " JAVA_HOME
  done;
fi

if [ -n "$JAVA_VERSION" ]; then
  echo "Your Java version is: $JAVA_VERSION"
fi
echo "JAVA_HOME is now set to: $JAVA_HOME"

# PredictionIO
echo -e "\033[1;36mStarting PredictionIO setup in:\033[0m $pio_dir"

cd ${TEMP_DIR}

files=$(ls PredictionIO*.tar.gz 2> /dev/null | wc -l)

if [[ $files == 0 ]]; then
  echo "Downloading PredictionIO..."

  curl -L https://archive.apache.org/dist/predictionio/0.14.0/apache-predictionio-0.14.0.tar.gz > predictionio-release.tar.gz
  mkdir PredictionIO
  
  tar zxf predictionio-release.tar.gz -C PredictionIO

  cd PredictionIO
  ./make-distribution.sh
  
  cd ..
  
  cp PredictionIO/${PIO_FILE} ${TEMP_DIR}
  rm -r PredictionIO
fi

tar zxf ${PIO_FILE}
rm -rf ${pio_dir}
mv PredictionIO*/ ${pio_dir}

if [[ $USER ]]; then
  chown -R $USER ${pio_dir}
fi

echo "Updating ~/.profile to include: $pio_dir"
PATH=$PATH:${pio_dir}/bin
echo "export PATH=\$PATH:$pio_dir/bin" >> ${USER_PROFILE}

echo -e "\033[1;32mPredictionIO setup done!\033[0m"

mkdir -p ${vendors_dir}

# Spark
echo -e "\033[1;36mStarting Spark setup in:\033[0m $spark_dir"
if [[ ! -e spark-${SPARK_VERSION}-bin-hadoop2.7.tgz ]]; then
  echo "Downloading Spark..."
  curl -O https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
fi

tar xf spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
rm -rf ${spark_dir}
mv spark-${SPARK_VERSION}-bin-hadoop2.7 ${spark_dir}

echo "Updating: $pio_dir/conf/pio-env.sh"
${SED_CMD} "s|SPARK_HOME=.*|SPARK_HOME=$spark_dir|g" ${pio_dir}/conf/pio-env.sh

echo -e "\033[1;32mSpark setup done!\033[0m"

installPGSQL () {
  if [[ ${distribution} = "$DISTRO_DEBIAN" ]]; then
      echo -e "\033[1;36mInstalling PostgreSQL...\033[0m"
      sudo apt-get install postgresql-9.4 -y
      echo -e "\033[1;36mPlease use the default password 'pio' when prompted to enter one\033[0m"
      sudo -u postgres createdb pio
      sudo -u postgres createuser -P pio
      echo -e "\033[1;36mPlease update $pio_dir/conf/pio-env.sh if you did not enter the default password\033[0m"
    else
      echo -e "\033[1;31mYour distribution not yet supported for automatic install :(\033[0m"
      echo -e "\033[1;31mPlease install PostgreSQL manually!\033[0m"
    fi
    curl -O https://jdbc.postgresql.org/download/postgresql-${POSTGRES_VERSION}.jar
    mv postgresql-${POSTGRES_VERSION}.jar ${pio_dir}/lib/

    echo -e "\033[1;32mPGSQL setup done!\033[0m"
}

installES() {
    echo -e "\033[1;36mStarting Elasticsearch setup in:\033[0m $elasticsearch_dir"
    if [[ -e elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz ]]; then
      if confirm "Delete existing elasticsearch-$ELASTICSEARCH_VERSION.tar.gz?"; then
        rm elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz
      fi
    fi
    if [[ ! -e elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz ]]; then
      echo "Downloading Elasticsearch..."
      curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz
    fi
    tar zxf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz
    rm -rf ${elasticsearch_dir}
    mv elasticsearch-${ELASTICSEARCH_VERSION} ${elasticsearch_dir}

    echo "Updating: $elasticsearch_dir/config/elasticsearch.yml"
    echo 'network.host: 127.0.0.1' >> ${elasticsearch_dir}/config/elasticsearch.yml
}

case $source_setup in
  "$PGSQL")
    installPGSQL
    ;;
  "$ES_PGSQL")
    installES
    installPGSQL
    echo "Updating: $pio_dir/conf/pio-env.sh"
    ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=.*|PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=$elasticsearch_dir|" ${pio_dir}/conf/pio-env.sh
    ;;
  "$MYSQL")
    if [[ ${distribution} = "$DISTRO_DEBIAN" ]]; then
      echo -e "\033[1;36mInstalling MySQL...\033[0m"
      echo -e "\033[1;36mPlease update $pio_dir/conf/pio-env.sh with your database configuration\033[0m"
      sudo apt-get install mysql-server -y
      sudo mysql -e "create database pio; grant all on pio.* to pio@localhost identified by 'pio'"
      echo -e "\033[1;36mUpdating: $pio_dir/conf/pio-env.sh\033[0m"
      ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=MYSQL|" ${pio_dir}/conf/pio-env.sh
      ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=MYSQL|" ${pio_dir}/conf/pio-env.sh
      ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=MYSQL|" ${pio_dir}/conf/pio-env.sh
      ${SED_CMD} "s|PIO_STORAGE_SOURCES_PGSQL|# PIO_STORAGE_SOURCES_PGSQL|" ${pio_dir}/conf/pio-env.sh
      ${SED_CMD} "s|# PIO_STORAGE_SOURCES_MYSQL|PIO_STORAGE_SOURCES_MYSQL|" ${pio_dir}/conf/pio-env.sh
    else
      echo -e "\033[1;31mYour distribution not yet supported for automatic install :(\033[0m"
      echo -e "\033[1;31mPlease install MySQL manually!\033[0m"
      exit 4
    fi
    curl -O http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.37/mysql-connector-java-${MYSQL_VERSION}.jar
    mv mysql-connector-java-${MYSQL_VERSION}.jar ${pio_dir}/lib/
    ;;
  "$ES_HB")
    # Elasticsearch
    installES
    echo "Updating: $pio_dir/conf/pio-env.sh"
    ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=LOCALFS|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=PGSQL|PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=HBASE|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|PIO_STORAGE_SOURCES_PGSQL|# PIO_STORAGE_SOURCES_PGSQL|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|# PIO_STORAGE_SOURCES_LOCALFS|PIO_STORAGE_SOURCES_LOCALFS|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|# PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=.*|PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=$elasticsearch_dir|" ${pio_dir}/conf/pio-env.sh
    echo -e "\033[1;32mElasticsearch setup done!\033[0m"

    # HBase
    echo -e "\033[1;36mStarting HBase setup in:\033[0m $hbase_dir"
    if [[ ! -e hbase-${HBASE_VERSION}-bin.tar.gz ]]; then
      echo "Downloading HBase..."
      curl -O http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz
    fi
    tar zxf hbase-${HBASE_VERSION}-bin.tar.gz
    rm -rf ${hbase_dir}
    mv hbase-${HBASE_VERSION} ${hbase_dir}

    echo "Creating default site in: $hbase_dir/conf/hbase-site.xml"
    cat <<EOT > ${hbase_dir}/conf/hbase-site.xml
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file://${hbase_dir}/data</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>${zookeeper_dir}</value>
  </property>
</configuration>
EOT

    echo "Updating: $hbase_dir/conf/hbase-env.sh to include $JAVA_HOME"
    ${SED_CMD} "s|# export JAVA_HOME=/usr/java/jdk1.6.0/|export JAVA_HOME=$JAVA_HOME|" ${hbase_dir}/conf/hbase-env.sh

    echo "Updating: $pio_dir/conf/pio-env.sh"
    ${SED_CMD} "s|# PIO_STORAGE_SOURCES_HBASE|PIO_STORAGE_SOURCES_HBASE|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|PIO_STORAGE_SOURCES_HBASE_HOME=.*|PIO_STORAGE_SOURCES_HBASE_HOME=$hbase_dir|" ${pio_dir}/conf/pio-env.sh
    ${SED_CMD} "s|# HBASE_CONF_DIR=.*|HBASE_CONF_DIR=$hbase_dir/conf|" ${pio_dir}/conf/pio-env.sh

    echo -e "\033[1;32mHBase setup done!\033[0m"

    ;;
esac









echo "Updating permissions on: $vendors_dir"

if [[ $USER ]]; then
  chown -R $USER ${vendors_dir}
fi

echo -e "\033[1;32mInstallation done!\033[0m"





echo "--------------------------------------------------------------------------------"
echo -e "\033[1;32mInstallation of PredictionIO complete!\033[0m"
echo -e "\033[1;32mPlease follow documentation at http://predictionio.apache.org/start/download/ to download the engine template based on your needs\033[0m"
echo -e
echo -e "\033[1;33mCommand Line Usage Notes:\033[0m"
if [[ ${source_setup} = $ES_HB ]]; then
  echo -e "To start PredictionIO and dependencies, run: '\033[1mpio-start-all\033[0m'"
else
  echo -e "To start PredictionIO Event Server in the background, run: '\033[1mpio eventserver &\033[0m'"
fi
echo -e "To check the PredictionIO status, run: '\033[1mpio status\033[0m'"
echo -e "To train/deploy engine, run: '\033[1mpio [train|deploy|...]\033[0m' commands"
if [[ ${source_setup} = $ES_HB ]]; then
  echo -e "To stop PredictionIO and dependencies, run: '\033[1mpio-stop-all\033[0m'"
fi
echo -e ""
echo -e "Please report any problems to the user mailing list."
echo -e "User mailing list instructions: \033[1;34mhttp://predictionio.apache.org/support/\033[0m"
echo "--------------------------------------------------------------------------------"
