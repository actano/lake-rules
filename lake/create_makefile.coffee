# Std library
path = require 'path'
fs = require 'fs'

# Third party
Promise = require 'bluebird'
debug = require('debug')('create-makefile')
mkdirp = require '../helper/mkdirp'

module.exports.createMakefiles = Promise.coroutine ->
    # Local dep
    lakeConfig = require './config'
    Rule = require '../helper/rule'

    # Install Build-Server to RuleBuilder
    require '../helper/build-server'

    # load Plugins
    plugins = []
    for rule in lakeConfig.rules
        debug 'Loading plugin %s', rule
        plugin = require path.join lakeConfig.config.root, rule
        # make all APIs really return promises
        for m in ['init', 'addRules', 'done']
            old = plugin[m]
            plugin[m] = if old? then Promise.method old else Promise.resolve

        plugins.push plugin

    # load manifests
    manifests = []
    for feature in lakeConfig.features
        debug 'Loading feature %s', feature
        manifests.push lakeConfig.getManifest feature

    # init plugins
    Rule.writable = process.stdout
    yield Promise.all plugins.map (plugin) -> plugin.init()

    # Generate includes per feature
    for manifest in manifests
        endInclude = yield Rule.startInclude manifest.featurePath
        try
            # yield here, to avoid concurrent access from plugins on writable
            yield plugin.addRules manifest for plugin in plugins

        finally
            endInclude()

    # release plugins
    yield Promise.all plugins.map (plugin) -> plugin.done()
