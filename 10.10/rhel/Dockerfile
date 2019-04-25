# vim:set ft=dockerfile:
FROM registry.access.redhat.com/rhel7
MAINTAINER Nuxeo <packagers@nuxeo.com>

LABEL name="nuxeo/nuxeo" \
      vendor="Nuxeo" \
      version="%%NUXEO_VERSION%%" \
      release="1" \
      summary="Nuxeo Digital Asset Platform" \
      description="The Nuxeo platform image packaged as a container" \
      url="https://www.nuxeo.com" \
      run='docker run -tdi -p 8080:8080 --name ${NAME} ${IMAGE}' \
      io.k8s.description="Starts a Nuxeo Platform server." \
      io.k8s.display-name="Nuxeo" \
      io.openshift.expose-services="8080/http" \
      io.openshift.tags="nuxeo" \
      io.openshift.min-memory="2Gi" \
      io.openshift.min-cpu="2"

# install java
RUN yum-config-manager --disable rhel-7-server-htb-rpms && \
    yum install -y \
       java-1.8.0-openjdk java-1.8.0-openjdk-devel wget unzip

#Add repositories need it for ffmpeg2theora and ffmpeg
ARG EPEL_RPM_URL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
ARG NUX_GPG_KEY_URL=http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
ARG NUX_DEXTOP_RPM_URL=http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm
RUN wget ${EPEL_RPM_URL} \
    && rpm -Uvh epel-release-latest-7*.rpm \
    && rpm --import ${NUX_GPG_KEY_URL} \
    && rpm -Uvh ${NUX_DEXTOP_RPM_URL}

## must find another way to install it, need it for ffmpeg
ARG NUX_DEXTOP_FRIBIDI_RPM_URL=ftp://ftp.pbone.net/mirror/li.nux.ro/download/nux/dextop/retired/libfribidi-0.19.2-3.el7.nux.x86_64.rpm
RUN rpm -Uvh ${NUX_DEXTOP_FRIBIDI_RPM_URL}

# enable repo for libreoffice
RUN yum-config-manager --enable rhel-7-server-optional-rpms
# Add needed convert tools
RUN yum -y upgrade && yum -y install \
    perl \
    ImageMagick \
    ffmpeg \
    ffmpeg2theora \
    ufraw \
    poppler-utils \
    libreoffice-core  \
    libwpd-tools \
    perl-Image-ExifTool \
    ghostscript \
    && yum clean all

ADD licenses /licenses
ADD help.1 /help.1


# Remove setuid/setgid binaries from images for security
RUN find / -perm 6000 -type f -exec chmod a-s {} \; || true

ENV NUXEO_USER nuxeo
ENV NUXEO_HOME /opt/nuxeo/server
ENV HOME /opt/nuxeo/server
ARG NUXEO_VERSION=10.10
ARG NUXEO_DIST_URL=http://community.nuxeo.com/static/releases/nuxeo-10.10/nuxeo-server-10.10-tomcat.zip
ARG NUXEO_MD5=90ef2ac005020e880b6277510800c30c


# Create Nuxeo user
RUN useradd -m -d /home/$NUXEO_USER -u 1000 -s /bin/bash $NUXEO_USER

# Add distribution
RUN curl -fsSL "${NUXEO_DIST_URL}" -o /tmp/nuxeo-distribution-tomcat.zip \
    && if [ $NUXEO_VERSION != "master" ]; then echo "$NUXEO_MD5 /tmp/nuxeo-distribution-tomcat.zip" | md5sum -c -; fi \
    && mkdir -p /tmp/nuxeo-distribution $(dirname $NUXEO_HOME) \
    && unzip -q -d /tmp/nuxeo-distribution /tmp/nuxeo-distribution-tomcat.zip \
    && DISTDIR=$(/bin/ls /tmp/nuxeo-distribution | head -n 1) \
    && mv /tmp/nuxeo-distribution/$DISTDIR $NUXEO_HOME \
    && sed -i -e "s/^org.nuxeo.distribution.package.*/org.nuxeo.distribution.package=docker/" $NUXEO_HOME/templates/common/config/distribution.properties \
    && rm -rf /tmp/nuxeo-distribution* \
    && chmod +x $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh \
    # For arbitrary user in the admin group
    && chmod g+rwX $NUXEO_HOME/bin/*ctl $NUXEO_HOME/bin/*.sh \
    && $NUXEO_HOME/bin/nuxeoctl mp-init \
    && chown -R 1000:0 $NUXEO_HOME && chmod -R g+rwX $NUXEO_HOME

COPY docker-template $NUXEO_HOME/templates/docker
COPY nuxeo.conf /etc/nuxeo/nuxeo.conf.template
ENV NUXEO_CONF /etc/nuxeo/nuxeo.conf

# Protecting writeable directories to support arbitrary User IDs for OpenShift
# https://docs.openshift.com/container-platform/3.4/creating_images/guidelines.html
RUN chown -R 1000:0 /etc/nuxeo && chmod g+rwX /etc/nuxeo && rm -f $NUXEO_HOME/bin/nuxeo.conf \
    && mkdir -p /var/lib/nuxeo/data \
    && chown -R 1000:0 /var/lib/nuxeo/data && chmod -R g+rwX /var/lib/nuxeo/data \
    && mkdir -p /var/log/nuxeo \
    && chown -R 1000:0 /var/log/nuxeo && chmod -R g+rwX /var/log/nuxeo \
    && mkdir -p /var/run/nuxeo \
    && chown -R 1000:0 /var/run/nuxeo && chmod -R g+rwX /var/run/nuxeo \
    && mkdir -p /docker-entrypoint-initnuxeo.d \
    && chown -R 1000:0 /docker-entrypoint-initnuxeo.d && chmod -R g+rwX /docker-entrypoint-initnuxeo.d  \
    && chmod g=u /etc/passwd

ENV PATH $NUXEO_HOME/bin:$PATH

WORKDIR $NUXEO_HOME
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
CMD ["nuxeoctl","console"]

USER 1000