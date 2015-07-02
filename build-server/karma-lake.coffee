Promise = require 'bluebird'
{createPatternObject} = require 'karma/lib/config'
{join, resolve} = require 'path'

karmaPrepend = []
karmaAppend = []

exitKarma = ->

process.on 'lake_exit', ->
    exitKarma()

# Capture Karmas SIGINT listener to be able to call it manually to stop server
EmitterWrapper = require 'karma/lib/emitter_wrapper'

_on = (event, listener) ->
    if event is 'SIGINT'
        exitKarma = listener
        EmitterWrapper::on = _on
    _on.apply this, arguments

[_on, EmitterWrapper::on] = [EmitterWrapper::on, _on]

browsers = null
MARKER1 = createPatternObject resolve __dirname, 'MARKER1'
MARKER2 = createPatternObject resolve __dirname, 'MARKER2'

patchBrowsers = (logger, emitter, capturedBrowsers, launcher) ->
    log = logger.create 'lake-jserror'
    log.debug 'init lake-jserror'
    # monkey-patch browserCollections add, to get hold on new browser objects and add a 'onJserror' method, before init() is called on them.
    # That's the way we grap unhandled js errors
    # TODO find a better way
    _add = (browser) ->
        browser.jserrors ?= []
        browser.onJserror = (err) ->
            log.debug 'received jserror %s for %s', err, this
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
                log.info "We're missing %s, trying to restart", browser.name
                return if launcher.restart id
                log.error "Cannot restart %s, trying to exit karma", browser.name
                exitKarma()

initLake = (logger, files, fileList) ->
    log = logger.create 'lake'
    log.debug 'init lake'

    # Find the 'marker' in official file list to memorize prepended and appended scripts from other frameworks
    pos = files.indexOf MARKER1
    karmaPrepend = files.slice 0, pos
    files.splice pos, 1

    pos = files.indexOf MARKER2
    files.splice pos, 1
    karmaAppend = files.slice pos

    # Pass refresh function back to lake, allowing to re-run karma tests
    helper = require './karma-helper'
    helper.refresh = (_files) ->
        pattern = karmaPrepend.concat(_files.map (f) -> createPatternObject resolve f).concat karmaAppend
        fileList.reload(pattern, [])

initLake.$inject = ['logger', 'config.files', 'fileList']

initLakeEarly = (files, preprocess) ->
    files.unshift MARKER1
    files.push MARKER2
    helper = require './karma-helper'
    helper.preprocess = preprocess

initLakeEarly.$inject = ['config.files', 'preprocess']


module.exports =
    'framework:lake-jserror': ['factory', patchBrowsers]
    'framework:lake': ['factory', initLake]
    'framework:lake-init': ['factory', initLakeEarly]
    'reporter:lake': ['factory', require './karma-reporter']
