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

    'jade.html': Promise.coroutine (target, src, locals, includePaths...) ->
        options = {}
        if locals.length
            options = JSON.parse locals

        {data, options, jade} = yield prepareJade src, includePaths, options

        jade = require 'jade'
        data = yield fs.readFileAsync src, {encoding: 'utf-8'}

        options.client = true
        options.name = 'template'
        options.filename = src
        options.includePaths = includePaths

        js = jade.render data, options
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, js
        return 0

    'jade.js': Promise.coroutine (target, src, includePaths...) ->
        {data, options, jade} = yield prepareJade src, includePaths

        options.compileDebug = true
        js = jade.compileClient data, options
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, "module.exports = function(jade){ return #{js} }"
        return 0

    'component.json': Promise.coroutine (target, src, translationScripts...) ->
        createComponent = require './create_component_json'
        yield mkdirp path.dirname target
        createComponent src, target, {
            scripts: translationScripts
        }
        return 0

processCommand = Promise.method (args) ->
    cmd = commands[args[0]]
    return 1 unless cmd?
    cmd.apply this, args.slice 1

prepareJade = Promise.coroutine (src, includePaths, options = {}) ->
    jade = require 'jade'
    data = yield fs.readFileAsync src, {encoding: 'utf-8'}
    options.client = true
    options.name = 'template'
    options.filename = src
    if includePaths?.length
        class MyParser extends jade.Parser
            constructor: () ->
                jade.Parser.apply(@, arguments)

            resolvePath: (path, purpose) ->
                {basename,join,normalize} = require 'path'

                if options.denyParent && (normalize(path).indexOf('..') >= 0)
                    throw "Denied resolving #{path} from #{options.filename}"

                if (basename(path).indexOf('.') == -1)
                    path += '.jade'

                for p in @options.includePaths
                    test = join p, path
                    if fs.existsSync test
                        return normalize test

                super path, purpose

        options.includePaths = includePaths
        options.parser = MyParser

    return { data, options, jade}
