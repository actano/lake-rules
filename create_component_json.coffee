#!/usr/bin/env coffee

# Std library
fs = require 'fs'
path = require 'path'

# Third party
debug = require('debug') 'tools.rules.create-component.json'
nopt = require 'nopt'
_ = require 'underscore'

{replaceExtension} = require './helper/filesystem'

_deepKeyLookup = (obj, keys) ->
    _keys = keys.split('.')
    _lookup = (_obj) ->
        if not _obj? or not _keys? or _keys.length is 0
            return _obj
        else
            return _lookup(_obj[_keys.shift()])
    return _lookup(obj)


generateComponent = (manifestPath, componentPath, additionalFiles = {}) ->
    debug "creating #{componentPath} from #{manifestPath}"

    manifest = require path.resolve manifestPath
    throw new Error("manifest without client section") if not manifest.client

    # basics
    component =
        # the name is obsolete in component 1.x.x for local components
        # https://github.com/component/spec/blob/master/component.json/specifications.md#name
        name: manifest.name or throw new Error("missing name in manifest '#{manifestPath}'")
        description: manifest.description if manifest.description
        version: manifest.version if manifest.version
        license: manifest.license if manifest.license
        keywords: manifest.keywords if manifest.keywords
        dependencies: manifest.client.dependencies?.production?.remote or {}
        development: manifest.client.dependencies?.development?.remote or {}
        remotes: ["https://raw.githubusercontent.com"]

    # script stuff
    _addToComponent = (srcObj, componentKey, manifestKey, extension) ->
        _mapValues = (src) ->
            if _(src).isArray() or _(src).isString()
                if extension?
                    [].concat(src).map (script) ->
                        replaceExtension(script, extension)
                else
                    [].concat(src)
            else
                []

        values = _mapValues(_deepKeyLookup(srcObj, manifestKey))
        if values.length > 0
            component[componentKey] = (component[componentKey] or []).concat(values)


    _addToComponent(manifest.client, 'scripts', 'scripts', '.js')
    _addToComponent(manifest.client, 'scripts', 'templates.files', '.js')
    _addToComponent(manifest.client, 'scripts', 'templates', '.js')
    _addToComponent(manifest.client, 'scripts', 'mixins.export', '.js')
    _addToComponent(manifest.client, 'styles', 'styles.files', '.css')
    _addToComponent(manifest.client, 'styles', 'styles', '.css')
    _addToComponent(manifest.client, 'fonts', 'fonts')
    _addToComponent(manifest.client, 'images', 'images')

    _addToComponent(additionalFiles, 'scripts', 'scripts', '.js')
    _addToComponent(additionalFiles, 'styles', 'styles', '.css')
    _addToComponent(additionalFiles, 'fonts', 'fonts')

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



