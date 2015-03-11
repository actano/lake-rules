# Std library
path = require 'path'

# Local dep
{replaceExtension, addCopyRule, addMkdirRule, addMkdirRuleOfFile} = require './helper/filesystem'
{addCopyRulesForTests} = require './helper/test'
{addPhonyRule} = require './helper/phony'

COVERAGE = '$(BUILD)/coverage'

exports.description = 'JavaScript code coverage'
exports.readme =
    name: 'coverage'
    path: path.join __dirname, 'coverage.md'
exports.addRules = (config, manifest, rb) ->
    buildPath = path.join '$(SERVER)', config.featurePath
    reportPath = path.join COVERAGE, 'report', config.featurePath # build/coverage/report/lib/feature/
    instrumentedBase = path.join COVERAGE, 'instrumented'  # build/coverage/instrumented/
    instrumentedPath = path.join instrumentedBase, config.featurePath        # build/coverage/instrumented/lib/feature/

    _local = (target) -> path.join config.featurePath, target
    _src = (script) -> path.join config.featurePath, script
    _dst = (script) -> path.join buildPath, replaceExtension(script, '.js')
    _instrumented = (script) -> path.normalize path.join instrumentedPath, replaceExtension(script, '.js')
    _instrumentedAsset = (script) -> path.join instrumentedPath, script

    if manifest.server?.scripts?.files?
        instrumentedFiles = []

        for script in manifest.server.scripts.files
            do (script) ->
                dep = _dst script
                target = _instrumented script
                targetDir = path.dirname target

                addMkdirRule rb, targetDir

                rb.addRule
                    targets: target
                    dependencies: [dep, '|', targetDir]
                    actions: "$(NODE_BIN)/istanbul instrument --no-compact --output #{target} #{dep}"

                instrumentedFiles.push target

        rb.addRule
            targets: _local 'instrument'
            dependencies: instrumentedFiles

        addPhonyRule rb, _local 'instrument'

        rb.addRule
            targets: 'instrument'
            dependencies: _local 'instrument'

    {tests, assets} = addCopyRulesForTests rb, manifest, _src, _instrumentedAsset, _instrumentedAsset

    rb.addRule
        targets: 'pre_coverage'
        dependencies: tests

    rb.addRule
        targets: 'pre_coverage'
        dependencies: assets

    addPhonyRule rb, 'pre_coverage'
    addPhonyRule rb, _local "coverage"

    if tests.length > 0
        rb.addRule
            targets: 'feature_coverage'
            dependencies: _local "coverage"

        rb.addRule
            targets: _local "coverage"
            dependencies: ['instrument', 'pre_coverage']
            actions: "-$(COFFEE) #{path.join __dirname, 'mocha_istanbul_test_runner.coffee'} -p #{path.resolve instrumentedBase} -o #{reportPath} #{tests.join ' '}"
    else
        # add standard target even if nothing has to be done
        rb.addRule
            targets: _local "coverage"
