# Std lib
path = require 'path'

# Local Dep
{addCopyRule, addMkdirRule} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'

# Rule dep
componentBuild = require './component-build'
menu = require './menu'

exports.title = 'webapp'
exports.readme =
    name: 'webapp'
    path: path.join __dirname, 'webapp.md'
exports.description = 'install widgets for use by webapp'
exports.addRules = (config, manifest, addRule) ->
    return if not manifest.webapp?

    _local = (targets...) -> path.normalize path.join(config.featurePath, targets...)
    runtimePath = path.join config.runtimePath, config.featurePath

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'
        addMkdirRule addRule, dstPath

        widgetTargets = []

        createWidgetRule = (widget, dstPath, getComponentTargets) ->
            # widget will be given relative to featurePath, so we can use it
            # to resolve the featurePath of the widget:
            dependency = path.normalize(path.join(config.featurePath, widget))
            name = _local 'widgets', dependency
            buildPath = path.join config.featureBuildDirectory, config.featurePath, widget

            componentBuildTargets = getComponentTargets(buildPath)

            # We can't rely on make to get all dependencies because we would
            # have to know which files component-build has produced. So
            # instead use rsync and make this rule phony.
            addRule
                targets: name
                dependencies: [componentBuildTargets.target, '|', dstPath]
                actions: "rsync -rupEl #{componentBuildTargets.targetDst}/ #{dstPath}"
            addPhonyRule addRule, name
            widgetTargets.push name

        # TODO: remove distinction between component v0 and v1 when every component is v1

        if manifest.webapp.widgets?
            for widget in manifest.webapp.widgets
                do (widget, dstPath) ->
                    createWidgetRule widget, dstPath, (buildPath) -> componentBuild.getTargets(buildPath, 'component-build')

        # Collect all widgets into one rule
        addRule
            targets: _local 'widgets'
            dependencies: widgetTargets
        addPhonyRule addRule, _local 'widgets'

        # Extend install rule
        addRule
            targets: _local 'install'
            dependencies: _local 'widgets'
        addPhonyRule addRule, _local 'install'

    if manifest.webapp.restApis?
        restApis = for restApi in manifest.webapp.restApis
            path.join(path.normalize(path.join(config.featurePath, restApi)), 'install')

        addRule
            targets: _local 'install'
            dependencies: restApis

    if manifest.webapp.menu?
        menuTargets = []
        for menuName, widget of manifest.webapp.menu
            menuFiles = menu.getTargets config, manifest, menuName
            for [menuPath, menuFile] in menuFiles
                src = path.join menuPath, menuFile
                dst = path.join runtimePath, 'menus', menuName, menuFile
                menuTargets.push addCopyRule addRule, src, dst

        addRule
            targets: _local 'menus'
            dependencies: menuTargets
        addPhonyRule addRule, _local 'menus'

        # Extend install rule
        addRule
            targets: _local 'install'
            dependencies: _local 'menus'

    # fallback install rule
    addRule
        targets: _local 'install'
    addPhonyRule addRule, _local 'install'

    # global install rule
    addRule
        targets: 'install'
        dependencies: _local 'install'
