PLUGINS = [
    'coffee'
    'component'
    'couchview'
    'jade'
    'karma'
    'stylus'
]

Promise = require 'bluebird'
net = require 'net'
path = require 'path'
fs = require 'fs'
debug = require('debug')('build-server')
Promise.promisifyAll fs

commands = {}

installCommands = (_commands) ->
    commands[k] = v for k, v of _commands

processCommand = Promise.method (args) ->
    cmd = commands[args[0]]
    return 1 unless cmd?
    cmd.apply this, args.slice 1

server = (keepAlive, port = 8124) ->
    unless fs.existsSync keepAlive
        console.error 'Touch File %s does not exist', keepAlive
        process.exit 1

    for mod in PLUGINS
        installCommands require path.join __dirname, mod

    _server = net.createServer {allowHalfOpen: true}, (c) ->
        c.setEncoding 'utf-8'

        data = ''
        c.on 'data', (d) ->
            data += d.replace /\r/g, ''
        c.on 'end', ->
            processCommand data.split '\n'
                .catch (e) ->
                    console.error e.stack
                    return 99
                .then (exitCode) ->
                    c.end "#{exitCode || 0}\n"

    _server.listen port, ->
        debug "Build Server listening on #{port}"
        if process.send?
            process.send 'running'

    process.on 'lake_exit', ->
        _server.close()

    checkExisting = ->
        return if fs.existsSync keepAlive

        debug "#{keepAlive} gone, exiting"
        timer = setTimeout (-> process.exit 1), 20000
        if timer.unref?
            timer.unref()
        else
            clearTimeout timer
        clearInterval interval
        process.emit 'lake_exit'

    interval = setInterval checkExisting, 500

module.exports = server

if require.main is module
    server process.argv[2], process.argv[3]
