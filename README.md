# Gilfoyle
Gilfoyle is a helpful chat bot based on the [hubot](https://hubot.github.com/) framework.


## Production deploy
- Ensure that `docker` and `docker-compose` are installed on the production server
- Create dir for redis `mkdir -p /opt/data/redis`
- git clone/update repo on server
- Add `.env` file to repo directory with necessary environment vars. See `example.env`.
- launch: `docker-compose up -d`

## Env variables
- Get the [openshift client tools](https://developers.openshift.com/managing-your-applications/client-tools.html)
- ```rhc setup```
- ```rhc env set -a gilfoyle KEY=value```
- ```rhc env list -a gilfoyle```
