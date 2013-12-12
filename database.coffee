{basename, dirname, join} = require 'path'

exports.title = 'couchbase views'
exports.description = "installs couchvbase views"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    if manifest.database?.designDocuments?.length > 0
        buildPath = join featurePath, lake.featureBuildDirectory # lib/foobar/build

        for viewfile in manifest.database.designDocuments
            source = join featurePath, viewfile
            target = join buildPath, viewfile
            rb.addToGlobalTarget 'couchview',
                rb.addRule "couchbase_view_#{viewfile}",
                ['couchbase_view', 'resources'],
                ->
                    targets: [target]
                    dependencies: [source]
                    actions: [
                        "mkdir -p #{dirname target}"
                        "$(NODE_BIN)/jshint #{source}"
                        "$(COUCHVIEW_INSTALL) -s #{source}"
                        "touch #{target}"
                    ]