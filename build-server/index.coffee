PLUGINS = ['coffee', 'component', 'couchview', 'jade', 'casper', 'karma']

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

        proceed = Promise.coroutine (args) ->
            exitCode = null
            try
                exitCode = yield processCommand(args)
            catch e
                console.error e.stack
                exitCode = 99
            c.end "#{exitCode || 0}\n"

        data = ''
        c.on 'data', (d) ->
            data += d.replace /\r/g, ''
        c.on 'end', ->
            proceed data.split '\n'

    _server.listen port, ->
        debug "Build Server listening on #{port}"
        if process.send?
            process.send 'running'

    checkExisting = ->
        return if fs.existsSync keepAlive

        debug "#{keepAlive} gone, exiting"
        _server.close ->
            debug "Build Server stopped"
            process.exit 0

        clearInterval interval

    interval = setInterval checkExisting, 500

module.exports = server

if require.main is module
    server process.argv[2], process.argv[3]
