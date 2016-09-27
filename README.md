# <img src="https://raw.githubusercontent.com/WpgTech/gilfoyle/master/docs/gilfoyle.jpg" width="35px"/> Gilfoyle

Gilfoyle is a helpful chat bot that lives in the [Prairie Tech Slack instance](http://slack.prdcdeliver.com).

## What is Gilfoyle?
Gilfoyle is written in Coffeescript on `node.js`. He is based on the [Hubot framework](https://hubot.github.com/) originally written by Github.

## What can Gilfoyle do?
Gilfoyle can do a few things out of the box like posting images, and following people on twitter, but the real fun happens when you add your own scripts.

Gilfoyle could be programmed to do all sorts of things:
- Update JIRA issues
- Deploy to prod
- Check the bus schedule for you
- Tell you if its raining outside
- Take a food order for your team

The possibilities are endless!

## How do I write my own scripts?
It's easy to get started, follow the **hello world** example below

### Dependencies
- [Node.js](https://nodejs.org/en/download/) (version 0.10+) 

### Get the Code
- Fork [the repository](https://github.com/WpgTech/gilfoyle) to your own github account
- Clone the repo from your local fork to your machine

### Hack on the code
- Before you begin, you need to know that **whitespace matters** in coffeescript!
- Open up `src/jokes.coffee`.
- In the below code, when someone says `@gilfoyle i am tired`, he will respond with `Have a coffee ☕️`.
```
module.exports = (robot) ->
  robot.respond /i am tired/i, (msg) ->
    msg.send "Have a coffee :coffee:"
```
- Let's add to the script below. We'll add a listener so that when Gilfoyle **hears** anyone say `McDonalds`, he will insist that he needs a big mac.
```
module.exports = (robot) ->
  robot.respond /i am tired/i, (msg) ->
    msg.send "Have a coffee :coffee:"
    
  robot.hear /mcdonalds/i, (msg) ->
    msg.reply "Ooh! get me a big mac!"
```
- There are 2 different ways Gilfoyle can 'listen' for commands
  - `robot.respond` - Gilfoyle will be triggered only when his name is mentioned before the command.
  - `robot.hear` - Gilfoyle will be triggered by simply *hearing* the command.
- There are 2 different ways Gilfoyle can 'respond' to commands
  - `msg.reply` - Gilfoyle will reply to the user in the room.
  - `msg.send` - Gilfoyle will give a generic reply in the room.

- Let's test out our new commands before committing our code. Run Gilfoyle locally with `bin/hubot`

```
gilfoyle> gilfoyle i am tired                                                                                                          
Have a coffee :coffee:                                                                                                       

gilfoyle> @John, do you want to go get McDonalds?                                                                                      
Shell: Ooh! get me a big mac!      
```

- After you are satisfied with your new command, commit the code, and push it to your fork.
- Create a pull request to have your new code be merged back into this repository.
- Profit!!

## 3rd party scripts
- The Hubot scripting community is full of awesome scripts that are easy to install and have great functionality.
- You can [browse hubot scripts here](https://www.npmjs.com/browse/keyword/hubot-scripts)

### Installing a 3rd party script
- We'll walkthrough the steps we need to install a 3rd party script called [hubot-pwned](https://www.npmjs.com/package/hubot-pwned)
- Fork this Gilfoyle repo (if you haven't already) and clone it to your local machine
- Install the hubot-pwned script and save it to package.json
```
npm install hubot-pwned --save
```
- Add **hubot-pwned** to the array in `external-scripts.json`
```
[
  "hubot-pwned"
]
```
- Let's test out the new script we just added. Run Gilfoyle with `bin/hubot`
```
gilfoyle> has foo@bar.com been pwned?                                                                                                  
gilfoyle> Yes, foo@bar.com has been pwned :sob:
000webhost.com
acne.org
adobe.com
dropbox.com
```
- Commit the code, and push it to your fork of the Gilfoyle repo.
- Create a pull request to have your new code be merged back into this repository.

**A note about 3rd party scripts:**

Some scripts need environment variables set for API keys or other secrets.
If you want to install a scripts that has special requirements, reach out to the **#chatops** channel in the [Prairie Tech Slack Instance](http://slack.prdcdeliver.com) and someone there can help you out. 

## What's next?
- Check out the [Hubot scripting guide](https://hubot.github.com/docs/scripting/) for more details on how to get more out of your scripts.
- Check out the `scripts` directory to see more examples.

## Need help?
There are a few ways to get assistance:
- Create a [Github Issue](https://github.com/WpgTech/gilfoyle/issues/new).
- Reach out to the **#chatops** channel in the [Prairie Tech Slack Instance](http://slack.prdcdeliver.com)
- Ask Gilfoyle for help:
```
gilfoyle> @gilfoyle help                                                                                                                                                              
gilfoyle echo <text> - Reply back with <text>                                                                                                                                         
gilfoyle follow <@user> - gilfoyle will follow the specified twitter user and post to the current channel                                                                             
gilfoyle help - Displays all of the help commands that gilfoyle knows about.                                                                                                          
gilfoyle help <query> - Displays all help commands that match <query>.                                                                                                                
gilfoyle ping - Reply with pong                                                                            
```