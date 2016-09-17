docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
docker tag gilfoyle wpgtech/gilfoyle:latest
docker push wpgtech/gilfoyle:latest
fab --disable-known-hosts -f fabfile.py --hosts $SSH_HOST -u $SSH_USER -p $SSH_PASSWORD deploy