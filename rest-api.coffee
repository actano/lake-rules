# Std library
path = require 'path'

# Local dep
{replaceExtension, addCopyRule} = require './helper/filesystem'
{addCoffeeRule} = require './helper/coffeescript'
{createTestRule} = require './helper/test'

Rule = require './helper/rule'
{config} = require './lake/config'

exports.description = "build a rest-api feature"
exports.readme =
    name: 'rest-api'
    path: path.join __dirname, 'rest-api.md'
exports.addRules = (manifest) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    featurePath = manifest.featurePath
    buildPath = path.join '$(SERVER)', featurePath
    runtimePath = path.join config.runtimePath, featurePath

    _src = (script) -> path.join featurePath, script
    _dst = (script) -> path.join buildPath, replaceExtension(script, '.js')
    _run = (script) -> path.join runtimePath, replaceExtension(script, '.js')
    _runAsset = (asset) -> path.join runtimePath, asset
    _local = (target) -> path.join featurePath, target

    # Build targets
    buildRule = new Rule _local 'build'
        .prerequisiteOf featurePath
        .prerequisiteOf 'build'

    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _src script
            dst = _dst script
            buildRule.prerequisite addCoffeeRule src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            buildRule.prerequisite path.join(path.normalize(path.join(featurePath, dependency)), 'build')

    buildRule.phony().write()

    # Install / Dist targets
    installRule = new Rule _local 'install'
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _src script
            dst = _run script
            installRule.prerequisite addCoffeeRule src, dst

    if manifest.server.scripts?.assets?
        for file in manifest.server.scripts.assets
            src = _src file
            dst = _runAsset file
            installRule.prerequisite addCopyRule src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            installRule.prerequisite path.join(path.normalize(path.join(featurePath, dependency)), 'install')

    installRule.prerequisiteOf 'install'
        .phony().write()

    rule = new Rule _local 'unit_test'
        .prerequisiteOf _local 'test'
        .prerequisiteOf 'unit_test'
        .phony()

    if manifest.server?.test?.unit?
        for testFile in manifest.server.test.unit
            test = path.join featurePath, testFile
            testRule = createTestRule test, '$(MOCHA_RUNNER)'
                .write()

            new Rule path.join '$(BUILD)/mocha-unit-test.opts'
                .prerequisite test
                .write()
            rule.prerequisite testRule

    rule.write()

