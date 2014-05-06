{
    replaceExtension
    addCopyRule
    addMkdirRule
    addPhonyRule
    concatPaths
    addMkdirRuleOfFile
} = require "../rulebook_helper"
testHelper = require '../test_helper'
path = require 'path'
_ = require 'underscore'

exports.description = 'JavaScript code coverage'
exports.readme =
    name: 'coverage'
    path: path.join __dirname, 'coverage.md'
exports.addRules = (lake, featurePath, manifest, rb) ->
    buildPath = path.join manifest.projectRoot, 'build', 'server', featurePath
    reportPath = path.join lake.coveragePath, "report", featurePath # build/coverage/report/lib/feature/
    instrumentedBase = path.join lake.coveragePath, "instrumented"  # build/coverage/instrumented/
    instrumentedPath = path.join instrumentedBase, featurePath      # build/coverage/instrumented/lib/feature/

    _local = (target) -> path.join featurePath, target
    _src = (script) -> path.join featurePath, script
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

                rb.addRule target, [], ->
                    targets: target
                    dependencies: [dep, '|', targetDir]
                    actions: "$(ISTANBUL) instrument --no-compact --output #{target} #{dep}"

                instrumentedFiles.push target

        rb.addRule _local('instrument'), [], ->
            targets: _local 'instrument'
            dependencies: instrumentedFiles

        addPhonyRule rb, _local 'instrument'

        rb.addRule 'instrument (local)', [], ->
            targets: 'instrument'
            dependencies: _local 'instrument'

    {tests, assets} = testHelper.addCopyRulesForTests rb, manifest, _src, _instrumentedAsset, _instrumentedAsset

    rb.addRule 'pre_coverage (tests)', [], ->
        targets: 'pre_coverage'
        dependencies: tests

    rb.addRule 'pre_coverage (assets)', [], ->
        targets: 'pre_coverage'
        dependencies: assets

    addPhonyRule rb, 'pre_coverage'

    if tests.length > 0
        coverageTarget = path.join featurePath, "coverage"
        addPhonyRule rb, coverageTarget

        rb.addRule 'feature_coverage', [], ->
            targets: 'feature_coverage'
            dependencies: coverageTarget

        rb.addRule coverageTarget, [], ->
            targets: coverageTarget
            dependencies: ['instrument', 'pre_coverage']
            actions: "-$(ISTANBUL_TEST_RUNNER) -p #{path.resolve instrumentedBase} -o #{reportPath} #{tests.join ' '}"
