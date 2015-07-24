module.exports = (config) ->
    path = require 'path'
    base = require path.resolve 'karma.conf'
    base config

    config.set
        autoWatch: false
        singleRun: true

    config.frameworks.push 'lake-jserror'
    config.reporters.push 'lake'
    config.plugins = ['karma-*'] unless config.plugins?
    config.plugins.push require './karma-lake'
