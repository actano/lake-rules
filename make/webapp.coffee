# Std lib
path = require 'path'

# Local Dep
{addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'

# Rule dep
component = require('./component')

exports.title = 'webapp'
exports.readme =
    name: 'webapp'
    path: path.join __dirname, 'webapp.md'
exports.description = 'install widgets for use by webapp'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.webapp?

    _local = (targets...) -> path.normalize path.join(featurePath, targets...)
    runtimePath = path.join lake.runtimePath, featurePath

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'
        addMkdirRule rb, dstPath

        widgetTargets = []
        for widget in manifest.webapp.widgets
            do (widget, dstPath) ->
                # widget will be given relative to featurePath, so we can use it
                # to resolve the featurePath of the widget:
                dependency = path.normalize(path.join(featurePath, widget))
                name = _local 'widgets', dependency
                buildPath = path.join lake.featureBuildDirectory, featurePath, widget
                componentBuildTargets = component.getTargets(buildPath, 'component-build')

                # We can't rely on make to get all dependencies because we would
                # have to know which files component-build has produced. So
                # instead use rsync and make this rule phony.
                rb.addRule name, [], ->
                    targets: name
                    dependencies: [componentBuildTargets.target, '|', dstPath]
                    actions: "rsync -rupEl #{componentBuildTargets.targetDst}/ #{dstPath}"
                addPhonyRule rb, name
                widgetTargets.push name

        # Collect all widgets into one rule
        rb.addRule _local('widgets'), [], ->
            targets: _local 'widgets'
            dependencies: widgetTargets
        addPhonyRule rb, _local 'widgets'

        # Extend install rule
        rb.addRule 'install (widgetTargets)', [], ->
            targets: _local 'install'
            dependencies: _local 'widgets'
        addPhonyRule rb, _local 'install'

    if manifest.webapp.restApis?
        restApis = for restApi in manifest.webapp.restApis
            path.join(path.normalize(path.join(featurePath, restApi)), 'install')

        rb.addRule 'install (restApis)', [], ->
            targets: _local 'install'
            dependencies: restApis

    if manifest.webapp.menu?
        dstPath = path.join runtimePath, 'menus'
        addMkdirRule rb, dstPath

        menuTargets = []
        for menu, widget of manifest.webapp.menu
            do (menu, widget, dstPath) ->
                # widget will be given relative to featurePath, so we can use it
                # to resolve the featurePath of the widget:
                dependency = path.normalize(path.join(featurePath, widget))
                name = _local 'menus', menu
                menuPath = path.join lake.featureBuildDirectory, featurePath, widget, 'menu', menu

                # TODO parse menu file to generate explicit rules to get rid of rsync
                rb.addRule name, [], ->
                    targets: name
                    dependencies: [dependency, '|', dstPath]
                    actions: "rsync -rupEl #{menuPath} #{dstPath}"
                addPhonyRule rb, name
                menuTargets.push name

        rb.addRule _local('menus'), [], ->
            targets: _local 'menus'
            dependencies: menuTargets

        # Extend install rule
        rb.addRule 'install (menus)', [], ->
            targets: _local 'install'
            dependencies: _local 'menus'
        addPhonyRule rb, _local 'install'

        # global install rule
        rb.addRule 'install (webapp global)', [], ->
            targets: 'install'
            dependencies: _local 'install'

