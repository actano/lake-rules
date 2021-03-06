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
exports.addRules = (manifest) ->

    _local = (target) -> path.join manifest.featurePath, target

    # integration test target
    if manifest.server?.test?.integration?
        target = _local 'integration_mocha_test'
        rule = new Rule target
            .phony()

        for testFile in manifest.server.test.integration
            test = path.join manifest.featurePath, testFile
            rule.prerequisite createTestRule(test, '$(INTEGRATION_RUNNER)').write()
            new Rule path.join '$(BUILD)/mocha-integration-test.opts'
                .prerequisite test
                .write()

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

