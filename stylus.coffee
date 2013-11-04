# Std library
path = require 'path'

# Local dep
{replaceExtension, concatPaths} = require "./rulebook_helper"

exports.title = 'stylus'
exports.description = "convert stylus to css"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory 
    # lib/foobar/build/styles
    styluesBuildPath = path.join buildPath, "styles" 

    if manifest.client?.styles?
        rb.addRule "stylus", ["client"], ->
            targets: concatPaths manifest.client.styles, {pre: buildPath}, (file) ->
                replaceExtension file, '.css'
            dependencies: concatPaths manifest.client.styles, {pre: featurePath}
            actions: [
                "mkdir -p #{styluesBuildPath}"
                "$(STYLUSC) $(STYLUS_FLAGS) -o #{styluesBuildPath} $^"
            ]
