Promise = require 'bluebird'
helper = require './karma-helper'
{join} = require 'path'

FAIL_FAST = process.env['FAIL_FAST'] isnt '0'
BROWSERS = (process.env['KARMA_BROWSERS'] || '').split(/\s+/).filter (s) -> s isnt ''
LOG_LEVEL = process.env['KARMA_LOG_LEVEL']
REUSE_COUNT = Number(process.env['KARMA_REUSE_COUNT'] || 20)
TIMEOUT = Number(process.env['KARMA_TIMEOUT'] || 60) * 1000

karmaOptions =
    browsers: BROWSERS
    configFile: join __dirname, 'karma.conf.coffee'

if LOG_LEVEL?
    karmaOptions.logLevel = LOG_LEVEL

karmaServer = null

startServer = (_files) ->
    {server} = require 'karma'
    karmaOptions.files = _files
    new Promise (resolve, reject) ->
# Capture Karmas SIGINT listener to be able to call it manually to stop server
        EmitterWrapper = require 'karma/lib/emitter_wrapper'

        _on = EmitterWrapper::on
        EmitterWrapper::on = (event, listener) ->
            if event is 'SIGINT'
                helper.exit = ->
                    helper.refresh = null
                    listener?()
                    listener = null
                EmitterWrapper::on = _on
            _on.apply this, arguments

        server.start karmaOptions, (code) ->
            return resolve() if code is 0

            err = new Error "Karma exited with code #{code}"
            console.error err.message
            reject err

        if BROWSERS.length == 0
            console.log 'Connect your browsers and press RETURN'
    .finally ->
        helper.exit = ->
        helper.refresh = null

runKarma = Promise.coroutine (_files) ->
    if BROWSERS.length is 0 and not process.stdout.isTTY
        console.error 'You have no browsers configured and try to run without tty, this is considered not good'
        return Promise.resolve [null, {error: true, exitCode: 4}]

    promise = new Promise (resolve, reject) ->
        emitter = helper.emitter
        emitter.once 'results', (results) ->
            reject = null
            resolve results

        refresh = helper.refresh
        if refresh? and karmaServer?.isPending()
            refresh _files
        else
            karmaServer = startServer _files
            karmaServer.runCount = 0
        karmaServer.runCount++
        karmaServer.then ->
            reject? new Error('Karma quit unexpected')
        karmaServer.catch (err) ->
            reject? err

    promise = promise.timeout TIMEOUT
    results = yield promise
    results.exitCode = 5 unless results.suites?
    results.exitCode = 0 if results.exitCode is 1 and not FAIL_FAST
    if karmaServer.runCount >= REUSE_COUNT
        console.log 'Karma ran %s times, quitting ...', karmaServer.runCount
        helper.exit()
        yield karmaServer
    return results


module.exports.run = runKarma