###

    generates make rules for database views

    defines the following main targets:

    feature/couchview:
        installs all couchbase views into the database

        output contract:
            nothing. this is a phony target.

    the feature/couchview target is also appended to couchview.

    The feature/couchview depends on the views to be present as
    javascript in BUILD_DIR/FEATURE_DIR/VIEW_FILE.js and takes
    care of creating the appropriate rules.

###

# Std library
path = require 'path'

# Local dep
{
    replaceExtension,
    addCopyRule,
    addPhonyRule,
    addMkdirRule
} = require '../rulebook_helper'

exports.description = 'build couchbase views'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.database?

    _local = (targets...) -> path.join featurePath, targets...

    buildPath = path.join lake.featureBuildDirectory, featurePath

    # Build targets
    # Compile coffee to js, or just copy them to BUILD_DIR
    if manifest.database.designDocuments?
        for viewFile in manifest.database.designDocuments
            src = path.join featurePath, viewFile
            dst = path.join buildPath, replaceExtension(viewFile, '.js')

            switch path.extname viewFile
                when '.coffee'
                    dstPath = addMkdirRule rb, path.dirname dst
                    rb.addRule dst, [], ->
                        targets: dst
                        dependencies: [src, '|', dstPath]
                        actions: "$(COFFEEC) $(COFFEE_FLAGS) --output #{dstPath} $^"
                when '.js'
                    addCopyRule rb, src, dst
                else
                    throw new Error("Unknown database view format #{path.extname viewFile}")

    # Couchview targets
    # Installs views into couchbase
    if manifest.database.designDocuments?
        installRules = []
        for viewFile in manifest.database.designDocuments
            name = _local viewFile, 'couchview'
            js = path.join buildPath, replaceExtension(viewFile, '.js')
            rb.addRule name, [], ->
                targets: name
                dependencies: js
                actions: [
                    "$(NODE_BIN)/jshint #{js}"
                    "$(COUCHVIEW_INSTALL) -s #{js}"
                ]
            addPhonyRule rb, name
            installRules.push name

        rb.addRule _local('couchview'), [], ->
            targets: _local 'couchview'
            dependencies: installRules
        addPhonyRule rb, _local 'couchview'

        rb.addRule 'couchview (global)', [], ->
            targets: 'couchview'
            dependencies: _local 'couchview'
