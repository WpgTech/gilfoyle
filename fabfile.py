# Usage
# fab --disable-known-hosts -f fabfile.py --hosts $SSH_HOST -u $SSH_USER -p $SSH_PASSWORD deploy --set DOCKER_USER=$DOCKER_USER,DOCKER_PASS=$DOCKER_PASS 2> /dev/null
# note that we are redirecting stderr to /dev/null so we don't leak sensitive info to the console on failures

from fabric.api import *
import os
import sys
from fabric.contrib.project import rsync_project
from fabric.contrib.console import confirm

env.forward_agent = True

def deploy():
  with hide('everything'):            
    #build and upload the docker image
    print("Logging into docker")
    local("docker login -u %s -p %s" % (env.DOCKER_USER, env.DOCKER_PASS))
    
    print("Building docker image")
    local("docker build -t gilfoyle .")
    
    print("Tagging docker image")
    local("docker tag gilfoyle wpgtech/gilfoyle:latest")
    
    print("Pushing image to dockerhub")
    local("docker push wpgtech/gilfoyle:latest")
    
    #deploy on remote server
    result=run("uname -r")
    if result.succeeded:
      print("[PASSED] Connecting to remote server")
    else:
      print("[FAILED] Could *not* ssh into server! Please fix the auto-ssh issue. Exiting!")
      sys.exit(1)
  
    local_dir = os.path.dirname(os.path.realpath(__file__))
    print("Copying docker-compose.yml to remote server")
    put(local_dir + "/docker-compose.yml", "/opt/hubot/gilfoyle/")

    print("Copying .env to remote server")
    put(local_dir + "/.env", "/opt/hubot/gilfoyle/")

    with cd('/opt/hubot/gilfoyle'):
      print("Pulling new docker image on remote server")
      run('/usr/local/bin/docker-compose pull')
    
    print("Restarting gilfoyle on remote server")
    run('sudo systemctl restart gilfoyle.service')