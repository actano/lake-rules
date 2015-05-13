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
                process.exit 0

            clearInterval interval

    interval = setInterval checkExisting, 500

server()

commands =
    coffee: Promise.coroutine (target, src) ->
        CoffeeScript = require 'coffee-script'
        data = yield fs.readFileAsync src, {encoding: 'utf-8'}
        js = CoffeeScript.compile data
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, newline js
        return 0

    couchview: Promise.coroutine (target, src) ->
        couchbase = require "#{target}/lib/couchbase"
        bucket = couchbase.getBucket()
        yield bucket.uploadDesignDocAsync src
        return 0

    'jade.html': Promise.coroutine (target, src, locals, includePaths...) ->
        if locals?.length
            locals = JSON.parse locals
        else
            locals = null

        {data, options, jade} = yield prepareJade src, includePaths

        # TODO this should go via jade.render(), but cannot, as we allow embedded require statements, so it should write js to a build-dir target file to use build-time relative renders
        require.extensions['.jade'] = (client, filename) ->
            data = fs.readFileSync filename
            options.filename = filename
            js = jade.compileClient data, options
            client._compile(wrapJadeResult(js), filename)

        relativeName = path.relative __dirname, options.filename
        fn = require relativeName
        template = fn jade.runtime
        html = template locals

        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, newline html
        return 0

    'jade.js': Promise.coroutine (target, src, includePaths...) ->
        {data, options, jade} = yield prepareJade src, includePaths

        options.compileDebug = true
        js = jade.compileClient data, options
        yield mkdirp path.dirname target
        yield fs.writeFileAsync target, newline wrapJadeResult js
        return 0

    'component.json': Promise.coroutine (target, src, translationScripts...) ->
        createComponent = require './create_component_json'
        yield mkdirp path.dirname target
        createComponent src, target, {
            scripts: translationScripts
        }
        return 0

    'component-install': Promise.coroutine (target, remoteComponents) ->
        resolver = Promise.promisify require 'component-resolver'
        cwd = path.dirname target
        options =
            out: remoteComponents
            timeout: 20000
            dev: true
            install: true
            verbose: true

        yield mkdirp remoteComponents
        yield resolver cwd, options
        return 0

    'component-build': Promise.coroutine (target, src, remoteComponents, name, excludeRequire) ->
        resolver = Promise.promisify require 'component-resolver'
        build = require 'component-builder'
        coffee = require 'builder-coffee-script'
        autoprefix = require 'builder-autoprefixer'
        es6modules = require 'builder-es6-module-to-cjs'
        cwd = path.dirname src
        out = path.resolve process.cwd(), cwd, 'component-build'

        yield mkdirp out

        options =
            destination: out # for copy/symlink the file assets (fonts, ...)
            dev: true
            sourceURL: true
            sourceMap: false
            concurrency: 1 # avoid risk of random order of build output

        resolverOptions =
            install: false
            dev: true
            out: remoteComponents

        tree = yield resolver cwd, resolverOptions

        scripts = build.scripts tree, options
            .use 'scripts', es6modules(options), build.plugins.js(options)
            .use 'scripts', coffee(options)
            .use 'json', build.plugins.json(options)
            .use 'templates', build.plugins.string(options) # html templates
        result = yield Promise.promisify(scripts.end, scripts)()
        if result
            unless excludeRequire?
                result = build.scripts.require + result # prepend commons.js impl
            if options.minify?
                UglifyJS = require 'uglify-js'
                minified = UglifyJS.minify result, mangle: true, compress: true, fromString: true
                result = minified.code
            fileName = name + '.js'
            outFile = path.join out, fileName
            yield fs.writeFileAsync outFile, result

        styles = build.styles(tree)
            .use 'styles', build.plugins.urlRewriter(options.prefix or ''), autoprefix(options)
        result = yield Promise.promisify(styles.end, styles)()
        if result
            fileName = name + '.css'
            outFile = path.join out, fileName
            fs.writeFileSync outFile, result

        filesPlugin = if options.copy then build.plugins.copy options else build.plugins.symlink options
        files = build.files tree, options
            .use 'images', filesPlugin
            .use 'fonts', filesPlugin
            .use 'files', filesPlugin
        yield Promise.promisify(files.end, files)()
        return 0

processCommand = Promise.method (args) ->
    cmd = commands[args[0]]
    return 1 unless cmd?
    cmd.apply this, args.slice 1

wrapJadeResult = (js) ->
    "module.exports = function(jade){ return #{js} }"

newline = (s) ->
    s += '\n' unless s.substr(-1) is '\n'
    s

prepareJade = Promise.coroutine (src, includePaths) ->
    jade = require 'jade'
    data = yield fs.readFileAsync src, {encoding: 'utf-8'}
    options =
        client: true
        name: 'template'
        filename: src

    if includePaths?.length
        class MyParser extends jade.Parser
            constructor: () ->
                jade.Parser.apply(@, arguments)

            resolvePath: (path, purpose) ->
                {basename,join,normalize} = require 'path'

                if options.denyParent && (normalize(path).indexOf('..') >= 0)
                    throw new Error "Denied resolving #{path} from #{options.filename}"

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
