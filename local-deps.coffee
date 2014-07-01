path = require 'path'

getTargetName = () ->
    base = path.basename(__filename)
    ext = path.extname base
    base.substring 0, base.length - ext.length

TARGET_NAME = getTargetName()
CLEAN = 'clean'
NODE_MODULES = 'node_modules'
MANIFEST = 'Manifest.coffee'
PACKAGE_JSON = 'package.json'
MOSTLYCLEAN = 'mostlyclean'

_toArray = (arrays...) ->
    result = []
    for a in arrays
        if a?
            if a.length
                result = result.concat a
            else unless a.length is 0
                result.push a
    return result

addDependency = (d, featurePath) ->
    remoteManifest = path.normalize path.join featurePath, d, MANIFEST
    myManifest = path.join featurePath, MANIFEST
    remoteDeps = path.normalize path.join featurePath, d, TARGET_NAME
    return result =
        targets: path.join featurePath, NODE_MODULES, path.basename(d), PACKAGE_JSON
        dependencies: [
            remoteManifest
            myManifest
            '|'
            remoteDeps
        ]
        actions: [
            "@mkdir -p $(@D)"
            "$(NODE_BIN)/coffee #{__filename} $@ $<"
        ]

addInitialRules = (ruleBook, featurePath) ->
    target = path.join featurePath, TARGET_NAME
    globalClean = path.join TARGET_NAME, CLEAN
    localClean = path.join target, CLEAN

    ruleBook.addRule
        targets: localClean
        actions: [
            "rm -rf \"#{path.join featurePath, NODE_MODULES}\""
        ]

    ruleBook.addRule
        targets: TARGET_NAME
        dependencies: target

    ruleBook.addRule
        targets: globalClean
        dependencies: localClean

    ruleBook.addRule
        targets: globalClean
        dependencies: path.join target, CLEAN

    ruleBook.addRule
        targets: MOSTLYCLEAN
        dependencies: globalClean

    {addPhonyRule} = require './helper/phony'
    addPhonyRule ruleBook, target
    addPhonyRule ruleBook, TARGET_NAME
    addPhonyRule ruleBook, localClean
    addPhonyRule ruleBook, globalClean
    return target

cache = {}

module.exports =
    title: 'Create node_modules folders for local dependencies'
    readme:
        name: TARGET_NAME
        path: path.join __dirname, "#{TARGET_NAME}.md"

    addRules: (config, manifest, ruleBook) ->
        featurePath = config.featurePath
        deps = _toArray manifest.client?.tests?.browser?.dependencies, manifest.client?.htdocs?.dependencies
        _targets = []

        done = cache[featurePath]
        unless done?
            done = cache[featurePath] = {
                _targetName: addInitialRules ruleBook, featurePath
            }

        for d in deps
            unless done[d]
                done[d] = true
                rule = addDependency d, featurePath
                ruleBook.addRule rule
                _targets.push rule.targets

        target = done._targetName

        ruleBook.addRule
            targets: target
            dependencies: _targets

        jadeTarget = require('./browser-tests.coffee').jadeTarget(config, manifest)
        if jadeTarget?
            ruleBook.addRule
                targets: jadeTarget
                dependencies: [
                    '|'
                    target
                ]

if require.main == module
    file = process.argv[2]
    folder = path.dirname file
    depManifest = process.argv[3]
    depFeaturePath = path.dirname(depManifest)
    dep = require path.relative __dirname, depManifest

    pkg =
        name: path.basename folder

    main = dep.client?.main

    unless main
        console.error "WARN: No main script found in #{depManifest}, required from #{path.dirname path.dirname folder}"
    else
        unless 'string' == typeof main
            throw "main script is not of type 'string' in #{depManifest}"

        pkg.main = path.relative folder, path.join depFeaturePath, main

    result = JSON.stringify pkg
    require('fs').writeFileSync file, result
