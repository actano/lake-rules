{
    replaceExtension
    addCopyRule
    addMkdirRule
    addPhonyRule
    concatPaths
    addMkdirRuleOfFile
} = require "../rulebook_helper"
path = require 'path'
_ = require 'underscore'

exports.addRules = (lake, featurePath, manifest, rb) ->
    buildPath = path.join lake.featureBuildDirectory, featurePath
    reportPath = path.join lake.coveragePath, "report", featurePath # build/coverage/report/lib/feature/
    instrumentedBase = path.join lake.coveragePath, "instrumented"  # build/coverage/instrumented/
    instrumentedPath = path.join instrumentedBase, featurePath      # build/coverage/instrumented/lib/feature/

    _local = (target) -> path.join featurePath, target
    _src = (script) -> path.join featurePath, script
    _dst = (script) -> path.join buildPath, 'server_scripts', replaceExtension(script, '.js')
    _instrumented = (target) -> path.normalize path.join instrumentedPath, replaceExtension(target, '.js')

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

    testFilesForCoverage = []

    if manifest.server?.tests?
        for test in manifest.server.tests
            src = path.join featurePath, test
            dst = path.join instrumentedPath, test
            addCopyRule rb, src, dst
            testFilesForCoverage.push dst
    if manifest.integrationTests?.mocha?
        for test in manifest.integrationTests.mocha
            src = path.join featurePath, test
            dst = path.join instrumentedPath, test
            addCopyRule rb, src, dst
            testFilesForCoverage.push dst

    if testFilesForCoverage.length > 0
        coverageTarget = path.join featurePath, "coverage"
        addPhonyRule rb, coverageTarget

        rb.addRule "feature_coverage", [], ->
            targets: "feature_coverage"
            dependencies: coverageTarget

        rb.addRule coverageTarget, [], ->
            targets: coverageTarget
            dependencies: ["instrument", "pre_coverage"].concat testFilesForCoverage
            actions: "-$(ISTANBUL_TEST_RUNNER) -p #{path.resolve instrumentedBase} -o #{reportPath} #{testFilesForCoverage.join ' '}"

    addCopyRules = (files, id) ->
        targets = []

        for file in files
            src = _src file
            dst = path.join instrumentedPath, file
            addCopyRule rb, src, dst
            targets.push dst

        rb.addRule id, [], ->
            targets: "pre_coverage"
            dependencies: targets

    # test assets

    if manifest.server?.testAssets?
        addCopyRules manifest.server.testAssets, "pre_coverage (assets)"

    # test dependencies

    if manifest.server?.testDependencies?
        addCopyRules manifest.server.testDependencies, "pre_coverage (test dependencies)"
