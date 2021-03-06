# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRule} = require './helper/filesystem'
Rule = require './helper/rule'
{config} = require './lake/config'

exports.title = 'database'
exports.description = 'build couchbase views'
exports.readme =
    name: 'database'
    path: path.join __dirname, 'database.md'
exports.addRules = (manifest) ->
    return if not manifest.database?

    _local = (targets...) -> path.join manifest.featurePath, targets...

    buildPath = path.join config.featureBuildDirectory, manifest.featurePath

    # Build targets
    # Compile coffee to js, or just copy them to BUILD_DIR
    if manifest.database.designDocuments?
        for viewFile in manifest.database.designDocuments
            do (viewFile) ->
                src = path.join manifest.featurePath, viewFile
                dst = path.join buildPath, replaceExtension(viewFile, '.js')

                switch path.extname viewFile
                    when '.coffee'
                        new Rule dst
                            .prerequisite src
                            .info '$@ (view)'
                            .buildServer 'coffee'
                            .action '$(NODE_BIN)/jshint $@'
                            .write()
                    when '.js'
                        dstPath = addMkdirRule path.dirname dst
                        new Rule dst
                            .prerequisite src
                            .orderOnly dstPath
                            .action 'cp -f $^ $@'
                            .action '$(NODE_BIN)/jshint $@'
                            .write()

                    else
                        throw new Error("Unknown database view format #{path.extname viewFile}")

    # Couchview targets
    # Installs views into couchbase
    if manifest.database.designDocuments?
        rule = new Rule _local 'couchview'
            .prerequisiteOf 'couchview'
            .phony()

        for viewFile in manifest.database.designDocuments
            do (viewFile) ->
                name = _local viewFile, 'couchview'
                js = path.join buildPath, replaceExtension(viewFile, '.js')
                new Rule name
                    .prerequisite js
                    .buildServer 'couchview', '$(ROOT)'
                    .phony()
                    .write()
                rule.prerequisite name

        rule.write()
