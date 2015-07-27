fs = require 'fs'
Promise = require 'bluebird'
{join, dirname, basename} = require 'path'
mkdirp = require 'mkdirp'
    .sync

TEST_REPORTS = process.env['TEST_REPORTS']
FAIL_FAST = process.env['FAIL_FAST'] isnt '0'

class Reporter
    constructor: (@log, @formatError, @target) ->
        @results =
            suites: {}
            success: 0
            failed: 0
            skipped: 0
            error: false
            exitCode: 0

    initBrowser: (browser) ->
        suite = @results.suites[browser.id]
        return suite if suite?
        timestamp = (new Date()).toISOString().substr(0, 19);
        @results.suites[browser.id] =
            browser: browser,
            timestamp: timestamp,
            testcases: []
            log: []
            errors: []

    onRunStart: (browsers) ->
        @log.debug 'onRunStart'
        browsers.forEach (b) => @initBrowser b

    onBrowserStart: (browser) ->
        @log.debug 'onBrowserStart'
        @initBrowser browser

    onBrowserLog: (browser, msg, type) ->
        @log.debug 'onBrowserLog'
        @initBrowser(browser).log.push {type, msg}

    onBrowserError: (browser, error) ->
        @log.debug 'onBrowserError'
        @initBrowser(browser).errors.push error
        @results.error = true

    onBrowserComplete: (browser) ->
        @log.debug 'onBrowserComplete'
        @initBrowser(browser).result = browser.lastResult

    onRunComplete: (browsers, result) ->
        @log.debug 'onRunComplete'
        return unless result?

        result.disconnected |= result.disconnected
        result.exitCode = if result.disconnected then 3 else if result.error then 2 else if result.failed then 1 else 0
        @log.debug 'Setting exitCode to %s', result.exitCode
        @writeResults result
        result.exitCode = 0 if result.exitCode is 1 and not FAIL_FAST

    onSpecComplete: (browser, result) ->
        @log.debug 'onSpecComplete'
        if result.skipped
            result.skipped++
        else if result.success
            result.success++
        else
            result.failed++
        @initBrowser(browser).testcases.push result

    writeResults: (result) ->
        result.exitCode = 5 unless @results.suites?
        if @results.suites?
            reportFile = "#{@target}.xml"
            writer = require('./karma-jenkins-writer')
            pkgName = dirname(reportFile).replace /\//g, '.'
            className = basename reportFile, '.xml'

            if pkgName?.length > 0 and pkgName isnt '.'
                className = "#{pkgName}.#{className}"

            xml = writer(@results, className, @target, @formatError)

            reportFile = join TEST_REPORTS, reportFile if TEST_REPORTS?
            mkdirp dirname reportFile
            fs.writeFileSync reportFile, xml

reporterFactory = (logger, formatError, emitter, target) ->
    log = logger.create 'reporter.lake'
    log.debug 'init'

    reporter = new Reporter log, formatError, target
    emitter.on 'jserror', reporter.onBrowserError.bind reporter
    return reporter

reporterFactory.$inject = ['logger', 'formatError', 'emitter', 'config.makeTarget']

module.exports = reporterFactory