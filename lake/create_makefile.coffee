# Std library
path = require 'path'
fs = require 'fs'

# Third party
debug = require('debug')('create-makefile')

# Local dep
Config = require './config'

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

    process.stdout.write "Generating Makefiles"
    for featurePath in input
        manifest = null
        try
            manifestPath = path.join projectRoot, featurePath, 'Manifest'
            manifest = require manifestPath
        catch err
            err.message = "Error in Manifest #{featurePath}: #{err.message}"
            debug err.message
            return err

        customConfig = new CustomConfig(featurePath)

        #console.log "Creating .mk file for #{featurePath}"
        mkFilePath = getFilename customConfig.projectRoot, customConfig.featurePath, output

        createLocalMakefileInc lakeConfig.rules, customConfig, manifest, mkFilePath

        process.stdout.write "."
    console.log ""
    return null

getFilename = (projectRoot, featurePath, output) ->
    featureName = path.basename featurePath
    mkFilePath = path.join path.resolve(projectRoot, output), featureName + '.mk'
    return mkFilePath

flatten = (array, result = []) ->
    for x in array
        if Array.isArray(x)
            flatten x, result
        else
            result.push x
    result

createLocalMakefileInc = (pluginFiles, config, manifest, mkFilePath) ->
    writable = fs.createWriteStream mkFilePath
    addRule = (rule) ->
        rule.dependencies or= []
        # wrap everything into an array and then flatten
        # so user can use string or (nested) array
        for prop in ['targets', 'dependencies', 'actions']
            if rule[prop]?
                rule[prop] = flatten [ rule[prop] ]

        # print the rule only if a target exists
        # otherwise user created the rule for RuleBook API features
        if rule.targets?
            writable.write "#{rule.targets.join ' '}: #{rule.dependencies.join ' '}\n"
            if rule.actions?
                actions = ['$(info )', "$(info \u001b[3;4m#{rule.targets}\u001b[24m)"]
                actions = actions.concat rule.actions
                writable.write "\t#{actions.join '\n\t'}\n\n"
            else
                writable.write '\n'

    # TODO remove after upgrading all uses
    addRule.addRule = addRule
    for pluginFile in pluginFiles
        plugin = require path.join config.projectRoot, pluginFile
        plugin.addRules config, manifest, addRule

    writable.end()
