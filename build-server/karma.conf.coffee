

module.exports = (config) ->
    path = require 'path'

    lib = path.resolve 'lib'

    base = require path.resolve 'karma.conf'
    base config

    config.set
        autoWatch: true
        singleRun: false
        basePath: path.resolve '.'

    config.frameworks.unshift 'lake-init'
    config.frameworks.push 'lake-jserror'
    config.frameworks.push 'lake'
    config.reporters.push 'lake'
    config.plugins = ['karma-*'] unless config.plugins?
    config.plugins.push require './karma-lake'
