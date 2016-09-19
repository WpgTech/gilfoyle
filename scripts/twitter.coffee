#  Description:
#    Make sure that hubot knows the rules.
#
#  Commands:
#    hubot follow <@user> - hubot will follow the specified twitter user and post to the current channel
#    hubot unfollow <@user> - hubot will unfollow the specified twitter user
#    hubot show following - hubot will list currently followed twitter users
#    hubot show ratelimit - hubot will show the current twitter api rate limit status (for debugging)
#    hubot show polling - hubt will show the current twitter polling interval
#    hubot watch <#hashtag> - hubot will watch twitter for a particular hashtag and post to the channel
#   
#
#  Notes:
#

# For following users - 180 rate limit
# https://dev.twitter.com/rest/reference/get/statuses/user_timeline

# For searching hashtags - 180 rate limit
# https://dev.twitter.com/rest/reference/get/search/tweets

Twit = require "twit"
async = require "async"

module.exports = (robot) ->
  #user-scope auth (needed for streams)
  TU = new Twit(
    consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY || 'foo',
    consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET || 'bar',
    access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN_KEY || 'foo',
    access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET || 'bar'
    )

  #App-scope auth (higher rate limits, but no streams)
  TA = new Twit(
    consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY || 'foo',
    consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET || 'bar',
    app_only_auth: true
    )

  TA.get('account/verify_credentials', skip_status: true).catch((err) ->
    robot.logger.error 'TWITTER AUTH ERROR', err.stack
    return
  ).then (result) ->
    # robot.logger.info "TWITTER AUTH RESULT: #{JSON.stringify result}" if result 
    return
  
  getUserTimeline = (user, since_id, count, cb) ->
    TA.get "statuses/user_timeline", {
      screen_name: user
      since_id: since_id ||= 1
      count: count ||= 1
      include_rts: true
      exclude_replies: false
    }, (err, data, response) ->
      if err
        return cb err
      return cb null, data
  
  updateMostRecentTweet = (user, mostRecent) ->
    twitterUsers = robot.brain.get "twitter.users"
    twitterUsers[user]["most_recent"] = mostRecent
    robot.brain.set "twitter.users", twitterUsers
  
  getUserTweet = (user, most_recent, cb) ->
    TA.get "statuses/user_timeline", {
      screen_name: user
      since_id: most_recent ||= 1
      count: 1
      include_rts: true
      exclude_replies: false
    }, (err, data, response) ->
      if err
        return cb err
      if data.length < 1
        robot.logger.debug "#{user}: No fresh tweets available"
        return cb null, null #not an error, but no fresh tweets were available
      updateMostRecentTweet(user, data[0]["id_str"])
      return cb null, data

  ingestTweets = () ->
    twitterUsers = robot.brain.get "twitter.users"
    if ! twitterUsers
      return robot.brain.set 'twitter.users', {}
    userList = []
    for user of twitterUsers
      userList.push user
    robot.logger.debug "Ingesting tweets for: #{userList}" if userList.length > 0
    async.each userList, ((user, callback) ->
      getUserTweet user, twitterUsers[user]['most_recent'], (err, tweets) ->
        if err
          robot.logger.error err
          return callback(err)
        if !tweets #tweets was empty, move on...
          return callback()
        robot.logger.debug "Found new tweet for #{tweets[0]["user"]["name"]}!"
        robot.messageRoom twitterUsers[user]["room_id"], ">*:twitter:#{tweets[0]["user"]["name"]}* @#{user}\n"+
                                                         ">#{(tweets[0]["text"]).replace(new RegExp('\r?\n','g'), '\n\>')}"
        callback()
      ), (err) ->
        robot.logger.error err if err
  
  calculatePollingInterval = (cb) ->
    twitterUsers = robot.brain.get 'twitter.users'
    numUsers = Object.keys(twitterUsers).length
    pollingInterval = Math.round((60 * 1000 * numUsers) / 10)
    pollingInterval = if pollingInterval < 10000 then 10000 else pollingInterval #set a sane minimum interval of 10 seconds
    robot.logger.info "Calculated polling interval: #{pollingInterval}ms"
    return cb pollingInterval
  
  globalPoll = 0
  brainLoaded = false
  robot.brain.on 'loaded', ->
    unless brainLoaded    
      robot.logger.info "inital brain load... initializing twitter data"
      brainLoaded = true
      ingestTweets()
      calculatePollingInterval (interval) ->
        globalPoll = setInterval ingestTweets, interval

  robot.respond /poll/i, (msg) ->
    ingestTweets

  robot.respond /show follow(ing)?/i, (msg) ->
    twitterUsers = robot.brain.get "twitter.users"
    if Object.keys(twitterUsers).length > 0
      usersMessage = ""
      for user, value of twitterUsers
        room = twitterUsers[user]["room_name"]
        usersMessage += "@#{user} - ##{room}\n"
      return msg.send "I'm following these people in these rooms:\n" +
                      "```#{usersMessage.trim()}```"
    msg.send "I'm not following anybody yet...\n" +
              "If you wan't me to follow someone, say `#{robot.name} follow slackhq`"
    

  robot.respond /follow (\S+)$/i, (msg) ->
    user = msg.match[1]
    user = user.toLowerCase()
    user = user.replace(/^\@*/,"") #remove any @ symbols at the beginning
    
    #get twitter users from brain and check if we are following already
    twitterUsers = robot.brain.get "twitter.users"
    if twitterUsers[user]
      return msg.send "I'm already following #{user}!"

    getUserTimeline user, 1, 1, (err, tweets) ->
      if err
        robot.logger.error err
        return msg.send "There was an error following #{user}. #{err}"
      if tweets.length < 1
        return msg.send "#{user} doesn't have any tweets yet. Tell #{user} to start tweetin', then I will follow them."
      
      mostRecentTweet = tweets[0]
      #this must be a new user, so we will store the username in the brain, along with their most recent tweet id
      twitterUsers[user] = {}
      twitterUsers[user]["most_recent"] = mostRecentTweet.id_str
      if !robot.adapter.client or !robot.adapter.client.rtm
        slackRoom = {id: msg.message.room, name: msg.message.room} #fake the data for local dev
      else
        slackRoom = robot.adapter.client.rtm.dataStore.getChannelGroupOrDMById(msg.message.room)

      if slackRoom.is_im # if you asked to follow somebody while in a DM
        twitterUsers[user]["room_name"] = "general" #we'll post the tweets to general instead of back to the DM
        twitterUsers[user]["room_id"] = "C264Y3Z9A" #hardcoded general channel as fallback... hacky, but ¯\_(ツ)_/¯
      else
        twitterUsers[user]["room_name"] = slackRoom.name
        twitterUsers[user]["room_id"] = slackRoom.id
      
      robot.brain.set "twitter.users", twitterUsers

      robot.logger.debug mostRecentTweet.id_str, mostRecentTweet.created_at, mostRecentTweet.text, mostRecentTweet.user.screen_name
      msg.send "Ok, I'll follow #{user} and post tweets to ##{twitterUsers[user]["room_name"]}. Here is *@#{user}*'s last tweet:\n" +
               ">*:twitter:#{mostRecentTweet.user.name}* @#{user}\n"+
               ">#{mostRecentTweet.text.replace(new RegExp('\r?\n','g'), '\n\>')}"
      
      #clear the current poller, then start the new one with the new polling interval
      clearInterval globalPoll
      calculatePollingInterval (interval) ->
        globalPoll = setInterval ingestTweets, interval

  robot.respond /unfollow (\S+)$/i, (msg) ->
    user = msg.match[1]
    user = user.toLowerCase() 
    user = user.replace(/^\@*/,"") #remove any @ symbols at the beginning

    twitterUsers = robot.brain.get "twitter.users"
    if !twitterUsers[user]
      return msg.send "I was never following #{user}."
    delete twitterUsers[user]
    robot.brain.set "twitter.users", twitterUsers
    msg.send "Ok, I'll unfollow #{user}."
    #clear the current poller, then start the new one with the new polling interval
    clearInterval globalPoll
    calculatePollingInterval (interval) ->
      globalPoll = setInterval ingestTweets, interval

  robot.respond /show poll(ing)?$/i, (msg) ->
    calculatePollingInterval (interval) ->
      msg.send "The current Twitter polling interval is #{interval}ms"
  
  robot.respond /show rate(\s?limit)?/i, (msg) ->
    TA.get "application/rate_limit_status", {
    # resources: "/statuses/user_timeline"
    }, (err, data, response) ->
      if err
        return msg.send "Error getting rate limit status #{err}"
      return msg.send "Application context limit for user statuses: #{JSON.stringify(data.resources.statuses["/statuses/user_timeline"])}"

  # robot.respond /watch (.*)/i, (msg) ->
    ############ TODO
    ############ put the streaming logic in its own function
    ############ execute it on brain load
    ############
    # hashtag = msg.match[1]
    # hashtag = hashtag.toLowerCase()
    # hashtag = hashtag.replace(/^\#*/,"") #remove any # symbols at the beginning
    
    # twitterHashtags = robot.brain.get 'twitter.hashtags'
    # if !twitterHashtags
    #   robot.brain.set 'twitter.hashtags', {}
    #   twitterHashtags = robot.brain.get 'twitter.hashtags'
    
    # if !robot.adapter.client or !robot.adapter.client.rtm
    #   slackRoom = {id: msg.message.room, name: msg.message.room} #fake the data for local dev
    # else
    #   slackRoom = robot.adapter.client.rtm.dataStore.getChannelGroupOrDMById(msg.message.room)

    # twitterHashtags[hashtag] = {}
    
    # if slackRoom.is_im # if you asked to follow somebody while in a DM
    #   twitterHashtags[hashtag]["room_name"] = "general" #we'll post the tweets to general instead of back to the DM
    #   twitterHashtags[hashtag]["room_id"] = "C264Y3Z9A" #hardcoded general channel as fallback... hacky, but ¯\_(ツ)_/¯
    # else
    #   twitterHashtags[hashtag]["room_name"] = slackRoom.name
    #   twitterHashtags[hashtag]["room_id"] = slackRoom.id
    
    # hashtags = []
    # for hashtag, value in twitterHashtags
    #   hashtags += hashtag

    # stream = TU.stream 'statuses/filter', { track: '#slack', language: 'en' }
    # stream.on 'tweet', (tweet) ->
    #   robot.logger.debug tweet.text
    #   msg.send ">*:twitter:#{tweet.user.name}* @#{tweet.user.screen_name}\n"+
    #            ">#{tweet.text.replace(new RegExp('\r?\n','g'), '\n\>')}"