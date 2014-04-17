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
    return if not manifest.webapp?

    _component = (featurePath) -> path.join lake.featureBuildDirectory, featurePath, 'component-build'
    _local = (targets...) -> path.normalize path.join(featurePath, targets...)

    runtimePath = path.join lake.runtimePath, featurePath

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'
        addMkdirRule rb, dstPath

        widgetTargets = []
        for widget in manifest.webapp.widgets
            do (widget) ->
                # widget will be given relative to featurePath, so we can use it
                # to resolve the featurePath of the widget:
                dependency = path.normalize(path.join(featurePath, widget))
                name = _local 'widgets', dependency
                componentPath = path.join lake.featureBuildDirectory, featurePath, widget, 'component-build'

                # We can't rely on make to get all dependencies because we would
                # have to know which files component-build has produced. So
                # instead use rsync and make this rule phony.
                rb.addRule name, [], ->
                    targets: name
                    dependencies: [dependency, '|', dstPath]
                    actions: "rsync -rupEl #{componentPath}/ #{dstPath}"
                addPhonyRule rb, name
                widgetTargets.push name

        # Collect all widgets into one rule
        rb.addRule _local('widgets'), [], ->
            targets: _local 'widgets'
            dependencies: widgetTargets
        addPhonyRule rb, _local 'widgets'

        # Extend install rule
        # TODO fix name of install rules and then change here back to _local 'install'
        rb.addRule 'install (widgetTargets)', [], ->
            targets: path.join 'build', 'runtime', featurePath, 'install' # wtf
            dependencies: _local 'widgets'
        addPhonyRule rb, _local 'install'
