#!/usr/bin/env coffee

# Std library
fs = require 'fs'
path = require 'path'

# Third party
debug = require('debug') 'tools.rules.create-component.json'
nopt = require 'nopt'
_ = require 'underscore'

{replaceExtension} = require '../rulebook_helper'

generateComponent = (manifestPath, componentPath, additionalFiles = {}) ->
    debug "creating #{componentPath} from #{manifestPath}"

    manifest = require path.resolve manifestPath
    throw new Error("manifest without client section") if not manifest.client

    # basics
    component =
        name: manifest.name or throw new Error("missing name in manifest '#{manifestPath}'")
        description: manifest.description or ''
        version: manifest.version or '0.0.1'
        license: manifest.license or 'MIT'
        keywords: manifest.keywords or []
        dependencies: manifest.client.dependencies?.production?.remote or {}
        development: manifest.client.dependencies?.development?.remote or {}
        remotes: ["https://raw.githubusercontent.com"]

    # script stuff
    _addToComponent = (componentKey, manifestKey, extension) ->
        _mapValues = (src) ->
            if extension?
                [].concat(src).map (script) ->
                    replaceExtension(script, extension)
            else
                [].concat(src)

        values = []
        if manifest.client[manifestKey]?
            values = values.concat(_mapValues(manifest.client[manifestKey].files or manifest.client[manifestKey]))
        if additionalFiles[manifestKey]?
            values = values.concat(_mapValues(additionalFiles[manifestKey]))
        if values.length > 0
            component[componentKey] = (component[componentKey] or []).concat(values)


    _addToComponent('scripts', 'scripts', '.js')
    _addToComponent('scripts', 'templates', '.js')
    _addToComponent('styles', 'styles', '.css')
    _addToComponent('fonts', 'fonts')
    _addToComponent('images', 'images')

    if manifest.client.main?.length
        component.main = replaceExtension(manifest.client.main, '.js')

    # local dependencies
    if manifest.client.dependencies?.production?.local?.length
        localDeps = manifest.client.dependencies.production.local
        component.local = localDeps.map (localDep) ->
            path.basename localDep
        # a bit stupid, to we need a path entry ???
        component.paths = _.uniq localDeps.map (localDep) ->
            path.dirname localDep

    fs.writeFileSync componentPath, JSON.stringify component, null, 4

usage = """
USAGE: #{path.basename process.argv[1]} <path to manifest> <path to component.json> <options>
"""


parseCommandline = (argv) ->
    debug 'processing arguments ...'

    knownOpts =
        help : Boolean
        'add-script': [String, Array]
        'add-style': [String, Array]
        'add-font': [String, Array]

    shortHands =
        h: ['--help']

    parsedArgs = nopt knownOpts, shortHands, argv, 2
    return parsedArgs


main = ->
    debug 'started standalone'
    parsedArgs = parseCommandline process.argv
    debug JSON.stringify parsedArgs

    if parsedArgs.help or parsedArgs.argv.remain.length isnt 2
        console.log parsedArgs
        console.log usage
        process.exit 1

    [manifestPath, componentPath] = parsedArgs.argv.remain
    generateComponent manifestPath, componentPath, {
        scripts: parsedArgs['add-script']
        styles: parsedArgs['add-style']
        fonts: parsedArgs['add-font']
    }

if require.main is module
    main()




