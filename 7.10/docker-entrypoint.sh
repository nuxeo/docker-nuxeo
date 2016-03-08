#!/bin/bash 
set -e

NUXEO_CONF=$NUXEO_HOME/bin/nuxeo.conf

if [ "$1" = 'nuxeoctl' ]; then
  if [ ! -f $NUXEO_HOME/configured ]; then

    # PostgreSQL conf
    if [ -n "$NUXEO_DB_TYPE" ]; then

      if [ -z "$NUXEO_DB_HOST" ]; then
        echo "You have to setup a NUXEO_DB_HOST if not using default DB type"
        exit 1
      fi
      
      NUXEO_DB_HOST=${NUXEO_DB_HOST}
      NUXEO_DB_NAME=${NUXEO_DB_NAME:-nuxeo}
      NUXEO_DB_USER=${NUXEO_DB_USER:-nuxeo}
      NUXEO_DB_PASSWORD=${NUXEO_DB_PASSWORD:-nuxeo}

    	perl -p -i -e "s/^#?(nuxeo.templates=.*$)/\1,${NUXEO_DB_TYPE}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.host=.*$/nuxeo.db.host=${NUXEO_DB_HOST}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.name=.*$/nuxeo.db.name=${NUXEO_DB_NAME}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.user=.*$/nuxeo.db.user=${NUXEO_DB_USER}/g" $NUXEO_CONF
    	perl -p -i -e "s/^#?nuxeo.db.password=.*$/nuxeo.db.password=${NUXEO_DB_PASSWORD}/g" $NUXEO_CONF
    fi


    if [ -n "$NUXEO_TEMPLATES" ]; then
      perl -p -i -e "s/^#?(nuxeo.templates=.*$)/\1,${NUXEO_TEMPLATES}/g" $NUXEO_CONF
    fi
 
    # nuxeo.url
    if [ -n "$NUXEO_URL" ]; then
      echo "nuxeo.url=$NUXEO_URL" >> $NUXEO_CONF
    fi

    if [ -n "$NUXEO_ES_HOSTS" ]; then
      echo "elasticsearch.addressList=${NUXEO_ES_HOSTS}" >> $NUXEO_CONF
      echo "elasticsearch.clusterName=${NUXEO_ES_CLUSTER_NAME:=elasticsearch}" >> $NUXEO_CONF
      echo "elasticsearch.indexName=${NUXEO_ES_INDEX_NAME:=nuxeo}" >> $NUXEO_CONF
      echo "elasticsearch.indexNumberOfReplicas=${NUXEO_ES_REPLICAS:=1}" >> $NUXEO_CONF
      echo "elasticsearch.indexNumberOfShards=${NUXEO_ES_SHARDS:=5}" >> $NUXEO_CONF
    fi

    if [ "$NUXEO_AUTOMATION_TRACE" = "true" ]; then
      echo "org.nuxeo.automation.trace=true" >> $NUXEO_CONF
    fi

    if [ "$NUXEO_DEV_MODE" = "true" ]; then
      echo "org.nuxeo.dev=true" >> $NUXEO_CONF
    fi

    if [ -n "$NUXEO_REDIS_HOST" ]; then
      echo "nuxeo.redis.enabled=true" >> $NUXEO_CONF
      echo "nuxeo.redis.host=${NUXEO_REDIS_HOST}" >> $NUXEO_CONF
      echo "nuxeo.redis.port=${NUXEO_REDIS_PORT:=6379}" >> $NUXEO_CONF
    fi
    
    mkdir -p ${NUXEO_DATA:=/var/lib/nuxeo/data}
    mkdir -p ${NUXEO_LOG:=/var/log/nuxeo}
    mkdir -p /var/run/nuxeo

    # The binary store environment variable is defined : 1/ creates the folder with proper rights; 2/ fills in the corresponding property within nuxeo.conf
    if [ -n "$NUXEO_BINARY_STORE" ]; then
      mkdir -p $NUXEO_BINARY_STORE
      chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_BINARY_STORE
      echo "repository.binary.store=$NUXEO_BINARY_STORE" >> $NUXEO_CONF
    fi

    # The transient store environment variable is defined : 1/ creates the folder with proper rights; 2/ creates the symbolic link as explained in nuxeo cluster documentation
    if [ -n "$NUXEO_TRANSIENT_STORE" ]; then
      mkdir -p $NUXEO_TRANSIENT_STORE
      chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_TRANSIENT_STORE

      #removes transients stores if exists to allow symbolic link creation
      if [ -d $NUXEO_DATA/transientstores ]; then
          rm -rf $NUXEO_DATA/transientstores
      fi
      mkdir -p $NUXEO_DATA/transientstores
      ln -s $NUXEO_TRANSIENT_STORE $NUXEO_DATA/transientstores/default
    fi
    chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_HOME
    chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_DATA
    chown -R $NUXEO_USER:$NUXEO_USER $NUXEO_LOG
    chown -R $NUXEO_USER:$NUXEO_USER /var/run/nuxeo

    cat << EOF >> $NUXEO_CONF
nuxeo.log.dir=$NUXEO_LOG
nuxeo.pid.dir=/var/run/nuxeo
nuxeo.data.dir=$NUXEO_DATA
nuxeo.wizard.done=true
EOF

    if [ -f /nuxeo.conf ]; then
      cat /nuxeo.conf >> $NUXEO_CONF
    fi

    touch $NUXEO_HOME/configured

  fi

  # instance.clid
  if [ -n "$NUXEO_CLID" ]; then
    printf "%b\n" "$NUXEO_CLID" >> $NUXEO_DATA/instance.clid
  fi


  ## Executed at each start
  if [ -n "$NUXEO_CLID"  ] && [ ${NUXEO_INSTALL_HOTFIX:='true'} == "true" ]; then
      gosu $NUXEO_USER nuxeoctl mp-hotfix --accept=true
  fi

  # Install packages if exist
  if [ -n "$NUXEO_PACKAGES" ]; then
    gosu $NUXEO_USER nuxeoctl mp-install $NUXEO_PACKAGES --relax=false --accept=true
  fi
  for f in /docker-entrypoint-initnuxeo.d/*; do
    case "$f" in
      *.sh)  echo "$0: running $f"; . "$f" ;;
      *)     echo "$0: ignoring $f" ;;
    esac
    echo
  done

  if [ "$2" = "console" ]; then
    exec gosu $NUXEO_USER nuxeoctl console
  else
    exec gosu $NUXEO_USER "$@"
  fi

fi


exec "$@"
