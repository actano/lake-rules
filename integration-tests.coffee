# Std library
path = require 'path'

# Local dep
{addMkdirRule, replaceExtension} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'
{addTestRule,MOCHA_COMPILER} = require './helper/test'
Rule = require './helper/rule'

RUNNER = "$(MOCHA_MULTI) $(MOCHA_RUNNER) --reporter $(REPORTER) -t 20000 #{MOCHA_COMPILER} $(INTEGRATION_HOOKS)"

exports.title = 'integration tests'
exports.description = "integration tests with mocha"
exports.readme =
    name: 'integration-tests'
    path: path.join __dirname, 'integration-tests.md'
exports.addRules = (config, manifest, addRule) ->

    _local = (target) -> path.join config.featurePath, target

    testTargets = []

    # integration test target
    if manifest.server?.test?.integration?
        target = _local 'integration_mocha_test'
        testTargets.push target
        rule = new Rule target
            .phony()
        for testFile in manifest.server.test.integration
            test = path.join config.featurePath, testFile
            addTestRule addRule, rule, "#{RUNNER} #{test}", replaceExtension(test, '.xml')
        addRule rule

    # add dependencies to general targets
    if testTargets.length > 0
        addRule
            targets: _local 'integration_test'
            dependencies: testTargets
        addPhonyRule addRule, _local 'integration_test'

        addRule
            targets: _local 'test'
            dependencies: _local 'integration_test'
        addPhonyRule addRule, _local 'test'

        addRule
            targets: 'integration_test'
            dependencies: _local 'integration_test'
