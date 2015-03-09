#!/usr/bin/env coffee

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
program = require 'commander'
resolver = require 'component-resolver'
utils = require('component-consoler');
Build = require 'component-build'
UglifyJS = require 'uglify-js'

program
     # install only
    .option('--install-only', 'install the remote dependencies, not build will be triggered')
    .option('--timeout <timeout>', 'github connection timeout in ms defaulting to 20000', '20000')

    # options for build
    .option('-o, --out <dir>', 'output directory defaulting to ./build', 'build')
    .option('-n, --name <file>', 'base name for build files (js,css) defaulting to build', 'build.{js,css}')
    .option('--exclude-require', 'exclude require from build')
    .option('--minify', 'minify the JS output')
    # .option('-a, --no-auto', 'do not require the entry point (first local of the root) automatically')
    # .option('-p, --prefix <str>', 'prefix css asset urls with <str>', '')
    # .option('-b, --browsers <string>', 'browsers to support with autoprefixer')

   
    # build with dynamic root component.json
    # .option('--dynamic', 'create a dynamic root component: --root, --path, --entry are required')
    # .option('--root <name>', 'dynamic component: name will be used as root name')
    # .option('--paths <dirs>', 'dynamic component: lookup paths for locals')
    # .option('--entry <local>', 'dynamic component: local copmonent as entry point for the root component')

    # options for install and build step
    .option('-d, --dev', 'install/build development dependencies, use sourceURLs, use minify')
    .option('--cwd <dir>', 'path where the component.json exists')
    .option('--components-out <dir>', 'remote components directory defaulting to ./components', 'components')

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
        return errorHandling err
else
    # build only
    out = path.resolve process.cwd(), program.cwd, program.out

    options = 
        destination: out # for copy/symlink the file assets (fonts, ...)
        dev: program.dev
        name: program.name
        require: !program.excludeRequire

    resolverOptions = 
        install: false
        dev: program.dev
        out: program.componentsOut

    resolver program.cwd, resolverOptions, (err, tree) ->
        errorHandling err

        mkdirp.sync out
        
        build = Build tree, options
        start = Date.now()

        build.scripts (err, string) ->
            errorHandling err
            
            return unless string
            
            if options.minify?
                minified = UglifyJS.minify string, {mangle: true, compress: true, fromString: true}
                string = minified.code

            fileName = options.name + '.js'
            outFile = path.join out, fileName
            
            fs.writeFileSync outFile, string
            
            return utils.log 'build', "#{fileName} in #{Date.now() - start}ms - #{(string.length / 1024 | 0)}kb"

        build.styles (err, string) ->
            errorHandling err
            return unless string

            fileName = options.name + '.css'
            outFile = path.join out, fileName

            fs.writeFileSync outFile, string

            return utils.log 'build', "#{fileName} in #{Date.now() - start}ms - #{(string.length / 1024 | 0)}kb"

        build.files (err) ->
            return errorHandling err

        return

errorHandling = (err) ->
    if err?
        console.log err
        process.exit 1