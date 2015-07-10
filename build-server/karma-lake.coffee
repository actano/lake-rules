Promise = require 'bluebird'
{createPatternObject} = require 'karma/lib/config'
{join, resolve} = require 'path'
helper = require './karma-helper'

karmaPrepend = []
karmaAppend = []

process.on 'lake_exit', ->
    helper.exit()

# Monkey Patch karma-webpack
# @waiting is set to null after first compile, which prohibits waiting for recompilation on further reads
try
    {webpackPlugin} = require 'karma-webpack'
    Plugin = webpackPlugin[1]
    _addFile = Plugin::addFile
    Plugin::addFile = ->
        if _addFile.apply this, arguments
            @waiting = [] unless @waiting?
            return true
catch err
    console.error 'Cannot patch karma-webpack: %s', err.stack

browsers = null
MARKER1 = createPatternObject resolve __dirname, 'MARKER1'
MARKER2 = createPatternObject resolve __dirname, 'MARKER2'

patchBrowsers = (logger, emitter, capturedBrowsers, launcher) ->
    log = logger.create 'lake-jserror'
    log.debug 'init lake-jserror'
    # monkey-patch browserCollections add, to get hold on new browser objects and add a 'onJserror' method, before init() is called on them.
    # That's the way we grap unhandled js errors
    # TODO find a better way
    _add = capturedBrowsers.add
    capturedBrowsers.add = (browser) ->
        browser.jserrors ?= []
        browser.onJserror = (err) ->
            log.debug 'received jserror %s for %s', err, this
            emitter.emit 'jserror', this, err

        _onInfo = browser.onInfo
        browser.onInfo = (info) ->
            if info.unloaded
                emitter.emit 'browser_unloaded', this, info
            _onInfo.apply this, arguments
        _add.apply this, arguments

    browsers = {}
    emitter.on 'browser_register', (browser) ->
        browsers[browser.id] = browser

    emitter.on 'browsers_change', (capturedBrowsers) ->
        known = {}
        capturedBrowsers.forEach (browser) ->
            known[browser.id] = browser
        for id, browser of browsers
            unless known[id]?
                log.info "We're missing %s, trying to restart", browser.name
                return if launcher.restart id
                log.error "Cannot restart %s, trying to exit karma", browser.name
                helper.exit()

initLake = (logger, files, fileList) ->
    log = logger.create 'lake'
    log.debug 'init lake'

    # Find the 'marker' in official file list to memorize prepended and appended scripts from other frameworks
    pos = files.indexOf MARKER1
    files[pos] = createPatternObject join __dirname, 'karma-content.js'
    karmaPrepend = files.slice 0, pos + 1

    pos = files.indexOf MARKER2
    files.splice pos, 1
    karmaAppend = files.slice pos

    # Pass refresh function back to lake, allowing to re-run karma tests
    helper.refresh = (_files) ->
        pattern = karmaPrepend.concat(_files.map (f) -> createPatternObject resolve f).concat karmaAppend
        fileList.reload(pattern, [])

initLake.$inject = ['logger', 'config.files', 'fileList']

initLakeEarly = (files, preprocess) ->
    files.unshift MARKER1
    files.push MARKER2
    helper.preprocess = preprocess

initLakeEarly.$inject = ['config.files', 'preprocess']


module.exports =
    'framework:lake-jserror': ['factory', patchBrowsers]
    'framework:lake': ['factory', initLake]
    'framework:lake-init': ['factory', initLakeEarly]
    'reporter:lake': ['factory', require './karma-reporter']
