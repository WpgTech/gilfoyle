GLOBAL.Promise= require('bluebird')
expect = require('chai').expect

Helper = require('hubot-test-helper')
helper = new Helper('../scripts/jokes.coffee')

describe 'jokes hubot script', ->
  beforeEach ->
    @room = helper.createRoom(httpd: false)

  describe 'i am tired', ->
    it 'should respond with caffeine', ->
      @room.user.say('jordan.neufeld', '@hubot i am tired').then =>
        expect(@room.messages).to.eql [
          ['jordan.neufeld', '@hubot i am tired']
          ['hubot', 'Have a coffee :coffee:']
        ]
    
  describe 'mcdonalds', ->
    it 'should insist a big mac is delivered', ->
      @room.user.say('jordan.neufeld', 'John, do you want mcdonalds for lunch?').then =>
        expect(@room.messages).to.eql [
          ['jordan.neufeld', 'John, do you want mcdonalds for lunch?']
          ['hubot', '@jordan.neufeld Ooh! get me a big mac!']
        ]