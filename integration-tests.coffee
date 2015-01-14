# Std library
path = require 'path'

# Local dep
{addMkdirRule} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'
test = require './helper/test'

exports.title = 'integration tests'
exports.description = "integration tests with mocha"
exports.readme =
    name: 'integration-tests'
    path: path.join __dirname, 'integration-tests.md'
exports.addRules = (config, manifest, ruleBook) ->

    _local = (target) -> path.join config.featurePath, target

    testTargets = []

    # integration test target
    if manifest.server?.test?.integration?
        testTargets.push test.addTestRule ruleBook,
            target: _local 'integration_mocha_test'
            tests: (path.join config.featurePath, testFile for testFile in manifest.server.test.integration)
            runner: "$(INTEGRATION_RUNNER) -r sternchen"
            phony: yes

    # casper test target
    if manifest.integrationTests?.casper?
        testTargets.push test.addTestRule ruleBook,
            target: _local 'integration_casper_test'
            tests: (path.join config.featurePath, testFile  for testFile in manifest.integrationTests.casper)
            runner: '$(MOCHACASPERJS) --cookies-file=lib/testutils/casper-cookies.txt --expect --reporter=sternchen'
            phony: yes

    # add dependencies to general targets
    if testTargets.length > 0
        ruleBook.addRule
            targets: _local 'integration_test'
            dependencies: testTargets
        addPhonyRule ruleBook, _local 'integration_test'

        ruleBook.addRule
            targets: _local 'test'
            dependencies: _local 'integration_test'
        addPhonyRule ruleBook, _local 'test'

        ruleBook.addRule
            targets: 'integration_test'
            dependencies: _local 'integration_test'
