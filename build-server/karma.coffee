fs = require 'fs'
Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
{join, resolve, dirname, basename} = require 'path'

FAIL_FAST = process.env['FAIL_FAST'] isnt '0'
TEST_REPORTS = process.env['TEST_REPORTS']

refresh = null
onRunComplete = null
MARKER = join __dirname, __filename

# TODO this should come from some config
HTML_TEMPLATE = resolve 'tools/karma-html-template.js'

startServer = (_files) ->
    return refresh _files if refresh?
    {server} = require 'karma'

    # We DO NOT want to use preprocessors here, e.g. coffee-preprocessor overwrites current used coffee-script with it's own old version
    options =
        port: 9876
#        logLevel: 'DEBUG'
        basePath: '' # current cwd
        files: [{pattern: MARKER, included: false, served: false, watched: false}]
        lake:
            refresh: (fn) -> refresh = fn
            files: _files
            marker: MARKER
            onRunComplete: (suites, results) ->
                if onRunComplete?
                    onRunComplete(suites, results)
                    onRunComplete = null
        frameworks: ['mocha', 'sinon-chai', 'chai', 'chai-as-promised', 'jquery-2.1.0', 'lake']
        reporters: ['progress','lake']
        jenkinsReporter:
            classnameSuffix: 'browser-test'
        browsers: ['Chrome']
        plugins: ['karma-*', require './karma-lake']
        # TODO: this result into an error in the vm:
        # failed to proxy /base/build/local_components/lib/new-schedulemanager/tree-row/component-build/fortawesome/font-awesome/v4.2.0/fonts/fontawesome-webfont.woff?v=4.2.0 (connect ECONNREFUSED)
        # proxies:
        #     '/': '/' # proxy all fonts and other assets

    server.start options, (code) ->
        console.error 'Karma exited with code %s', code if code
        refresh = null

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

    promise = new Promise (resolve) ->
        onRunComplete = (suites, results) ->
            resolve [suites, results]

    startServer assets.concat testFiles
    [suites, results] = yield promise

    xml = writer(suites, results, "#{pkgName}.#{className}", makeTarget)

    reportFile = join TEST_REPORTS, reportFile if TEST_REPORTS?
    yield mkdirp dirname reportFile
    yield fs.writeFileAsync reportFile, xml

    mapExitCode results

module.exports = {karma}

