# Std lib
path = require 'path'

# Local Dep
{addCopyRule, addMkdirRule, addMkdirRuleOfFile} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'

# Rule dep
componentBuild = require './component-build'
menu = require './menu'

exports.title = 'webapp'
exports.readme =
    name: 'webapp'
    path: path.join __dirname, 'webapp.md'
exports.description = 'install widgets for use by webapp'
exports.addRules = (config, manifest, rb) ->
    return if not manifest.webapp?

    _local = (targets...) -> path.normalize path.join(config.featurePath, targets...)
    runtimePath = path.join config.runtimePath, config.featurePath

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'
        addMkdirRule rb, dstPath

        widgetTargets = []
        for widget in manifest.webapp.widgets
            do (widget, dstPath) ->
                # widget will be given relative to featurePath, so we can use it
                # to resolve the featurePath of the widget:
                dependency = path.normalize(path.join(config.featurePath, widget))
                name = _local 'widgets', dependency
                buildPath = path.join config.featureBuildDirectory, config.featurePath, widget
                componentBuildTargets = componentBuild.getTargets(buildPath, 'component-build')

                # We can't rely on make to get all dependencies because we would
                # have to know which files component-build has produced. So
                # instead use rsync and make this rule phony.
                rb.addRule
                    targets: name
                    dependencies: [componentBuildTargets.target, '|', dstPath]
                    actions: "rsync -rupEl #{componentBuildTargets.targetDst}/ #{dstPath}"
                addPhonyRule rb, name
                widgetTargets.push name

        # Collect all widgets into one rule
        rb.addRule
            targets: _local 'widgets'
            dependencies: widgetTargets
        addPhonyRule rb, _local 'widgets'

        # Extend install rule
        rb.addRule
            targets: _local 'install'
            dependencies: _local 'widgets'
        addPhonyRule rb, _local 'install'

    if manifest.webapp.restApis?
        restApis = for restApi in manifest.webapp.restApis
            path.join(path.normalize(path.join(config.featurePath, restApi)), 'install')

        rb.addRule
            targets: _local 'install'
            dependencies: restApis

    if manifest.webapp.menu?
        menuTargets = []
        for menuName, widget of manifest.webapp.menu
            menuFiles = menu.getTargets config, manifest, menuName
            for [menuPath, menuFile] in menuFiles
                src = path.join menuPath, menuFile
                dst = path.join runtimePath, 'menus', menuName, menuFile
                menuTargets.push addCopyRule rb, src, dst

        rb.addRule
            targets: _local 'menus'
            dependencies: menuTargets
        addPhonyRule rb, _local 'menus'

        # Extend install rule
        rb.addRule
            targets: _local 'install'
            dependencies: _local 'menus'

    # fallback install rule
    rb.addRule
        targets: _local 'install'
    addPhonyRule rb, _local 'install'

    # global install rule
    rb.addRule
        targets: 'install'
        dependencies: _local 'install'