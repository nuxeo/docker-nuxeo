# vim:set ft=dockerfile:
FROM       java:8
MAINTAINER Nuxeo <packagers@nuxeo.com>

# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN arch="$(dpkg --print-architecture)" \
	&& set -x \
	&& curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch" \
	&& curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch.asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu


# Add needed convert tools
RUN apt-get update && apt-get install -y --no-install-recommends \    
    perl \
    sudo \
    locales \
    pwgen \
    imagemagick \
    ffmpeg2theora \
    ufraw \
    poppler-utils \
    libreoffice \
    libwpd-tools \
    exiftool \
    ghostscript \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*  

# Create Nuxeo user
RUN useradd -m -d /home/nuxeo -p nuxeo nuxeo && adduser nuxeo sudo && chsh -s /bin/bash nuxeo

ENV NUXEO_VERSION 7.10
ENV NUXEO_MD5 de2084b1a6fab4b1c8fb769903b044f2
ENV NUXEO_USER nuxeo
ENV NUXEO_HOME /opt/nuxeo/server
ENV NUXEOCTL $NUXEO_HOME/bin/nuxeoctl

# Add distribution
ADD http://cdn.nuxeo.com/nuxeo-${NUXEO_VERSION}/nuxeo-cap-${NUXEO_VERSION}-tomcat.zip /tmp/nuxeo-distribution-tomcat.zip
RUN echo "$NUXEO_MD5 /tmp/nuxeo-distribution-tomcat.zip" | md5sum -c - \
    && mkdir -p /tmp/nuxeo-distribution $(dirname $NUXEO_HOME) \
    && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
    && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
    && mv /tmp/nuxeo-distribution/$DISTDIR $NUXEO_HOME \
    && rm -rf /tmp/nuxeo-distribution* \
    && chmod +x $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh



WORKDIR $NUXEO_HOME
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
CMD ["./bin/nuxeoctl","console"]