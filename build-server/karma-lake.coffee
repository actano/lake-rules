Promise = require 'bluebird'
{createPatternObject} = require 'karma/lib/config'
{join, resolve} = require 'path'

karmaPrepend = []
karmaAppend = []
onRunComplete = ->

exitKarma = null

WAIT_MS = Number(process.env['KARMA_WAIT_MS'] || '-1')

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

browsers = null

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
results = null
initResults = ->
    return results if results?
    results =
        suites: {}
        success: 0
        failed: 0
        skipped: 0
        error: false
        exitCode: 0

initBrowser = (browser) ->
    suite = initResults().suites[browser.id]
    return suite if suite?
    timestamp = (new Date()).toISOString().substr(0, 19);
    results.suites[browser.id] =
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
        initResults()
        browsers.forEach initBrowser

    onBrowserStart: (browser) ->
        log.debug 'onBrowserStart'
        initBrowser browser

    onBrowserLog: (browser, msg, type) ->
        log.debug 'onBrowserLog'
        initBrowser(browser).log.push {type, msg}

    onBrowserError: (browser, error) ->
        log.debug 'onBrowserError'
        unless results?
            log.error 'Browser %s got error outside of test-run, trying to restart', browser.name
            browser.kill()
            return
        initBrowser(browser).errors.push error
        results.error = true

    onBrowserComplete: (browser) ->
        log.debug 'onBrowserComplete'
        initBrowser(browser).result = browser.lastResult

    onRunComplete: (browsers, result) ->
        log.debug 'onRunComplete'
        return unless results?

        results.disconnected |= result.disconnected
        cb = lakeConfig.callback
        @cleanup = ->
            results.exitCode = if results.disconnected then 3 else if results.error then 2 else if results.failed then 1 else 0
            log.debug 'Setting exitCode to %s', results.exitCode
            cb null, results
            results = null
            @cleanup = ->

        if WAIT_MS < 0
            process.nextTick @cleanup.bind this
        else if WAIT_MS > 0
            setTimeout (@cleanup.bind this), WAIT_MS
        else
            @cleanup()

    onSpecComplete: (browser, result) ->
        log.debug 'onSpecComplete'
        return unless results?
        if result.skipped
            results.skipped++
        else if result.success
            results.success++
        else
            results.failed++
        initBrowser(browser).testcases.push result

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
