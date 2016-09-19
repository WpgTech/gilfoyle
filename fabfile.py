# Usage
# fab --disable-known-hosts -f fabfile.py --hosts $SSH_HOST -u $SSH_USER -p $SSH_PASSWORD deploy
from fabric.api import *
import os
import sys
from fabric.contrib.project import rsync_project
from fabric.contrib.console import confirm

env.forward_agent = True

def deploy():
    #upload the docker image we built
    print("Logging into dockerhub")
    local(docker login -u $DOCKER_USER -p $DOCKER_PASS)
    print("Tagging image gilfoyle as wpgtech/gilfoyle:latest")
    local(docker tag gilfoyle wpgtech/gilfoyle:latest)
    print("Pushing wpgtech/gilfoyle:latest to dockerhub")
    local(docker push wpgtech/gilfoyle:latest)
    
    #deploy on remote server
    result=run("uname -r")

    if result.succeeded:
      print "[PASSED] Connecting to remote server "+env.host_string
    else:
      print "[FAILED] Could *not* ssh into server "+env.host_string+"! Please fix the auto-ssh issue. Exiting!";
      sys.exit(1)
   
    local_dir = os.path.dirname(os.path.realpath(__file__))
    print("Copying docker-compose.yml to server")
    put(local_dir + "/docker-compose.yml", '/opt/hubot/gilfoyle/')

    with cd('/opt/hubot/gilfoyle'):
      run('/usr/local/bin/docker-compose pull')
    run('sudo systemctl restart gilfoyle.service')