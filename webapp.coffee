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

    installWidget = (widget, dstPath) ->
        addMkdirRule dstPath
        # widget will be given relative to featurePath, so we can use it
        # to resolve the featurePath of the widget:
        srcFeature = path.normalize(path.join(config.featurePath, widget))
        name = _local 'widgets', srcFeature
        buildPath = path.join config.featureBuildDirectory, config.featurePath, widget
        componentBuildTargets = componentBuild.getTargets(buildPath, 'component-build')

        # We can't rely on make to get all dependencies because we would
        # have to know which files component-build has produced. So
        # instead use rsync and make this rule phony.
        new Rule name
            .prerequisite componentBuildTargets.target
            .orderOnly dstPath
            .action "rsync -rupEl #{componentBuildTargets.targetDst}/ #{dstPath}"
            .phony()
            .write()

    installRestApi = (restApi) ->
        srcFeature = path.normalize path.join config.featurePath, restApi
        path.join srcFeature, 'install'

    installMenu = (menuName, widget) ->
        menuFiles = menu.getTargets config, manifest, menuName
        pre = []
        for [menuPath, menuFile] in menuFiles
            src = path.join menuPath, menuFile
            dst = path.join runtimePath, 'menus', menuName, menuFile
            pre.push addCopyRule src, dst
        pre

    installRule = new Rule _local 'install'

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'

        widgetRule = new Rule _local 'widgets'

        for widget in manifest.webapp.widgets
            widgetRule.prerequisite installWidget widget, dstPath

        widgetRule.phony().write()

        installRule.prerequisite widgetRule

    if manifest.webapp.restApis?
        restRule = new Rule _local 'restApis'

        for restApi in manifest.webapp.restApis
            restRule.prerequisite installRestApi restApi

        restRule.phony().write()
        installRule.prerequisite restRule

    if manifest.webapp.menu?
        menuRule = new Rule _local 'menus'
        for menuName, widget of manifest.webapp.menu
            menuRule.prerequisite installMenu menuName, widget

        menuRule.phony().write()
        installRule.prerequisite menuRule

    # global install rule
    installRule
        .prerequisiteOf 'install'
        .phony()
        .write()
