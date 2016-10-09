# Description:
#   Displays Deliver current presentors, next presentors or full schedule
#
#
# Dependencies:
#  "cheerio": "^0.20.0"
#  "needle": "^1.0.0"
#  "async": "^1.5.2",
#  "moment": "^2.15.1"
#
# Commands:
#   hubot who is speaking now? - Displays all presenters currently speaking
#	hubot who is speaking next? - Displays all presenters speaking next
#	hubot schedule - Displays full schedule
#
# Author:
#  Derek Richard
#

needle = require('needle');
cheerio = require('cheerio');
moment = require("moment")
_ = require('lodash')
async = require('async')
html2json = require('html2json').html2json

now = new moment()

retrieveSchedule = (day, callback) ->
	needle.get 'http://www.prdcdeliver.com/Schedule', (err, resp) ->
		scheduleJSON = []
		events = html2json(cheerio.load((resp.body).replace(/(?:\r\n|\r|\n)/g,""))('#' + day).children().html())
		events = cleanArray(events.child)
		_.forEach events, (event) ->
			if event.tag != 'h2'
				scheduleEvent = {}
				scheduleEvent.speakers = []
				timeslots = cleanArray(event.child)
				_.forEach timeslots, (timeslot) ->
					if timeslot.tag == "h3"
						times = /(\d*\:\d* (?:AM|PM)) \- (\d*\:\d* (?:AM|PM))/.exec(timeslot.child[0].text)
						scheduleEvent.starttime = times[1]
						scheduleEvent.endtime = times[2]
					else if timeslot.tag != 'hr'
						speaker = cleanArray(timeslot.child)
						speakerInfo = {}
						speakerInfo.name = speaker[2].child[0].text.trim()
						speakerInfo.location = speaker[0].child[0].text.trim()
						speakerInfo.title = speaker[1].child[0].text.trim()
						scheduleEvent.speakers.push(speakerInfo)
				scheduleJSON.push(scheduleEvent)
		callback null, scheduleJSON
		
cleanArray = (array) ->
	_.filter array, (event) ->
			return !event.text || event.text.trim() == null

buildScheduleJSON = (cb) ->
	async.parallel {
		wednesday: (cb) ->
			retrieveSchedule 'Wednesday', cb
		thursday: (cb) ->
			retrieveSchedule 'Thursday', cb
	}, (err, results) ->
		if err
			console.log("ERROR" + err)
		else
			cb results

fullSchedule = (msg) ->
	buildScheduleJSON (scheduleData) ->
		console.log(scheduleData)


module.exports = (robot) ->
  robot.respond /(schedule)/i, (msg) ->
  	fullSchedule(msg)