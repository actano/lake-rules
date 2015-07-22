Promise = require 'bluebird'
{join} = require 'path'

BROWSERS = (process.env['KARMA_BROWSERS'] || '').split(/\s+/).filter (s) -> s isnt ''
LOG_LEVEL = process.env['KARMA_LOG_LEVEL']
TIMEOUT = Number(process.env['KARMA_TIMEOUT'] || 60) * 1000

karmaOptions =
    browsers: BROWSERS
    configFile: join __dirname, 'karma.conf.coffee'

if LOG_LEVEL?
    karmaOptions.logLevel = LOG_LEVEL

runKarma = (_files, target) ->
    if BROWSERS.length is 0 and not process.stdout.isTTY
        console.error 'You have no browsers configured and try to run without tty, this is considered not good'
        return Promise.resolve 4

    karmaOptions.files = _files
    karmaOptions.makeTarget = target

    {server} = require 'karma'
    promise = new Promise (resolve) ->
        server.start karmaOptions, (code) ->
            resolve code

        if BROWSERS.length == 0
            console.log 'Connect your browsers and press RETURN'

    promise.timeout TIMEOUT

module.exports.run = runKarma