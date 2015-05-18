# Std library
path = require 'path'
fs = require 'fs'

# Third party
debug = require('debug')('create-makefile')
mkdirp = require 'mkdirp'

# Local dep
Config = require './config'
Rule = require '../helper/rule'

# Install Build-Server to RuleBuilder
BuildServer = require '../helper/build-server'

_flatten = (result, array) ->
  for x in array
    if Array.isArray x
      _flatten result, x
    else
      result.push x
  return result

flatten = (array) ->
  _flatten [], array

module.exports.createMakefiles = (input, output) ->

    projectRoot = Config.projectRoot()
    lakeConfig = Config.config()
    output ?= path.join lakeConfig.config.lakeOutput

    CustomConfig = (featurePath) ->
      @featurePath = featurePath
      @projectRoot = projectRoot
    CustomConfig.prototype = lakeConfig.config

#    process.stderr.write "Generating Makefiles"
    for featurePath in input
        manifest = null
        try
            manifestPath = path.resolve projectRoot, featurePath, 'Manifest'
            manifest = require manifestPath
        catch err
            err.message = "Error in Manifest #{featurePath}: #{err.message}"
            debug err.message
            return err

        customConfig = new CustomConfig(featurePath)

        #console.log "Creating .mk file for #{featurePath}"
        mkFilePath = path.resolve output, featurePath + '.mk'

        mkdirp.sync path.dirname mkFilePath
        createLocalMakefileInc lakeConfig.rules, customConfig, manifest, mkFilePath

#        process.stderr.write "."
#    process.stderr.write "\n"
    return null

flatten = (array, result = []) ->
    for x in array
        if Array.isArray(x)
            flatten x, result
        else if x?
            result.push x
    result

logged = {}

createLocalMakefileInc = (pluginFiles, config, manifest, mkFilePath) ->
    writable = fs.createWriteStream mkFilePath
    addRule = (rule) ->
        rule = Rule.upgrade rule unless rule instanceof Rule
        rule.write writable

    for pluginFile in pluginFiles
        plugin = require path.join config.projectRoot, pluginFile
        plugin.addRules config, manifest, addRule

    writable.end()
    console.log "include #{path.relative config.projectRoot, mkFilePath}"
