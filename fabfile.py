# Usage
# fab --disable-known-hosts -f fabfile.py --hosts $SSH_HOST -u $SSH_USER -p $SSH_PASSWORD deploy
from fabric.api import *
import os
import sys
from fabric.contrib.project import rsync_project
from fabric.contrib.console import confirm

env.forward_agent = True

def deploy():
    result=run("uname -a")

    if result.succeeded:
      print "[PASSED] Connecting to remote server "+env.host_string
    else:
      print "[FAILED] Could *not* ssh into server "+env.host_string+"! Please fix the auto-ssh issue. Exiting!";
      sys.exit(1)

    run("whoami")
    
    local_dir = os.path.dirname(os.path.realpath(__file__))
    print("Copying docker-compose.yml to server")
    put(local_dir + "/docker-compose.yml", '/opt/hubot/gilfoyle/')
    run('sudo systemctl restart gilfoyle')