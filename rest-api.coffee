# Std library
path = require 'path'

# Local dep
{replaceExtension} = require "./rulebook_helper"

exports.description = "build a rest-api feature"
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    dependencies = []
    runtimeDependencies = []
    targetDirectories = {}

    buildPath = path.join lake.featureBuildDirectory, featurePath
    runtimePath = path.join lake.runtimePath, featurePath

    if manifest.server.scripts?.files?
        serverFiles = []
        for script in manifest.server.scripts.files
            src = path.join featurePath, script
            dst = path.join buildPath, 'server_scripts', replaceExtension(script, '.js')
            run = path.join runtimePath, replaceExtension(script, '.js')
            do (src, dst, run) ->
                dstPath = path.dirname dst
                runPath = path.dirname run
                dependencies.push dst
                runtimeDependencies.push run
                serverFiles.push dst
                targetDirectories[dstPath] = true
                targetDirectories[runPath] = true

                rb.addRule dst, [], ->
                    targets: dst
                    dependencies: [src, '|', dstPath]
                    actions: "$(COFFEEC) $(COFFEE_FLAGS) --output #{dstPath} $^"
                rb.addRule run, [], ->
                    targets: run
                    dependencies: [dst, '|', runPath]
                    actions: 'cp -f $^ $@'

        rb.addRule 'run', [], ->
            targets: path.join featurePath, 'run'
            dependencies: serverFiles
            actions: "$(NODE) #{path.join lake.featureBuildDirectory, featurePath, 'server_scripts', 'server'}"

    # TODO rules/server.coffee also copies files given in manifest.resources, do
    # we actually need those for rest apis?

    rb.addRule 'build', [], ->
        targets: path.join featurePath, 'build'
        dependencies: dependencies

    rb.addRule 'build (global)', [], ->
        targets: 'build'
        dependencies: path.join featurePath, 'build'

    rb.addRule 'install', [], ->
        targets: path.join featurePath, 'install'
        dependencies: runtimeDependencies

    rb.addRule 'install (global)', [], ->
        targets: 'install'
        dependencies: path.join featurePath, 'install'

    for dir of targetDirectories
        do (dir) ->
            rb.addRule dir, [], ->
                targets: dir
                actions: 'mkdir -p $@'
