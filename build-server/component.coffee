fs = require 'fs'
path = require 'path'

Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
Promise.promisifyAll fs

module.exports =
    'component.json': Promise.coroutine (target, src, translationScripts...) ->
        createComponent = require '../create_component_json'
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
