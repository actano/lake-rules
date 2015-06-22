path = require 'path'

defaultConfig = require '../lake.config.coffee'

loadConfig = ->
    try
        require 'coffee-script/register'

    p = path.join defaultConfig.config.root, 'lake.config'
    try
        configurator = require p
    catch e
        console.error 'WARN: cannot require %s: %s', p, e

    configurator defaultConfig
    return defaultConfig

module.exports = loadConfig()
