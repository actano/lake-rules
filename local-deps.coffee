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

module.exports =
    title: 'Create node_modules folders for local dependencies'
    readme:
        name: 'local-deps'
        path: path.join __dirname, 'local-deps.md'

    addRules: (config, manifest, ruleBook) ->
        {addPhonyRule} = require './helper/phony'
        deps = _toArray manifest.client?.dependencies?.production?.local, manifest.tests?.browser?.dependencies
        _targets = []

        done = {'': true}
        for d in deps
            unless done[d]
                done[d] = true

                target = path.join config.featurePath, 'node_modules', path.basename(d), 'package.json'
                _targets.push target
                ruleBook.addRule
                    targets: target
                    dependencies: [
                        path.normalize path.join config.featurePath, d, 'Manifest.coffee'
                        path.join config.featurePath, 'Manifest.coffee'
                        '|'
                        path.normalize path.join config.featurePath, d, 'local_deps'
                    ]
                    actions: [
                        "@mkdir -p $(@D)"
                        "$(NODE_BIN)/coffee #{__filename} $@ $<"
                    ]

        target = path.join config.featurePath, 'local_deps'
        globalClean = path.join 'local_deps', 'clean'
        localClean = path.join target, 'clean'

        ruleBook.addRule
            targets: target
            dependencies: _targets

        ruleBook.addRule
            targets: localClean
            actions: [
                "rm -rf \"#{path.join config.featurePath, 'node_modules'}\""
            ]

        ruleBook.addRule
            targets: 'local_deps'
            dependencies: target

        ruleBook.addRule
            targets: globalClean
            dependencies: localClean

        ruleBook.addRule
            targets: globalClean
            dependencies: path.join target, 'clean'

        ruleBook.addRule
            targets: 'mostlyclean'
            dependencies: globalClean

        addPhonyRule ruleBook, target
        addPhonyRule ruleBook, 'local_deps'
        addPhonyRule ruleBook, localClean
        addPhonyRule ruleBook, globalClean

if require.main == module
    file = process.argv[2]
    folder = path.dirname file
    depManifest = process.argv[3]
    depFeaturePath = path.dirname(depManifest)
    dep = require path.relative __dirname, depManifest
    main = dep.client?.main

    unless main
        throw "No main script found in #{depManifest}, required from #{path.dirname path.dirname folder}"

    unless 'string' == typeof main
        throw "main script is not of type 'string' in #{depManifest}"

    pkg =
        name: path.basename folder
        main: path.relative folder, path.join depFeaturePath, main
    result = JSON.stringify pkg
    require('fs').writeFileSync file, result
