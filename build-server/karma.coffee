fs = require 'fs'
Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
{join, resolve, dirname, basename} = require 'path'

FAIL_FAST = process.env['FAIL_FAST'] isnt '0'
TEST_REPORTS = process.env['TEST_REPORTS']
BROWSERS = (process.env['KARMA_BROWSERS'] || '').split(/\s+/).filter (s) -> s isnt ''

refresh = null
onRunComplete = null
MARKER = join __dirname, __filename

# TODO this should come from some config
HTML_TEMPLATE = resolve 'tools/karma-html-template.js'

karmaOptions =
    port: 9876
#    logLevel: 'DEBUG'
    basePath: '' # current cwd
    files: [{pattern: MARKER, included: false, served: false, watched: false}]
    lake:
        refresh: (fn) -> refresh = fn
        marker: MARKER
        onRunComplete: (suites, results) ->
            if onRunComplete?
                onRunComplete(suites, results)
                onRunComplete = null
    frameworks: ['mocha', 'sinon-chai', 'chai', 'chai-as-promised', 'jquery-2.1.0', 'lake']
    reporters: ['progress','lake']
    jenkinsReporter:
        classnameSuffix: 'browser-test'
    browsers: BROWSERS

    # We DO NOT want to use preprocessors here, e.g. coffee-preprocessor overwrites current used coffee-script with it's own old version
    # TODO: this result into an error in the vm:
    # failed to proxy /base/build/local_components/lib/new-schedulemanager/tree-row/component-build/fortawesome/font-awesome/v4.2.0/fonts/fontawesome-webfont.woff?v=4.2.0 (connect ECONNREFUSED)
    # proxies:
    #     '/': '/' # proxy all fonts and other assets

startServer = (_files) ->
    {server} = require 'karma'
    karmaOptions.lake.files = _files
    karmaOptions.plugins = ['karma-*', require './karma-lake']

    server.start karmaOptions, (code) ->
        console.error 'Karma exited with code %s', code if code
        refresh = null

    if BROWSERS.length == 0
        console.log 'Connect your browsers and press RETURN'


runKarma = Promise.coroutine (_files) ->
    if BROWSERS.length is 0 and not process.stdout.isTTY
        console.error 'You have no browsers configured and try to run without tty, this is considered not good'
        return Promise.resolve [null, {error: true, exitCode: 4}]

    promise = Promise.fromNode (callback) ->
        karmaOptions.lake.callback = callback
    if refresh?
        refresh _files
    else
        startServer _files

    [suites, results] = yield promise
    if results?
        results.exitCode = mapExitCode results
    else
        results = exitCode: 5

    return [suites, results]

mapExitCode = (results) ->
    unless FAIL_FAST
        return 2 if results.disconnected
        return 3 if results.error
        return 0

    if results.exitCode is 0
        return 2 if results.disconnected
        return 3 if results.error
        return 1 if results.failures > 0
    return results.exitCode

karma = Promise.coroutine (makeTarget, srcFile, reportFile, assetspath, testFiles) ->
    writer = require('./karma-jenkins-writer')

    assets = [
        # karma-html-template needs to be loaded before testFiles
        HTML_TEMPLATE
        "#{assetspath}/**/*.js"
        "#{assetspath}/**/*.css"
    ]

    pkgName = dirname(reportFile).replace /\//g, '.'
    className = basename reportFile

    [suites, results] = yield runKarma assets.concat testFiles

    if suites?
        xml = writer(suites, results, "#{pkgName}.#{className}", makeTarget, karmaOptions.lake.formatError)

        reportFile = join TEST_REPORTS, reportFile if TEST_REPORTS?
        yield mkdirp dirname reportFile
        yield fs.writeFileAsync reportFile, xml

    results.exitCode

module.exports = {karma}

