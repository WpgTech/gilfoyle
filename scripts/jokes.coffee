# Description:
#   Responds with jokes
# 
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot I am tired - hubot will give you a coffee.
#   mcdonalds - Hubot will request a big mac.

module.exports = (robot) ->
  robot.respond /i am tired/i, (msg) ->
    msg.send "Have a coffee :coffee:"
  
  robot.hear /mcdonalds/i, (msg) ->
    msg.reply "Ooh! get me a big mac!"