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

patchBrowsers = (logger, emitter, capturedBrowsers) ->
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

        _add.apply this, arguments

module.exports =
    'framework:lake-jserror': ['factory', patchBrowsers]
