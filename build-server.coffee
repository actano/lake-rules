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

commands =
    coffee: Promise.coroutine (target, src) ->
        CoffeeScript = require 'coffee-script'
        data = yield fs.readFileAsync src, {encoding: 'utf-8'}
        js = CoffeeScript.compile data
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, js
        return 0

    couchview: Promise.coroutine (target, src) ->
        couchbase = require "#{target}/lib/couchbase"
        bucket = couchbase.getBucket()
        yield bucket.uploadDesignDocAsync src
        return 0

    jade_html: Promise.coroutine (target, src, locals, includePaths...) ->
        jade = require 'jade'

        options = {}
        if locals.length
            options = JSON.parse locals

        data = yield fs.readFileAsync src, {encoding: 'utf-8'}

        options.client = true
        options.name = 'template'
        options.filename = src
        options.includePaths = includePaths

        js = jade.render data, options
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, js
        return 0

    jade_js: Promise.coroutine (target, src, includePaths...) ->
        jade = require 'jade'

        data = yield fs.readFileAsync src, {encoding: 'utf-8'}

        options = {}
        options.client = true
        options.name = 'template'
        options.compileDebug = true
        options.filename = src
        options.includePaths = includePaths

        js = jade.compileClient data, options
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, "module.exports = function(jade){ return #{js} }"
        return 0

processCommand = Promise.method (args) ->
    console.log args[0]
    cmd = commands[args[0]]
    return 1 unless cmd?
    cmd.apply this, args.slice 1
