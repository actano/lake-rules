Promise = require 'bluebird'
net = require 'net'
fs = require 'fs'
path = require 'path'
mkdirp = Promise.promisify require 'mkdirp'
debug = require('debug')('build-server')
Promise.promisifyAll fs

server = ->
    keepAlive = process.argv[2]
    port = process.argv[3] || 8124

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

    checkExisting = ->
        fs.existsAsync keepAlive, (exists) ->
            return if exists

            debug "#{keepAlive} gone, exiting"
            _server.close ->
                debug "Build Server stopped"

            clearInterval interval

    interval = setInterval checkExisting, 500

server()

processCommand = Promise.method (args) ->
    switch args[0]
        when 'coffee' then coffee args[1], args[2]
        when 'couchview' then couchview args[1], args[2]
        else 1

CoffeeScript = require 'coffee-script'

coffee = Promise.coroutine (target, src) ->
    data = yield fs.readFileAsync src, {encoding: 'utf-8'}
    js = CoffeeScript.compile data
    yield mkdirp path.dirname target
    yield fs.writeFileAsync target, js
    return 0

couchview = Promise.coroutine (target, src) ->
    couchbase = require "#{target}/lib/couchbase"
    bucket = couchbase.getBucket()
    yield bucket.uploadDesignDocAsync src
    return 0
