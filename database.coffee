# Std library
path = require 'path'

# Local dep
{concatPaths} = require "./rulebook_helper"

exports.title = 'database views'
exports.description = "install couchviews"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build
    designBuildPath = path.join buildPath, "_design" # lib/foobar/build/_design

    if manifest.database?.designDocuments?.length > 0
        rb.addToGlobalTarget "couchview", rb.addRule "database", [], ->
            targets: concatPaths manifest.database.designDocuments, {pre: buildPath}
            dependencies: concatPaths manifest.database.designDocuments, {pre: featurePath}
            actions: [
                "mkdir -p #{path.join buildPath, "_design"}"
                concatPaths manifest.database.designDocuments, {pre: featurePath}, (file) ->
                    [
                        "$(NODE_BIN)/jshint #{file}"
                        "$(COUCHVIEW_INSTALL) -s #{file}"
                        "touch #{path.join designBuildPath, path.basename file}"
                    ]
            ]
