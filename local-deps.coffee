path = require 'path'

_toArray = (arrays...) ->
    result = []
    for a in arrays
        if a?
            if a.length
                result = result.concat a
            else unless a.length is 0
                result.push a
    return result

_createNodeModules = (featurePath, deps) ->

module.exports =
    title: 'Create node_modules folders for local dependencies'
    readme:
        name: 'local-deps'
        path: path.join __dirname, 'local-deps.md'

    addRules: (config, manifest, ruleBook) ->
        {addPhonyRule} = require './helper/phony'
        deps = _toArray manifest.client?.dependencies?.production?.local
        _targets = []

        for d in deps
            unless d == ''
                target = path.join config.featurePath, 'node_modules', path.basename(d), 'package.json'
                _targets.push target
                ruleBook.addRule
                    targets: target
                    dependencies: [
                        path.normalize path.join config.featurePath, d, 'Manifest.coffee'
                        path.join config.featurePath, 'Manifest.coffee'
                    ]
                    actions: [
                        "@mkdir -p $(@D)"
                        "$(NODE_BIN)/coffee #{__filename} $(@D) $< > $@"
                    ]

        target = path.join config.featurePath, 'local_deps'
        ruleBook.addRule
            targets: target
            dependencies: _targets

        ruleBook.addRule
            targets: 'local_deps'
            dependencies: target

        addPhonyRule ruleBook, target
        addPhonyRule ruleBook, 'local_deps'

if require.main == module
    folder = process.argv[2]
    depManifest = process.argv[3]
    depFeaturePath = path.dirname(depManifest)
    dep = require path.relative __dirname, depManifest
    main = dep.client?.main

    unless main
        throw "No main script found in #{depManifest}, required from #{path.dirname path.dirname folder}"

    pkg =
        name: path.dirname folder
        main: path.relative folder, path.join depFeaturePath, main
    console.log JSON.stringify pkg
