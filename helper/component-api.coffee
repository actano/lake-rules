#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
program = require 'commander'
resolver = require 'component-resolver'
utils = require 'component-consoler'
build = require 'component-builder'
coffee = require 'builder-coffee-script'
autoprefix = require 'builder-autoprefixer'
es6modules = require 'builder-es6-module-to-cjs'

UglifyJS = require 'uglify-js'

program
     # install only
    .option '--install-only', 'install the remote dependencies, not build will be triggered'
    .option '--timeout <timeout>', 'github connection timeout in ms defaulting to 20000', '20000'

    # options for build
    .option '-o, --out <dir>', 'output directory defaulting to ./build', 'build'
    .option '-n, --name <file>', 'base name for build files  js,css) defaulting to build', 'build.{js,css}'
    .option '--exclude-require', 'exclude require from build'
    .option '--minify', 'minify the JS output'
    # .option '-a, --no-auto', 'do not require the entry point  first local of the root) automatically'
    # .option '-p, --prefix <str>', 'prefix css asset urls with <str>', ''
    # .option '-b, --browsers <string>', 'browsers to support with autoprefixer'

   
    # build with dynamic root component.json
    # .option '--dynamic', 'create a dynamic root component: --root, --path, --entry are required'
    # .option '--root <name>', 'dynamic component: name will be used as root name'
    # .option '--paths <dirs>', 'dynamic component: lookup paths for locals'
    # .option '--entry <local>', 'dynamic component: local copmonent as entry point for the root component'

    # options for install and build step
    .option '-d, --dev', 'install/build development dependencies, use sourceURLs, use minify'
    .option '--cwd <dir>', 'path where the component.json exists'
    .option '--components-out <dir>', 'remote components directory defaulting to ./components', 'components'

program.parse(process.argv)

if program.installOnly
    # install only
    options = 
        out: program.componentsOut
        timeout: program.timeout
        dev: program.dev
        install: true
        verbose: true

    resolver program.cwd, options, (err, tree) ->
        errorHandling err
else
    # build only
    out = path.resolve process.cwd(), program.cwd, program.out

    options = 
        destination: out # for copy/symlink the file assets (fonts, ...)
        dev: program.dev
        sourceURL: true
        sourceMap: false
        concurrency: 1 # avoid risk of random order of build output

    resolverOptions = 
        install: false
        dev: program.dev
        out: program.componentsOut

    resolver program.cwd, resolverOptions, (err, tree) ->
        errorHandling err

        mkdirp.sync out

        start = Date.now()
        build.scripts tree, options
            .use 'scripts', es6modules(options), build.plugins.js(options)
            .use 'scripts', coffee(options)
            .use 'json', build.plugins.json(options)
            .use 'templates', build.plugins.string(options) # html templates
            .end (err, string) ->
                errorHandling err
                return unless string

                if not program.excludeRequire
                    string = build.scripts.require + string # prepend commons.js impl
                
                if options.minify?
                    minified = UglifyJS.minify string, mangle: true, compress: true, fromString: true
                    string = minified.code

                fileName = program.name + '.js'
                outFile = path.join out, fileName
                
                fs.writeFileSync outFile, string
                
                utils.log 'build', "#{fileName} in #{Date.now() - start}ms - #{(string.length / 1024 | 0)}kb"

        build.styles(tree)
            .use 'styles', build.plugins.urlRewriter(options.prefix or ''), autoprefix(options)
            .end (err, string) ->
                errorHandling err
                return unless string

                fileName = program.name + '.css'
                outFile = path.join out, fileName

                fs.writeFileSync outFile, string

                utils.log 'build', "#{fileName} in #{Date.now() - start}ms - #{(string.length / 1024 | 0)}kb"

        filesPlugin = if options.copy then build.plugins.copy options else build.plugins.symlink options
        build.files tree, options
            .use 'images', filesPlugin
            .use 'fonts', filesPlugin
            .use 'files', filesPlugin
            .end (err) ->
                errorHandling err

errorHandling = (err) ->
    if err?
        console.log err
        process.exit 1