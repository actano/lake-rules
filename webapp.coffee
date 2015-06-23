# Std lib
path = require 'path'

# Local Dep
{addCopyRule, addMkdirRule} = require './helper/filesystem'
Rule = require './helper/rule'
{config} = require './lake/config'

# Rule dep
componentBuild = require './component-build'
menu = require './menu'

exports.title = 'webapp'
exports.readme =
    name: 'webapp'
    path: path.join __dirname, 'webapp.md'
exports.description = 'install widgets for use by webapp'
exports.addRules = (manifest) ->
    return if not manifest.webapp?

    _local = (targets...) -> path.normalize path.join(manifest.featurePath, targets...)
    runtimePath = path.join config.runtimePath, manifest.featurePath

    installRestApi = (restApi) ->
        srcFeature = path.normalize path.join manifest.featurePath, restApi
        path.join srcFeature, 'install'

    installMenu = (menuName, featureManifest) ->
        dstMenu = path.join runtimePath, 'menus', menuName
        menu.installMenu featureManifest, dstMenu

    installRule = new Rule _local 'install'
        .prerequisiteOf 'install'

    if manifest.webapp.restApis?
        restRule = new Rule _local 'restApis'

        for restApi in manifest.webapp.restApis
            restRule.prerequisite installRestApi restApi

        restRule.phony().write()
        installRule.prerequisite restRule

    if config.webpack
        installRule.phony().write()
        installRule = new Rule _local 'install'
            .ifndef 'WEBPACK'

    if manifest.webapp.widgets?
        dstPath = path.join runtimePath, 'widgets'

        widgetRule = new Rule _local 'widgets'

        for widget in manifest.webapp.widgets
            widgetManifest = manifest.getManifest widget
            r = componentBuild.buildComponent widgetManifest, dstPath
            widgetRule.prerequisite r

        widgetRule.phony().write()

        installRule.prerequisite widgetRule

    if manifest.webapp.menu?
        menuRule = new Rule _local 'menus'
        for menuName, widget of manifest.webapp.menu
            menuRule.prerequisite installMenu menuName, manifest.getManifest widget

        menuRule.phony().write()
        installRule.prerequisite menuRule

    # global install rule
    installRule.phony().write()
