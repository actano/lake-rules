# Std lib
path = require 'path'

# Local Dep
{addCopyRule, addMkdirRule} = require './helper/filesystem'
Rule = require './helper/rule'

# Rule dep
componentBuild = require './component-build'
menu = require './menu'

exports.title = 'webapp'
exports.readme =
    name: 'webapp'
    path: path.join __dirname, 'webapp.md'
exports.description = 'install widgets for use by webapp'
exports.addRules = (config, manifest) ->
    return if not manifest.webapp?

    _local = (targets...) -> path.normalize path.join(config.featurePath, targets...)
    runtimePath = path.join config.runtimePath, config.featurePath

    installRule = new Rule _local 'install'
        .phony()

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'
        addMkdirRule dstPath

        widgetRule = new Rule _local 'widgets'
            .phony()

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
            new Rule name
                .prerequisite componentBuildTargets.target
                .orderOnly dstPath
                .action "rsync -rupEl #{componentBuildTargets.targetDst}/ #{dstPath}"
                .phony()
                .write()
            widgetRule.prerequisite name

        # TODO: remove distinction between component v0 and v1 when every component is v1

        if manifest.webapp.widgets?
            for widget in manifest.webapp.widgets
                do (widget, dstPath) ->
                    createWidgetRule widget, dstPath, (buildPath) -> componentBuild.getTargets(buildPath, 'component-build')

        widgetRule.write()

        installRule
            .prerequisite _local 'widgets'

    if manifest.webapp.restApis?
        restApis = for restApi in manifest.webapp.restApis
            path.join(path.normalize(path.join(config.featurePath, restApi)), 'install')

        installRule
            .prerequisite restApis

    if manifest.webapp.menu?
        menuTargets = []
        for menuName, widget of manifest.webapp.menu
            menuFiles = menu.getTargets config, manifest, menuName
            for [menuPath, menuFile] in menuFiles
                src = path.join menuPath, menuFile
                dst = path.join runtimePath, 'menus', menuName, menuFile
                menuTargets.push addCopyRule src, dst

        new Rule _local 'menus'
            .prerequisite menuTargets
            .phony()
            .write()
        installRule.prerequisite _local 'menus'

    # global install rule
    installRule
        .prerequisiteOf 'install'
        .write()
