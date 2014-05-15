# Std library
path = require 'path'

# Local dep
{replaceExtension, addCopyRule, addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony.coffee'
coffee = require '../helper/coffeescript'

exports.title = 'database'
exports.description = 'build couchbase views'
exports.readme =
    name: 'database'
    path: path.join __dirname, 'database.md'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.database?

    _local = (targets...) -> path.join featurePath, targets...

    buildPath = path.join lake.featureBuildDirectory, featurePath

    # Build targets
    # Compile coffee to js, or just copy them to BUILD_DIR
    if manifest.database.designDocuments?
        for viewFile in manifest.database.designDocuments
            do (viewFile) ->
                src = path.join featurePath, viewFile
                dst = path.join buildPath, replaceExtension(viewFile, '.js')

                switch path.extname viewFile
                    when '.coffee'
                        dstPath = addMkdirRule rb, path.dirname dst
                        rb.addRule dst, [], ->
                            targets: dst
                            dependencies: [src, '|', dstPath]
                            actions: [
                                coffee.coffeeAction
                                '$(NODE_BIN)/jshint $@'
                            ]
                    when '.js'
                        dstPath = addMkdirRule rb, path.dirname dst
                        rb.addRule dst, [], ->
                            targets: dst
                            dependencies: [src, '|', dstPath]
                            actions: [
                                'cp -f $^ $@'
                                '$(NODE_BIN)/jshint $@'
                            ]

                    else
                        throw new Error("Unknown database view format #{path.extname viewFile}")

    # Couchview targets
    # Installs views into couchbase
    if manifest.database.designDocuments?
        installRules = []
        for viewFile in manifest.database.designDocuments
            do (viewFile) ->
                name = _local viewFile, 'couchview'
                js = path.join buildPath, replaceExtension(viewFile, '.js')
                rb.addRule name, [], ->
                    targets: name
                    dependencies: js
                    actions: '$(NODE_BIN)/coffee $(TOOLS)/install_couch_view.coffee -s $<'
                addPhonyRule rb, name
                installRules.push name

        rb.addRule _local('couchview'), [], ->
            targets: _local 'couchview'
            dependencies: installRules
        addPhonyRule rb, _local 'couchview'

        rb.addRule 'couchview (global)', [], ->
            targets: 'couchview'
            dependencies: _local 'couchview'
