# Std lib
path = require 'path'

# Local Dep
{addCopyRule, addMkdirRule} = require './helper/filesystem'
Rule = require './helper/rule'
{config} = require './lake/config'

# Rule dep
componentBuild = require './component-build'

exports.title = 'webapp'
exports.readme =
    name: 'webapp'
    path: path.join __dirname, 'webapp.md'
exports.description = 'install widgets for use by webapp'
exports.addRules = (manifest) ->
    return if not manifest.webapp?

    _local = (targets...) -> path.normalize path.join(manifest.featurePath, targets...)

    installRestApi = (restApi) ->
        srcFeature = path.normalize path.join manifest.featurePath, restApi
        path.join srcFeature, 'install'

    installRule = new Rule _local 'install'
        .prerequisiteOf 'install'

    if manifest.webapp.restApis?
        restRule = new Rule _local 'restApis'

        for restApi in manifest.webapp.restApis
            restRule.prerequisite installRestApi restApi

        restRule.phony().write()
        installRule.prerequisite restRule

    # global install rule
    installRule.phony().write()


