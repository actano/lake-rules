# Std library
path = require 'path'

# Third party
glob = require 'glob'

# Local dep
{
    replaceExtension
    addCopyRule
    mkdirRule
} = require "../rulebook_helper"

exports.description = "build a rest-api feature"
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    buildDependencies = []
    runtimeDependencies = []

    buildPath = path.join lake.featureBuildDirectory, featurePath
    runtimePath = path.join lake.runtimePath, featurePath

    if manifest.server.scripts?.files?
        serverFiles = []
        for script in manifest.server.scripts.files
            js = replaceExtension(script, '.js')
            src = path.join featurePath, script
            dst = path.join buildPath, 'server_scripts', js
            run = path.join runtimePath, js
            do (src, dst, run) ->
                dstPath = path.dirname dst

                buildDependencies.push dst
                runtimeDependencies.push run
                serverFiles.push dst

                dstPath = mkdirRule rb, dst
                rb.addRule dst, [], ->
                    targets: dst
                    dependencies: [src, '|', dstPath]
                    actions: "$(COFFEEC) $(COFFEE_FLAGS) --output #{dstPath} $^"
                addCopyRule rb, dst, run

        rb.addRule 'run', [], ->
            targets: path.join featurePath, 'run'
            dependencies: serverFiles
            actions: "$(NODE) #{path.join lake.featureBuildDirectory, featurePath, 'server_scripts', 'server'}"

    # Until the switch to alien is complete, we need to copy i18n resources.
    # TODO Remove this once we don't need i18n!
    if manifest.resources?.dirs?
        for dir in manifest.resources.dirs
            resourcesPath = path.join featurePath, dir
            resourcesBuildPath = path.join buildPath, dir
            resourceFiles = glob.sync "*", cwd: path.resolve resourcesPath
            for resourceFile in resourceFiles
                src = path.join resourcesPath, resourceFile
                dst = path.join buildPath, dir, resourceFile
                run = path.join runtimePath, dir, resourceFile
                buildDependencies.push dst
                runtimeDependencies.push run
                do (src, dst, run) ->
                    addCopyRule rb, src, dst
                    addCopyRule rb, src, run

    rb.addRule 'build', [], ->
        targets: path.join featurePath, 'build'
        dependencies: buildDependencies

    rb.addRule 'build (global)', [], ->
        targets: 'build'
        dependencies: path.join featurePath, 'build'

    rb.addRule 'install', [], ->
        targets: path.join featurePath, 'install'
        dependencies: runtimeDependencies

    rb.addRule 'install (global)', [], ->
        targets: 'install'
        dependencies: path.join featurePath, 'install'
