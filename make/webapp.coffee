###

    Generates make rules to build the webapp

    Defines the following main make targets:

    feature/pages:
        copies all component-build outputs from dependend pages into RUNTIME_DIR/FEATURE_DIR/pages

        The dependencies have to be declared in the manifest

        input contract:
            feature generates component-build output in BUILD_DIR/FEATURE_DIR/component-build

        output contract:
            copies all component-build output in a shallow structure under RUNTIME_DIR/FEATURE_DIR/pages

    feature/install and install will be extended with feature/pages

###

# Std lib
path = require 'path'

# Local Dep
{
    addPhonyRule
    addMkdirRule
} = require '../rulebook_helper'

exports.description = 'install widgets for use by webapp'
exports.addRules = (lake, featurePath, manifest, rb) ->

    # For now we only want to run this for _the_ webapp feature.
    # This can probably be dropped once we know what needs to be done
    # in total.
    return if not manifest.server?.scripts?.files?
    return if not 'webapp.coffee' in manifest.server.scripts.files

    _component = (featurePath) -> path.join lake.featureBuildDirectory, featurePath, 'component-build'
    _local = (targets...) -> path.normalize path.join(featurePath, targets...)

    runtimePath = path.join lake.runtimePath, featurePath

    if manifest.server?.pages?
        dstPath = path.join runtimePath, 'pages'
        addMkdirRule rb, dstPath

        pageTargets = []
        for page in manifest.server.pages
            do (page) ->
                # page will be given relative to featurePath, so we can use it
                # to resolve the featurePath of the page:
                dependency = path.normalize(path.join(featurePath, page))
                name = _local 'pages', dependency
                componentPath = path.join lake.featureBuildDirectory, featurePath, page, 'component-build'

                # We can't rely on make to get all dependencies because we would
                # have to know which files component-build has produced. So
                # instead use rsync and make this rule phony.
                rb.addRule name, [], ->
                    targets: name
                    dependencies: [dependency, '|', dstPath]
                    actions: "rsync -rupEl #{componentPath}/ #{dstPath}"
                addPhonyRule rb, name
                pageTargets.push name

        # Collect all pages into one rule
        rb.addRule _local('pages'), [], ->
            targets: _local 'pages'
            dependencies: pageTargets
        addPhonyRule rb, _local 'pages'

        # Extend install rule
        # TODO fix name of install rules and then change here back to _local 'install'
        rb.addRule 'install (pages)', [], ->
            targets: path.join 'build', 'runtime', featurePath, 'install' # wtf
            dependencies: _local 'pages'
        addPhonyRule rb, _local 'install'
