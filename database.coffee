{basename, dirname, join, extname} = require 'path'
{replaceExtension} = require "./rulebook_helper"

exports.title = 'couchbase views'
exports.description = "installs couchbase views"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    if manifest.database?.designDocuments?.length > 0
        buildPath = join lake.featureBuildDirectory, featurePath # lib/foobar/build

        for viewfile in manifest.database.designDocuments
            source = join featurePath, viewfile
            target = join buildPath, viewfile
            actions = null

            if extname(source) is '.coffee'
                target = replaceExtension target, '.js'
                actions = [
                    "mkdir -p #{dirname target}"
                    "$(COFFEEC) -bc -o #{dirname target} #{source}"
                    "$(NODE_BIN)/jshint #{target}"
                    "$(COUCHVIEW_INSTALL) -s #{target}"
                ]
            else
                actions = [
                    "mkdir -p #{dirname target}"
                    "$(NODE_BIN)/jshint #{source}"
                    "$(COUCHVIEW_INSTALL) -s #{source}"
                    # "touch #{target}"
                ]

            rb.addToGlobalTarget 'couchview',
                rb.addRule "couchbase_view_#{viewfile}",
                ['couchbase_view', 'resources'],
                ->
                    targets: [target]
                    dependencies: [source]
                    actions: actions
