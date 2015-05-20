{createPatternObject} = require 'karma/lib/config'
{join, resolve} = require 'path'

karmaPrepend = []
karmaAppend = []
onRunComplete = ->

initLake = (launcher, fileList, files, lakeConfig) ->
    pattern = lakeConfig.files.map (f) ->
        f = resolve f if typeof f is 'string' or f instanceof String
        createPatternObject f
    marker = resolve lakeConfig.marker
    pos = null
    for p, i in files
        if p.pattern is marker
            pos = i
            break
    karmaPrepend = files.slice 0, i
    karmaAppend = files.slice i + 1
    files.splice i, 1, pattern...

    if lakeConfig.refresh?
        lakeConfig.refresh (_files) ->
            pattern = karmaPrepend.concat(_files.map (f) -> createPatternObject resolve f).concat karmaAppend
            fileList.reload(pattern, [])

    if lakeConfig.onRunComplete?
        onRunComplete = lakeConfig.onRunComplete

initLake.$inject = ['launcher', 'fileList', 'config.files', 'config.lake']

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
    constructor: (@formatError, emitter) ->
        emitter.on 'jserror', (browser, error) =>
            @onBrowserError browser, error

    onRunStart: (browsers) ->
        log.debug 'onRunStart'
        suites = {}
        browsers.forEach initBrowser

    onBrowserStart: (browser) ->
        log.debug 'onBrowserStart'
        initBrowser browser

    onBrowserLog: (browser, msg, type) ->
        log.debug 'onBrowserLog'
        suite = suites[browser.id]
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.
        suite.log.push {type, msg}

    onBrowserError: (browser, error) ->
        suite = suites[browser.id]
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.
        suite.errors.push error

    onBrowserComplete: (browser) ->
        log.debug 'onBrowserComplete'
        suite = suites[browser.id];
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.

        suite.result = browser.lastResult

    onRunComplete: (browsers, results) ->
        log.debug 'onRunComplete'
        results.formatError = @formatError # TODO find another way to pass it out here for formatting of errors
        onRunComplete suites, results
        suites = null

    onSpecComplete: (browser, result) ->
        log.debug 'onSpecComplete'
        suite = suites[browser.id]
        return unless suite? # This browser did not signal `onBrowserStart`. That happens if the browser timed out duging the start phase.
        suite.testcases.push result

reporterFactory = (logger, formatError, emitter, capturedBrowsers) ->
    log = logger.create 'reporter.lake'

    # monkey-patch browserCollections add, to get hold on new browser objects and add a 'onJserror' method, before init() is called on them.
    # That's the way we grap unhandled js errors
    # TODO find a better way
    _add = (browser) ->
        browser.jserrors ?= []
        browser.onJserror = (err) ->
            emitter.emit 'jserror', this, err
        _add.apply this, arguments
    [_add, capturedBrowsers.add] = [capturedBrowsers.add, _add]

    return new Reporter(formatError, emitter)

module.exports =
    'framework:lake': ['factory', initLake]
    'reporter:lake': ['factory', reporterFactory]
