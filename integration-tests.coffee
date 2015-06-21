# Std library
path = require 'path'

# Local dep
{replaceExtension} = require './helper/filesystem'
{createTestRule} = require './helper/test'
Rule = require './helper/rule'

exports.title = 'integration tests'
exports.description = "integration tests with mocha"
exports.readme =
    name: 'integration-tests'
    path: path.join __dirname, 'integration-tests.md'
exports.addRules = (config, manifest) ->

    _local = (target) -> path.join config.featurePath, target

    # integration test target
    if manifest.server?.test?.integration?
        target = _local 'integration_mocha_test'
        rule = new Rule target
            .phony()

        for testFile in manifest.server.test.integration
            test = path.join config.featurePath, testFile
            rule.prerequisite createTestRule(test, '$(INTEGRATION_RUNNER)').write()

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

