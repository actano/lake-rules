path = require 'path'
Rule = require './helper/rule'

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

addDependency = (featurePath, d) ->
    transitiveDependencyTarget = path.normalize path.join featurePath, d, TARGET_NAME
    target = path.join featurePath, NODE_MODULES, path.basename(d), PACKAGE_JSON
    new Rule target
        .prerequisite path.normalize path.join featurePath, d, MANIFEST
        .prerequisite path.join featurePath, MANIFEST
        .orderOnly transitiveDependencyTarget
        .action '@mkdir -p $(@D)'
        .action "$(COFFEE) #{__filename} $@ $<"
        .write()

    # Add Phony Stub for transitive dependencies
    new Rule transitiveDependencyTarget
        .phony()
        .write()
    return target

addInitialRules = (featurePath) ->
    target = path.join featurePath, TARGET_NAME
    globalClean = path.join TARGET_NAME, CLEAN
    localClean = path.join featurePath, TARGET_NAME, CLEAN


    new Rule localClean, 'local-deps/clean'
        .phony()
        .action "rm -rf \"#{path.join featurePath, NODE_MODULES}\""
        .write()

    new Rule globalClean
        .phony()
        .prerequisite localClean
        .write()

    new Rule MOSTLYCLEAN
        .prerequisite globalClean
        .write()

    return target

cache = {}

module.exports =
    title: 'Create node_modules folders for local dependencies'
    readme:
        name: TARGET_NAME
        path: path.join __dirname, "#{TARGET_NAME}.md"

    addDependencyRules: (featurePath, dependencies) ->
        dependencies = [] unless dependencies?
        dependencies = [dependencies] unless Array.isArray dependencies

        _targets = []

        done = cache[featurePath]
        unless done?
            done = cache[featurePath] = {
                _targetName: addInitialRules featurePath
            }

        for d in dependencies
            unless done[d]
                done[d] = true
                _targets.push addDependency featurePath, d

        target = done._targetName

        new Rule target
            .prerequisite _targets
            .write()
        return target

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
