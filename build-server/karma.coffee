Promise = require 'bluebird'

karma = (target, src) ->
    src = src.split ' '
    karmaServer = require './karma-server'
    karmaServer.run src, target

module.exports =
    karma: karma

