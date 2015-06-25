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
        menu.installMenu featureManifest, config.clientPath

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
        dstPath = config.clientPath

        clientRule = new Rule path.join dstPath, 'widgets'
            .prerequisiteOf config.clientPath
            .ifndef 'WEBPACK'

        for widget in manifest.webapp.widgets
            widgetManifest = manifest.getManifest widget
            r = componentBuild.buildComponent widgetManifest, dstPath
            clientRule.prerequisite r

        clientRule.phony().write()

    if manifest.webapp.menu?
        menuRule = new Rule _local 'menus'
        for menuName, widget of manifest.webapp.menu
            menuRule.prerequisite installMenu menuName, manifest.getManifest widget

        menuRule.phony().write()
        installRule.prerequisite menuRule

    # global install rule
    installRule.phony().write()
