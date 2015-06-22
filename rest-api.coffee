# Std library
path = require 'path'

# Local dep
{replaceExtension, addCopyRule} = require './helper/filesystem'
{addCoffeeRule} = require './helper/coffeescript'
{addTestRule, addCopyRulesForTests} = require './helper/test'

RUNNER = "$(MOCHA_RUNNER)"

Rule = require './helper/rule'

exports.description = "build a rest-api feature"
exports.readme =
    name: 'rest-api'
    path: path.join __dirname, 'rest-api.md'
exports.addRules = (config, manifest) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    buildDependencies = []
    runtimeDependencies = []

    featurePath = manifest.featurePath
    buildPath = path.join '$(SERVER)', featurePath
    runtimePath = path.join config.runtimePath, featurePath

    _src = (script) -> path.join featurePath, script
    _dst = (script) -> path.join buildPath, replaceExtension(script, '.js')
    _dstAsset = (asset) -> path.join buildPath, asset
    _run = (script) -> path.join runtimePath, replaceExtension(script, '.js')
    _runAsset = (asset) -> path.join runtimePath, asset
    _local = (target) -> path.join featurePath, target

    # Build targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _src script
            dst = _dst script
            do (src, dst) ->
                buildDependencies.push dst
                addCoffeeRule src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            buildDependencies.push(path.join(path.normalize(path.join(featurePath, dependency)), 'build'))

    new Rule _local 'build'
        .prerequisiteOf featurePath
        .prerequisiteOf 'build'
        .prerequisite buildDependencies
        .phony()
        .write()

    # Install / Dist targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _dst script
            dst = _run script
            do (src, dst) ->
                runtimeDependencies.push dst
                addCopyRule src, dst

    if manifest.server.scripts?.assets?
        for file in manifest.server.scripts.assets
            src = _src file
            dst = _runAsset file
            do (src, dst) ->
                runtimeDependencies.push dst
                addCopyRule src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            runtimeDependencies.push(path.join(path.normalize(path.join(featurePath, dependency)), 'install'))

    new Rule _local 'install'
        .prerequisiteOf 'install'
        .prerequisite runtimeDependencies
        .phony()
        .write()

    # Test targets
    {tests, assets} = addCopyRulesForTests manifest, _src, _dst, _dstAsset

    preUnitTest = new Rule _local 'pre_unit_test'
        .phony()
        .prerequisite tests
        .prerequisite assets

    if manifest.server?.dependencies?.production?.local?
        test_dependencies = for dependency in manifest.server.dependencies.production.local
            path.join(path.normalize(path.join(featurePath, dependency)), 'pre_unit_test')
        preUnitTest.prerequisite test_dependencies

    preUnitTest.write()

    rule = new Rule _local 'unit_test'
        .prerequisiteOf _local 'test'
        .prerequisiteOf 'unit_test'
        .phony()

    if manifest.server?.test?.unit?
        _getParams = (file) ->
            params = ''
            if manifest.server.testParams?
                for testParam in manifest.server.testParams
                    if file.indexOf(testParam.file) > -1
                        params += " #{testParam.param}"
            return params

        rule.prerequisite _local 'build'
            .prerequisite _local 'pre_unit_test'

        for testFile in manifest.server.test.unit
            test = path.join featurePath, testFile
            addTestRule rule, "#{RUNNER} #{_getParams test} #{test}", replaceExtension(test, '.xml')

    rule.write()

