fs = require 'fs'
path = require 'path'

Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
Promise.promisifyAll fs

MODULE_SWITCH = !!process.env['JADE_REQUIRE_MODULES']
MODULE_UPGRADE = !!process.env['JADE_UPGRADE_REQUIRE_MODULES']

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
                {basename,join,normalize,dirname} = require 'path'

                suffix = if basename(path).indexOf('.') < 0 then '.jade' else ''

                for p in @options.includePaths
                    test = "#{join p, path}#{suffix}"
                    if MODULE_SWITCH
                        _module = "#{basename p}/"

                        if MODULE_UPGRADE and fs.existsSync test
                            data = data.replace path, join _module, path
                            fs.writeFileSync src, data
                            return normalize test

                        continue unless _module is path.substring 0, _module.length
                        test = "#{join dirname(p), path}#{suffix}"

                    if fs.existsSync test
                        return normalize test

                super path, purpose

        options.includePaths = includePaths
        options.parser = MyParser

    return { data, options, jade}

wrapJadeResult = (js) ->
    "module.exports = function(jade){ return #{js} }"

newline = (s) ->
    s += '\n' unless s.substr(-1) is '\n'
    s

module.exports =
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

