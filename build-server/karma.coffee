fs = require 'fs'
Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
{join, resolve, dirname, basename} = require 'path'

FAIL_FAST = process.env['FAIL_FAST'] isnt '0'
TEST_REPORTS = process.env['TEST_REPORTS']
BROWSERS = (process.env['KARMA_BROWSERS'] || '').split(/\s+/).filter (s) -> s isnt ''
LOG_LEVEL = process.env['KARMA_LOG_LEVEL']

# TODO this should come from some config
HTML_TEMPLATE = resolve 'tools/karma-html-template.js'

karmaOptions =
    browsers: BROWSERS
    configFile: join __dirname, 'karma.conf.coffee'

if LOG_LEVEL?
    karmaOptions.logLevel = LOG_LEVEL

rejectRun = null

startServer = (_files) ->
    {server} = require 'karma'
    karmaOptions.files = _files
    server.start karmaOptions, (code) ->
        err = new Error "Karma exited with code #{code}"
        console.error err if code
        rejectRun err if rejectRun?

    if BROWSERS.length == 0
        console.log 'Connect your browsers and press RETURN'


runKarma = Promise.coroutine (_files) ->
    if BROWSERS.length is 0 and not process.stdout.isTTY
        console.error 'You have no browsers configured and try to run without tty, this is considered not good'
        return Promise.resolve [null, {error: true, exitCode: 4}]

    promise = new Promise (resolve, reject) ->
        rejectRun = ->
            rejectRun = null
            reject.apply this, arguments

        emitter = require './karma-helper'
            .emitter
        emitter.once 'results', (results) ->
            rejectRun = null
            resolve results
    refresh = require './karma-helper'
        .refresh
    if refresh?
        refresh _files
    else
        startServer _files

    results = yield promise
    results.exitCode = 5 unless results.suites?
    results.exitCode = 0 if results.exitCode is 1 and not FAIL_FAST
    return results

writeResults = Promise.coroutine (reportFile, results, makeTarget) ->
    if results.suites?
        writer = require('./karma-jenkins-writer')
        {formatError} = require './karma-helper'
        pkgName = dirname(reportFile).replace /\//g, '.'
        className = basename reportFile, '.xml'

        xml = writer(results, "#{pkgName}.#{className}", makeTarget, formatError)

        reportFile = join TEST_REPORTS, reportFile if TEST_REPORTS?
        yield mkdirp dirname reportFile
        yield fs.writeFileAsync reportFile, xml

    results.exitCode

karma = Promise.coroutine (makeTarget, srcFile, reportFile, assetspath, testFiles...) ->
    assets = [
        # karma-html-template needs to be loaded before testFiles
        HTML_TEMPLATE
        "#{assetspath}/**/*.js"
        "#{assetspath}/**/*.css"
    ]

    results = yield runKarma assets.concat testFiles

    writeResults reportFile, results, makeTarget

karmaWebpack = Promise.coroutine (target, src) ->
    results = yield runKarma [HTML_TEMPLATE, src]
    writeResults "#{src}.xml", results, target

module.exports =
    karma: karma
    'karma-webpack': karmaWebpack

