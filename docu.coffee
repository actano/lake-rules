# Std library
path = require 'path'

# Local dep
{concatPaths} = require "./rulebook_helper"

exports.title = 'documentation'
exports.description = "build documentation with markdown"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build
    documentationPath = path.join buildPath, "documentation" # lib/fooabr/build/documentation

    # project root relative paths
    localComponentPath = path.join lake.localComponentsPath, featurePath # build/runtime/lib/foobar 

    if manifest.documentation?
        rb.addToGlobalTarget "documentation", rb.addRule "documentation", [], ->
            targets: documentationPath
            dependencies: concatPaths manifest.documentation, {pre: featurePath}
            actions: [
                "@mkdir -p #{documentationPath}"
                concatPaths manifest.documentation, {}, (file) ->
                    "markdown #{path.join featurePath, file} > #{path.join documentationPath, file}"
                "touch #{documentationPath}"
            ]
