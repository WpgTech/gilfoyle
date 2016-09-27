## Server environment setup:
- Ensure that `docker` and `docker-compose` are installed and running
- Create dir for redis `mkdir -p /opt/data/redis`
- Clone the repo `mkdir -p /opt/hubot && git clone https://github.com/WpgTech/gilfoyle.git /opt/hubot/gilfoyle`
- Add `.env` file to `/opt/hubot/gilfoyle` with necessary environment vars. See `example.env`
- Install the systemd init script `shell/gilfoyle.service` to `/etc/systemd/system/gilfoyle.service`
- Enable the service `systemctl enable gilfoyle.service`
- Start the bot `systemctl start gilfoyle.service`

## Deploy new code automatically:
- Travis CI will automatically do it for you on every push to the master branch.
- See `.travis.yml` and `fabfile.py` for specifics.

## Deploy new code manually:
- SSH to the server, switch to the webapps user `su - webapps`
- Add/Update any new environment variables in `/opt/hubot/gilfoyle/.env`
- `cd /opt/hubot/gilfoyle && git pull origin master`
- Restart the bot `sudo systemctl restart gilfoyle.service`

#to build it
docker build . -t gilfoyle

#to test it
docker run gilfoyle /usr/local/bin/npm test

#to run it (interactively)
docker run -it --env-file .env gilfoyle
