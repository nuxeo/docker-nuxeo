#!/bin/bash

if [ "$1a" == "a" ]; then
	echo "Version parameter is mandatory."
	exit 1
fi

VERSION=$1

if [ -z "$2" ]; then
	MD5=`curl http://cdn.nuxeo.com/nuxeo-$VERSION/nuxeo-server-$VERSION-tomcat.zip.md5 | cut -d' ' -f1`
else
    MD5=$2
fi

mkdir -p $VERSION
cp docker-entrypoint.sh ./$VERSION/docker-entrypoint.sh
chmod +x ./$VERSION/docker-entrypoint.sh

cp Dockerfile.template ./$VERSION/Dockerfile
perl -p -i -e "s/^(ENV NUXEO_VERSION.*$)/ENV NUXEO_VERSION $VERSION/g" ./$VERSION/Dockerfile
perl -p -i -e "s/^(ENV NUXEO_MD5.*$)/ENV NUXEO_MD5 $MD5/g" ./$VERSION/Dockerfile
