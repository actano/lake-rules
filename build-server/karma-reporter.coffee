WAIT_MS = Number(process.env['KARMA_WAIT_MS'] || '10000')

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

    onBrowserUnloaded: (browser) ->
        log.debug 'onBrowserUnloaded'
        suites = results?.suites
        return unless suites?
        suites[browser.id]?.unloaded = true
        for id, suite of suites
            return unless suite.unloaded
        log.debug 'All browsers unloaded'
        @cleanup()

    onRunComplete: (browsers, result) ->
        log.debug 'onRunComplete'
        return unless results?

        results.disconnected |= result.disconnected
        @cleanup = ->
            lakeEmitter = require './karma-helper'
                .emitter
            results.exitCode = if results.disconnected then 3 else if results.error then 2 else if results.failed then 1 else 0
            log.debug 'Setting exitCode to %s', results.exitCode
            lakeEmitter.emit 'results', results
            results = null
            clearTimeout _timeout
            @cleanup = ->

        if WAIT_MS < 0
            process.nextTick => @cleanup()
        else if WAIT_MS > 0
            _timeout = setTimeout (=> @cleanup()), WAIT_MS
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

reporterFactory = (logger, formatError, emitter) ->
    log = logger.create 'reporter.lake'
    log.debug 'init'

    helper = require './karma-helper'
    helper.formatError = formatError

    reporter = new Reporter
    emitter.on 'jserror', reporter.onBrowserError.bind reporter
    emitter.on 'browser_unloaded', reporter.onBrowserUnloaded.bind reporter
    return reporter

reporterFactory.$inject = ['logger', 'formatError', 'emitter']

module.exports = reporterFactory