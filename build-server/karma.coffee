Promise = require 'bluebird'
{join, resolve} = require 'path'
#         runner = "$(KARMA_RUNNER) --path #{featurePath} --browsers Chrome --assetspath #{componentBuildTargets.targetDst} #{manifest.client.tests.browser.scripts.join(' ')} --singlerun"

{SINGLERUN} = process.env

_server = null
startServer = ->
    return _server if _server?
    {server} = require 'karma'
    options =
        port: 9876
        basePath: resolve '.'
        browsers: ['Chrome']
        singleRun: false

    _server = server.start options, (code) ->
        console.error 'Karma exited with code %s', code
        _server = null

karma = Promise.coroutine (makeTarget, srcFile, reportFile, path, assetspath, scripts...) ->
    {prepareTest, exitCallback, cleanup} = require './test'

    reportFile = yield prepareTest makeTarget, reportFile

    {server, runner} = require 'karma'

    assets = [
        # karma-html-template needs to be loaded before testFiles
        resolve 'tools/karma-html-template.js'
        "#{assetspath}/**/*.js"
        "#{assetspath}/**/*.css"
    ]

    testFiles = scripts.map (testFile) ->
        join path, testFile

    options =
        port: 9876
        files: assets.concat testFiles
        basePath: '' # current cwd
        frameworks: ['mocha', 'sinon-chai', 'chai', 'chai-as-promised', 'jquery-2.1.0']
        preprocessors:
            '**/*.coffee': ['coffee'] # for test files
        reporters: ['progress', 'jenkins']
        jenkinsReporter:
            classnameSuffix: 'browser-test'
        browsers: ['Chrome']
        singleRun: true
        # TODO: this result into an error in the vm:
        # failed to proxy /base/build/local_components/lib/new-schedulemanager/tree-row/component-build/fortawesome/font-awesome/v4.2.0/fonts/fontawesome-webfont.woff?v=4.2.0 (connect ECONNREFUSED)
        # proxies:
        #     '/': '/' # proxy all fonts and other assets

    cb = exitCallback()

    server.start options, cb
    code = yield cb.Promise
    cleanup reportFile, code

module.exports = {karma}

