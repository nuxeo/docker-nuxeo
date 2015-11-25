# vim:set ft=dockerfile:
FROM       java:8
MAINTAINER Nuxeo <contact@nuxeo.com>

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
RUN echo "deb http://httpredir.debian.org/debian jessie non-free" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends \    
    perl \
    sudo \
    locales \
    pwgen \
    imagemagick \
    ffmpeg2theora \
    libfaac-dev \
    ufraw \
    poppler-utils \
    libreoffice \
    libwpd-tools \
    gimp \
    exiftool \
    ghostscript \
 && rm -rf /var/lib/apt/lists/*  

# Create Nuxeo user
RUN useradd -m -d /home/nuxeo -p nuxeo nuxeo && adduser nuxeo sudo && chsh -s /bin/bash nuxeo

ENV NUXEO_VERSION 7.10
ENV NUXEO_USER nuxeo
ENV NUXEO_HOME /var/lib/nuxeo/server
ENV NUXEOCTL /var/lib/nuxeo/server/bin/nuxeoctl

# Add distribution
ENV NUXEO_MD5 de2084b1a6fab4b1c8fb769903b044f2
ADD http://www.nuxeo.org/static/latest-release/nuxeo,cap,tomcat,zip,7.10 /tmp/nuxeo-distribution-tomcat.zip
RUN echo "$NUXEO_MD5 /tmp/nuxeo-distribution-tomcat.zip" | md5sum -c - \
    && mkdir -p /tmp/nuxeo-distribution \
    && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
    && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
    && mkdir -p /var/lib/nuxeo/server \
    && mv /tmp/nuxeo-distribution/$DISTDIR/* /var/lib/nuxeo/server \
    && rm -rf /tmp/nuxeo-distribution* \
    && chmod +x /var/lib/nuxeo/server/bin/nuxeoctl 



WORKDIR /var/lib/nuxeo/server
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
CMD ["./bin/nuxeoctl","console"]