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
#	hubot schedule (Wednesday|Thursday)- Displays full schedule for requested day
#
# Author:
#  Derek Richard
#

needle = require('needle');
cheerio = require('cheerio');
moment = require("moment-timezone")
_ = require('lodash')
async = require('async')
html2json = require('html2json').html2json
table = require('easy-table')

retrieveSchedule = (dayOfWeek, date, callback) ->
	needle.get 'http://www.prdcdeliver.com/Schedule', (err, resp) ->
		scheduleJSON = []
		events = html2json(cheerio.load((resp.body).replace(/(?:\r\n|\r|\n)/g,""))('#' + dayOfWeek).children().html())
		events = cleanArray(events.child)
		_.forEach events, (event) ->
			if event.tag != 'h2'
				scheduleEvent = {}
				scheduleEvent.speakers = []
				timeslots = cleanArray(event.child)
				_.forEach timeslots, (timeslot) ->
					if timeslot.tag == "h3"
						times = /(\d*\:\d* (?:AM|PM)) \- (\d*\:\d* (?:AM|PM))/.exec(timeslot.child[0].text)
						scheduleEvent.starttime = new moment(date + " " + times[1],'MMM D YYYY h:mm a')
						scheduleEvent.endtime = new moment(date + " " + times[2],'MMM D YYYY h:mm a')
					else if timeslot.tag != 'hr'
						speaker = cleanArray(timeslot.child)
						speakerInfo = {}
						speakerInfo.name = speaker[2].child[0].text.trim()
						speakerInfo.location = speaker[0].child[0].text.trim()
						speakerInfo.title = speaker[1].child[0].text.trim()
						scheduleEvent.speakers.push(speakerInfo)
				scheduleJSON.push(scheduleEvent)
		callback scheduleJSON
		
cleanArray = (array) ->
	_.filter array, (event) ->
			return !event.text || event.text.trim() == null

buildScheduleJSON = (cb) ->
	retrieveSchedule 'Wednesday','Oct 12 2016', (results) ->
		retrieveSchedule 'Thursday','Oct 13 2016', (thuResults) ->
			Array.prototype.push.apply(results, thuResults);
			cb results

formatData = (data) ->
	schedule = ""
	_.forEach data, (timeslot) ->
		schedule += timeslot.starttime.format('h:mm A') + " - " + timeslot.endtime.format('h:mm A') + "\n"
		t = new table
		_.forEach timeslot.speakers, (speaker) ->
			t.cell 'Title', speaker.title
			t.cell 'Location', speaker.location
			t.cell 'Speaker', speaker.name 
			t.newRow()
		schedule += t.print() + "\n"
	return schedule

daySchedule = (msg, name) ->
	if msg.match[1].search(/(Wed|Thu)\w*/i) >= 0
		day = msg.match[1].replace /\w\S*/g, (txt) -> 
			return txt.charAt(0).toUpperCase() + txt.substr(1,2).toLowerCase()
		dayDisplay = if day=='Wed' then "Wednesday" else "Thursday"
		buildScheduleJSON (scheduleData) ->
			async.filter scheduleData, (timeslot, cb) ->
				cb null, timeslot.starttime.format('ddd') == day
			, (err, results) ->
				msg.send "*Daily Schedule for #{dayDisplay}*```#{formatData(results)}```"
	else
		msg.send "Uhh, the conference is only Wednesday and Thursday. You can ask me for something like `#{name} schedule wednesday`"

currentSpeakers = (msg) ->
	now = new moment()
	buildScheduleJSON (scheduleData) ->
		speakers = _.find scheduleData, (timeslot) ->
			return timeslot.starttime.isBefore(now) && timeslot.endtime.isAfter(now)
		if speakers
			msg.send "*The following sessions are happening now*```#{formatData([speakers])}```"
		else
			msg.send "Currently there are no sessions"

nextSpeakers = (msg) ->
	now = new moment()
	buildScheduleJSON (scheduleData) ->
		speakers = _.find scheduleData, (timeslot) ->
			return timeslot.starttime.isAfter(now)
		if speakers
			msg.send "*The following sessions are upcoming*```#{formatData([speakers])}```"
		else
			msg.send "There are no upcoming sessions"

module.exports = (robot) ->
	robot.respond /schedule (.*)/i, (msg) ->
		daySchedule(msg, robot.name)

	robot.respond /((who'?s?|who is)\s*(?:speaking)?\s*now)/i, (msg) ->
  		currentSpeakers(msg)

	robot.respond /((who'?s?|who is)\s*(?:speaking)?\s*next)/i, (msg) ->
  		nextSpeakers(msg)
