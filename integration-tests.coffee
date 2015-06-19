# Std library
path = require 'path'

# Local dep
{replaceExtension} = require './helper/filesystem'
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
            addTestRule rule, "#{RUNNER} #{test}", replaceExtension(test, '.xml')
        rule.write()

        # add dependencies to general targets
        new Rule _local 'integration_test'
            .prerequisite target
            .write()

        new Rule _local 'test'
            .prerequisite _local 'integration_test'
            .write()

        new Rule 'integration_test'
            .prerequisite _local 'integration_test'
            .write()

