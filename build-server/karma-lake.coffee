Promise = require 'bluebird'
{createPatternObject} = require 'karma/lib/config'
{join, resolve} = require 'path'

karmaPrepend = []
karmaAppend = []
onRunComplete = ->

exitKarma = null

process.on 'lake_exit', ->
    exitKarma() if exitKarma?

# Capture Karmas SIGINT listener to be able to call it manually to stop server
EmitterWrapper = require 'karma/lib/emitter_wrapper'

_on = (event, listener) ->
    if event is 'SIGINT'
        exitKarma = listener
        EmitterWrapper::on = _on
    _on.apply this, arguments

[_on, EmitterWrapper::on] = [EmitterWrapper::on, _on]

lakeConfig = null

initLake = (_lakeConfig, files, browserNames, fileList, emitter, launcher, capturedBrowsers) ->
    lakeConfig = _lakeConfig

    # Publish Global Event Emitter
    lakeConfig.globalEmitter = emitter

    # Convert array of config-file-pattern to array of Pattern objects
    pattern = lakeConfig.files.map (f) ->
        f = resolve f if typeof f is 'string' or f instanceof String
        createPatternObject f

    # Find the 'marker' in official file list to memorize prepended and appended scripts from other frameworks
    marker = resolve lakeConfig.marker
    pos = null
    for p, i in files
        if p.pattern is marker
            pos = i
            break
    karmaPrepend = files.slice 0, i
    karmaAppend = files.slice i + 1
    files.splice i, 1, pattern...

    # Pass refresh function back to lake, allowing to re-run karma tests
    if lakeConfig.refresh?
        lakeConfig.refresh (_files) ->
            pattern = karmaPrepend.concat(_files.map (f) -> createPatternObject resolve f).concat karmaAppend
            fileList.reload(pattern, [])

    # memorize completion callback handler to pass-back test-results to lake
    if lakeConfig.onRunComplete?
        onRunComplete = lakeConfig.onRunComplete

    # monkey-patch browserCollections add, to get hold on new browser objects and add a 'onJserror' method, before init() is called on them.
    # That's the way we grap unhandled js errors
    # TODO find a better way
    _add = (browser) ->
        browser.jserrors ?= []
        browser.onJserror = (err) ->
            emitter.emit 'jserror', this, err
        _add.apply this, arguments
    [_add, capturedBrowsers.add] = [capturedBrowsers.add, _add]

    browsers = {}
    emitter.on 'browser_register', (browser) ->
        browsers[browser.id] = browser

    emitter.on 'browsers_change', (capturedBrowsers) ->
        known = {}
        capturedBrowsers.forEach (browser) ->
            known[browser.id] = browser
        for id, browser of browsers
            unless known[id]?
                console.log "We're missing %s, trying to restart", browser.name
                return if launcher.restart id
                console.error "Cannot restart %s, trying to exit karma", browser.name
                exitKarma() if exitKarma?

initLake.$inject = ['config.lake', 'config.files', 'config.browsers', 'fileList', 'emitter', 'launcher', 'capturedBrowsers']

log = null
suites = null
initBrowser = (browser) =>
    timestamp = (new Date()).toISOString().substr(0, 19);
    suites[browser.id] =
        browser: browser,
        timestamp: timestamp,
        testcases: []
        log: []
        errors: []

class Reporter
    cleanup: ->

    onRunStart: (browsers) ->
        log.debug 'onRunStart'
        @cleanup()
        suites = {}
        browsers.forEach initBrowser

    onBrowserStart: (browser) ->
        log.debug 'onBrowserStart'
        initBrowser browser

    onBrowserLog: (browser, msg, type) ->
        log.debug 'onBrowserLog'
        suite = suites?[browser.id]
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.
        suite.log.push {type, msg}

    onBrowserError: (browser, error) ->
        log.debug 'onBrowserError'
        @results?.error = true
        suite = suites?[browser.id]
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.
        suite.errors.push error

    onBrowserComplete: (browser) ->
        log.debug 'onBrowserComplete'
        suite = suites?[browser.id];
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.

        suite.result = browser.lastResult

    onRunComplete: (browsers, results) ->
        log.debug 'onRunComplete'
        cb = lakeConfig.callback
        @results = results
        @cleanup = ->
            cb null, suites, results
            @results = null
            suites = null
            @cleanup = ->

        # TODO rplan/lib/payment/client_test crashes chrome AFTER runComplete/browserComplete, which is registered in browserError, so we need to wait a few ms here
        setTimeout (=> @cleanup()), 500

    onSpecComplete: (browser, result) ->
        log.debug 'onSpecComplete'
        suite = suites?[browser.id]
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.
        suite.testcases.push result

reporterFactory = (logger, formatError, emitter, lakeConfig) ->
    log = logger.create 'reporter.lake'

    lakeConfig.formatError = formatError

    reporter = new Reporter
    emitter.on 'jserror', reporter.onBrowserError.bind reporter
    return reporter

reporterFactory.$inject = ['logger', 'formatError', 'emitter', 'config.lake']

module.exports =
    'framework:lake': ['factory', initLake]
    'reporter:lake': ['factory', reporterFactory]
