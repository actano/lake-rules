path = require 'path'

_root = process.cwd()
_config = null

loadConfig = ->
    try
        require 'coffee-script/register'

    p = path.join _root, 'lake.config'
    try
        configurator = require p
    catch e
        console.error 'WARN: cannot require %s: %s', p, e

    return configurator unless configurator instanceof Function

    c = require '../lake.config.coffee'
    configurator c
    return c

module.exports =
    config: ->
        unless _config?
            _config = false
            _config = loadConfig()
        throw "lake.config not found in #{_root}" if _config is false
        return _config
