# Std library
path = require 'path'

# Local dep
{addMkdirRule} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addTestRule} = require '../helper/test'

exports.title = 'integration tests'
exports.description = "integration tests with mocha"
exports.readme =
    name: 'integration-tests'
    path: path.join __dirname, 'integration-tests.md'
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    reportBasePath = lake.testReportPath
    featureReportPath = path.join reportBasePath, featurePath

    testTargets = []
    if manifest.server?.test?.integration?
        integrationTestTarget = path.join featurePath, 'integration_mocha_test'
        addPhonyRule ruleBook, integrationTestTarget
        testTargets.push integrationTestTarget

        testFiles = (path.join featurePath, testFile for testFile in manifest.server.test.integration)
        addTestRule ruleBook, integrationTestTarget, testFiles

    if manifest.integrationTests?.casper?
        addMkdirRule ruleBook, featureReportPath
        casperTestTarget = path.join featurePath, 'integration_casper_test'
        testTargets.push casperTestTarget
        addPhonyRule ruleBook, casperTestTarget
        ruleBook.addRule casperTestTarget, [], ->
            targets: casperTestTarget
            dependencies: ['|', featureReportPath]
            actions: manifest.integrationTests.casper.map (testFile) ->
                basename = path.basename testFile, path.extname testFile
                testPath = path.join featurePath, testFile
                "PREFIX=#{reportBasePath} REPORT_FILE=#{path.join featurePath, basename}.xml " +
                    "$(MOCHACASPERJS) --cookies-file=lib/testutils/casper-cookies.txt --expect --reporter=sternchen #{testPath}"


    _addPhonyTarget = (target, dependencies) ->
        ruleBook.addRule target + '_it', [], ->
            targets: target
            dependencies: dependencies
        addPhonyRule ruleBook, target

    if testTargets.length > 0
        _addPhonyTarget(path.join(featurePath, 'integration_test'), testTargets)
        _addPhonyTarget(path.join(featurePath, 'test'), testTargets)
        _addPhonyTarget('integration_test', testTargets)
