# Std library
path = require 'path'

# Local dep
{replaceExtension, addCopyRule, addMkdirRule} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'
{addCoffeeRule} = require './helper/coffeescript'
test = require './helper/test'

exports.description = "build a rest-api feature"
exports.readme =
    name: 'rest-api'
    path: path.join __dirname, 'rest-api.md'
exports.addRules = (config, manifest, addRule) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    buildDependencies = []
    runtimeDependencies = []

    featurePath = config.featurePath
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
                addCoffeeRule addRule, src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            buildDependencies.push(path.join(path.normalize(path.join(featurePath, dependency)), 'build'))

    addRule
        targets: _local 'build'
        dependencies: buildDependencies
    addPhonyRule addRule, _local 'build'

    # Alias to map feature to feature/build
    addRule
        targets: featurePath
        dependencies: _local 'build'

    addRule
        targets: 'build'
        dependencies: _local 'build'

    # Install / Dist targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _dst script
            dst = _run script
            do (src, dst) ->
                runtimeDependencies.push dst
                addCopyRule addRule, src, dst

    if manifest.server.scripts?.assets?
        for file in manifest.server.scripts.assets
            src = _src file
            dst = _runAsset file
            do (src, dst) ->
                runtimeDependencies.push dst
                addCopyRule addRule, src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            runtimeDependencies.push(path.join(path.normalize(path.join(featurePath, dependency)), 'install'))

    addRule
        targets: _local 'install'
        dependencies: runtimeDependencies
    addPhonyRule addRule, _local 'install'

    # Test targets
    {tests, assets} = test.addCopyRulesForTests addRule, manifest, _src, _dst, _dstAsset

    addRule
        targets: _local 'pre_unit_test'
        dependencies: tests

    addRule
        targets: _local 'pre_unit_test'
        dependencies: assets

    addPhonyRule addRule, _local 'pre_unit_test'

    if manifest.server?.dependencies?.production?.local?
        test_dependencies = for dependency in manifest.server.dependencies.production.local
            path.join(path.normalize(path.join(featurePath, dependency)), 'pre_unit_test')
        addRule
            targets: _local 'pre_unit_test'
            dependencies: test_dependencies

    if manifest.server?.test?.unit?
        _getParams = (file) ->
            params = ''
            if manifest.server.testParams?
                for testParam in manifest.server.testParams
                    if file.indexOf(testParam.file) > -1
                        params += " #{testParam.param}"
            return params

        test.addTestRule addRule,
            target: _local 'unit_test'
            tests: (path.join featurePath, testFile for testFile in manifest.server.test.unit)
            runner: "$(MOCHA_RUNNER) -R sternchen #{test.MOCHA_COMPILER}"
            extraDependencies: [_local('build'), _local('pre_unit_test')]
            paramLookup: _getParams
    else
        addRule
            targets: _local 'unit_test'

    addPhonyRule addRule, _local 'unit_test'

    addRule
        targets: _local 'test'
        dependencies: _local 'unit_test'

    addPhonyRule addRule, _local 'test'

    addRule
        targets: 'unit_test'
        dependencies: _local 'unit_test'
