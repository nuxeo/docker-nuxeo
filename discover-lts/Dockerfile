# vim:set ft=dockerfile:
FROM       nuxeo/nuxeo:LTS
MAINTAINER Nuxeo <packagers@nuxeo.com>
RUN perl -p -i -e "s/^#?nuxeo.wizard.done=.*$/nuxeo.wizard.done=false/g" /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080
CMD ["nuxeoctl","console"]
