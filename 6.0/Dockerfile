# vim:set ft=dockerfile:
FROM       openjdk:8-jdk
MAINTAINER Nuxeo <packagers@nuxeo.com>

# Create Nuxeo user
ENV NUXEO_USER nuxeo
RUN useradd -m -d /home/$NUXEO_USER -u 1000 -s /bin/bash $NUXEO_USER

# Add needed convert tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
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
 && rm -rf /var/lib/apt/lists/*



ENV NUXEO_HOME /opt/nuxeo/server

ARG NUXEO_VERSION=6.0
ARG NUXEO_DIST_URL=http://cdn.nuxeo.com/nuxeo-${NUXEO_VERSION}/nuxeo-cap-${NUXEO_VERSION}-tomcat.zip
ARG NUXEO_MD5=b8cbc0b2858b0697a541be49feb24571

# Add distribution
RUN curl -fsSL "${NUXEO_DIST_URL}" -o /tmp/nuxeo-distribution-tomcat.zip \
    && echo "$NUXEO_MD5 /tmp/nuxeo-distribution-tomcat.zip" | md5sum -c - \
    && mkdir -p /tmp/nuxeo-distribution $(dirname $NUXEO_HOME) \
    && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
    && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
    && mv /tmp/nuxeo-distribution/$DISTDIR $NUXEO_HOME \
    && sed -i -e "s/^org.nuxeo.distribution.package.*/org.nuxeo.distribution.package=docker/" $NUXEO_HOME/templates/common/config/distribution.properties \
    && rm -rf /tmp/nuxeo-distribution* \
    && chmod +x $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh \
    # For arbitrary user in the admin group
    && chmod g+rwX $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh


RUN chown -R 1000:0 $NUXEO_HOME && chmod -R g+rwX $NUXEO_HOME

# Protecting writeable directories to support arbitrary User IDs for OpenShift
# https://docs.openshift.com/container-platform/3.4/creating_images/guidelines.html
RUN mkdir -p /var/lib/nuxeo/data \
    && chown -R 1000:0 /var/lib/nuxeo/data && chmod -R g+rwX /var/lib/nuxeo/data \
    && mkdir -p /var/log/nuxeo \
    && chown -R 1000:0 /var/log/nuxeo && chmod -R g+rwX /var/log/nuxeo \
    && mkdir -p /var/run/nuxeo \
    && chown -R 1000:0 /var/run/nuxeo && chmod -R g+rwX /var/run/nuxeo \
    && mkdir -p /docker-entrypoint-initnuxeo.d \
    && chown -R 1000:0 /docker-entrypoint-initnuxeo.d && chmod -R g+rwX /docker-entrypoint-initnuxeo.d 

# Remove setuid/setgid binaries from images for security
RUN find / -perm +6000 -type f -exec chmod a-s {} \; || true

ENV PATH $NUXEO_HOME/bin:$PATH

WORKDIR $NUXEO_HOME
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
EXPOSE 8787
CMD ["nuxeoctl","console"]


USER 1000
