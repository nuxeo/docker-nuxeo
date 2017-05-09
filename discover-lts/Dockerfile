# vim:set ft=dockerfile:
FROM       nuxeo/nuxeo:LTS
MAINTAINER Nuxeo <packagers@nuxeo.com>
RUN echo "nuxeo.wizard.done=false" > /docker-entrypoint-initnuxeo.d/nuxeo.conf
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
CMD ["nuxeoctl","console"]
