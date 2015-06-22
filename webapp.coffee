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

    _local = (targets...) -> path.normalize path.join(manifest.featurePath, targets...)
    runtimePath = path.join config.runtimePath, manifest.featurePath

    installWidget = (widget, dstPath) ->
        # widget will be given relative to featurePath, so we can use it
        # to resolve the featurePath of the widget:
        srcFeature = path.normalize(path.join(manifest.featurePath, widget))
        name = _local 'widgets', srcFeature
        buildPath = path.join config.featureBuildDirectory, manifest.featurePath, widget
        componentBuildTargets = componentBuild.getTargets(buildPath, 'component-build')

        # We can't rely on make to get all dependencies because we would
        # have to know which files component-build has produced. So
        # instead use rsync and make this rule phony.
        new Rule name
            .prerequisite componentBuildTargets.target
            .orderOnly addMkdirRule dstPath
            .action "rsync -rupEl #{componentBuildTargets.targetDst}/ #{dstPath}"
            .phony()
            .write()

    installRestApi = (restApi) ->
        srcFeature = path.normalize path.join manifest.featurePath, restApi
        path.join srcFeature, 'install'

    installMenu = (menuName, feature) ->
        dstMenu = path.join runtimePath, 'menus', menuName
        menu.installMenu config, feature, dstMenu

    installRule = new Rule _local 'install'

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'

        widgetRule = new Rule _local 'widgets'

        for widget in manifest.webapp.widgets
            r = installWidget widget, dstPath
            widgetRule.prerequisite r

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
