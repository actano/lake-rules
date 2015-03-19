path = require 'path'

_root = process.cwd()

loadConfig = ->
  try
    require 'coffee-script/register'

  p = path.join _root, 'lake.config'
  try
    configurator = require p
  catch e

  return configurator unless configurator instanceof Function

  c =
    config:
      lakePath: _root
      lakeOutput: path.join _root, 'build', 'lake'
  configurator c
  return c

_config = loadConfig()

module.exports =
  projectRoot: ->
    return _root

  config: ->
    throw "lake.config not found in #{_root}" unless _config?
    return _config
