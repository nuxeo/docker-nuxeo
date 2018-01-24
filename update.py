#!/usr/bin/env python



import os, sys, shutil, base64, getpass, json
import re
import urllib2
from distutils.version import StrictVersion
from distutils.dir_util import copy_tree


connect_user = raw_input("Please enter a connect account user: ")
connect_password = getpass.getpass("Please enter the connect password: ")


request = urllib2.Request("https://connect.nuxeo.com/nuxeo/site/target-platforms?filterDisabled=true&filterRestricted=true&filterDeprecated=true")
base64string = base64.encodestring('%s:%s' % (connect_user, connect_password)).replace('\n', '')
request.add_header("Authorization", "Basic %s" % base64string)   
target_platforms_json = urllib2.urlopen(request).read()
target_platforms = json.loads(target_platforms_json)

# Specific case for SNAPSHOT release
master = {}
master['version'] = "master"
master['downloadLink'] = "http://community.nuxeo.com/static/latest-snapshot/nuxeo-server-tomcat,SNAPSHOT.zip"
target_platforms.append(master)


MIN_VERSION='7.10'
VARIANTS = ['ubuntu', 'centos', 'rhel']

travis = []
    
for tp in target_platforms:
    
    version = tp['version']
    if version != "master" and StrictVersion(version) < StrictVersion(MIN_VERSION) :
        continue

    print "Generating files for %s" % tp['version']
    dist_url = tp['downloadLink']
    if version == "master":
        md5="noMD5check"
    else: 
        md5 = urllib2.urlopen("%s.md5" % dist_url).read().split(" ")[0]

    
    for variant in VARIANTS:
        pre93 = version != "master" and StrictVersion(version) < StrictVersion("9.3")
        pre92 = version != "master" and StrictVersion(version) < StrictVersion("9.2")
        pre91 = version != "master" and StrictVersion(version) < StrictVersion("9.1")
        pre810 = version != "master" and StrictVersion(version) < StrictVersion("8.10")

        if variant == 'ubuntu':
            dockerfile = '%s/Dockerfile' % version
            travis.append(' - VERSION=%s' % version)
        else:
            dockerfile = '%s/%s/Dockerfile' % (version, variant)
            if variant != 'rhel':
                travis.append(' - VERSION=%s VARIANT=%s' % (version, variant))
        if pre810 and os.path.exists('templates/pre-8.10/Dockerfile.' + variant):
            with open('templates/pre-8.10/Dockerfile.' + variant , 'r') as tmpfile:
               template = tmpfile.read()
        else:
            with open('templates/Dockerfile.' + variant , 'r') as tmpfile:
               template = tmpfile.read()
        if pre91:
            with open('templates/pre-9.1/Dockerfile-run', 'r') as tmpfile:
                run_content = tmpfile.read()
        else:
            with open('templates/Dockerfile-run', 'r') as tmpfile:
                run_content = tmpfile.read()
        with open('templates/Dockerfile-env', 'r') as tmpfile:
           env_content = tmpfile.read()

        # Workaround for Java version comparison bug : https://jira.nuxeo.com/browse/NXP-20189
        if pre810:
            env_content = env_content + "# https://jira.nuxeo.com/browse/NXP-20189\nENV LAUNCHER_DEBUG -Djvmcheck=nofail"

        env_content = env_content.replace('%%NUXEO_VERSION%%', version)
        env_content = env_content.replace('%%NUXEO_DIST_URL%%', dist_url)
        env_content = env_content.replace('%%NUXEO_MD5%%', md5)

        run_content = run_content.replace('%%ENV%%', env_content)
        docker_content = template.replace('%%RUN%%', run_content)

        d = os.path.dirname(dockerfile)
        if not os.path.exists(d):
            os.makedirs(d)

        with open(dockerfile, 'w') as dfile:
          dfile.write(docker_content)
        

        if pre91:            
            shutil.copy("templates/pre-9.1/docker-entrypoint.sh", d)
        else:
            shutil.copy("templates/docker-entrypoint.sh", d)            
            if(os.path.exists(d + '/docker-template')):
                shutil.rmtree(d + '/docker-template')
            shutil.copytree("templates/docker-template", d + '/docker-template')

            if pre92:
                shutil.copy("templates/pre-9.2/nuxeo.conf", d)
            elif pre93:
                shutil.copy("templates/pre-9.3/nuxeo.conf", d)
            else:
                shutil.copy("templates/nuxeo.conf", d)

        if variant == 'rhel':
            copy_tree("templates/rhel", d )
            







with open('travis.template', 'r') as tmpfile:
   template = tmpfile.read()
travis = template.replace('%%VERSIONS%%', '\n'.join(travis))


with open('.travis.yml', 'w') as travisfile:
  travisfile.write(travis)
