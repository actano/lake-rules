# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRule} = require './helper/filesystem'
{addCopyRulesForTests} = require './helper/test'
Rule = require './helper/rule'

COVERAGE = '$(BUILD)/coverage'

exports.description = 'JavaScript code coverage'
exports.readme =
    name: 'coverage'
    path: path.join __dirname, 'coverage.md'
exports.addRules = (_config, manifest) ->
    buildPath = path.join '$(SERVER)', manifest.featurePath
    reportPath = path.join COVERAGE, 'report', manifest.featurePath # build/coverage/report/lib/feature/
    instrumentedBase = path.join COVERAGE, 'instrumented'  # build/coverage/instrumented/
    instrumentedPath = path.join instrumentedBase, manifest.featurePath        # build/coverage/instrumented/lib/feature/

    _local = (target) -> path.join manifest.featurePath, target
    _src = (script) -> path.join manifest.featurePath, script
    _dst = (script) -> path.join buildPath, replaceExtension(script, '.js')
    _instrumented = (script) -> path.normalize path.join instrumentedPath, replaceExtension(script, '.js')
    _instrumentedAsset = (script) -> path.join instrumentedPath, script

    if manifest.server?.scripts?.files?
        instrumentRule = new Rule _local 'instrument'
            .phony()

        for script in manifest.server.scripts.files
            do (script) ->
                dep = _dst script
                target = _instrumented script
                targetDir = path.dirname target

                addMkdirRule targetDir

                new Rule target
                    .prerequisite dep
                    .orderOnly targetDir
                    .action "$(NODE_BIN)/istanbul instrument --no-compact --output #{target} #{dep}"
                    .write()

                instrumentRule.prerequisite target

        instrumentRule.write()

        new Rule 'instrument'
            .prerequisite _local 'instrument'
            .write()

    {tests, assets} = addCopyRulesForTests manifest, _src, _instrumentedAsset, _instrumentedAsset

    new Rule 'pre_coverage'
        .prerequisite tests
        .prerequisite assets
        .phony()
        .write()

    rule = new Rule _local 'coverage'
        .phony()

    if tests.length > 0
        rule
            .prerequisiteOf 'feature_coverage'
            .prerequisite ['instrument', 'pre_coverage']
            .action "-$(COFFEE) #{path.join __dirname, 'mocha_istanbul_test_runner.coffee'} -p #{path.resolve instrumentedBase} -o #{reportPath} #{tests.join ' '}"
    rule.write()