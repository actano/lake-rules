# Std library
path = require 'path'

# Third party
# TODO remove when i18n is removed
glob = require 'glob'

# Local dep
{replaceExtension, addCopyRule, addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addCoffeeRule} = require '../helper/coffeescript'
test = require '../helper/test'

exports.description = "build a rest-api feature"
exports.readme =
    name: 'rest-api'
    path: path.join __dirname, 'rest-api.md'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.server?

    if manifest.server.scripts?.dirs?
        throw new Error("Directory entries are not supported in the manifest (#{featurePath})")

    buildDependencies = []
    runtimeDependencies = []

    buildPath = path.join manifest.projectRoot, 'build', 'server', featurePath
    runtimePath = path.join lake.runtimePath, featurePath

    _src = (script) -> path.join featurePath, script
    _dst = (script) -> path.join buildPath, replaceExtension(script, '.js')
    _dstAsset = (asset) -> path.join buildPath, asset
    _run = (script) -> path.join runtimePath, replaceExtension(script, '.js')
    _local = (target) -> path.join featurePath, target

    # Build targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _src script
            dst = _dst script
            do (src, dst) ->
                buildDependencies.push dst
                addCoffeeRule rb, src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            buildDependencies.push(path.join(path.normalize(path.join(featurePath, dependency)), 'build'))

    rb.addRule 'build', [], ->
        targets: _local 'build'
        dependencies: buildDependencies
    addPhonyRule rb, _local 'build'

    # Alias to map feature to feature/build
    rb.addRule 'build alias', [], ->
        targets: featurePath
        dependencies: _local 'build'

    rb.addRule 'build (global)', [], ->
        targets: 'build'
        dependencies: _local 'build'

    # Install / Dist targets
    if manifest.server.scripts?.files?
        for script in manifest.server.scripts.files
            src = _dst script
            dst = _run script
            do (src, dst) ->
                runtimeDependencies.push dst
                addCopyRule rb, src, dst

    if manifest.server.dependencies?.production?.local?
        for dependency in manifest.server.dependencies.production.local
            runtimeDependencies.push(path.join(path.normalize(path.join(featurePath, dependency)), 'install'))

    rb.addRule 'install', [], ->
        targets: _local 'install'
        dependencies: runtimeDependencies
    addPhonyRule rb, _local 'install'

    # Test targets
    {tests, assets} = test.addCopyRulesForTests rb, manifest, _src, _dst, _dstAsset

    rb.addRule 'pre_unit_test (tests)', [], ->
        targets: _local 'pre_unit_test'
        dependencies: tests

    rb.addRule 'pre_unit_test (assets)', [], ->
        targets: _local 'pre_unit_test'
        dependencies: assets

    addPhonyRule rb, _local 'pre_unit_test'

    if manifest.server?.dependencies?.production?.local?
        test_dependencies = for dependency in manifest.server.dependencies.production.local
            path.join(path.normalize(path.join(featurePath, dependency)), 'pre_unit_test')
        rb.addRule 'pre_unit_test (dependencies)', [], ->
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

        test.addTestRule rb,
            target: _local 'unit_test'
            tests: (path.join featurePath, testFile for testFile in manifest.server.test.unit)
            runner: "$(MOCHA) -R sternchen #{test.MOCHA_COMPILER}"
            extraDependencies: [_local('build'), _local('pre_unit_test')]
            paramLookup: _getParams
    else
        rb.addRule _local('unit_test'), [], ->
            targets: _local 'unit_test'

    addPhonyRule rb, _local 'unit_test'

    rb.addRule 'unit-test (global)', [], ->
        targets: 'unit_test'
        dependencies: _local 'unit_test'
