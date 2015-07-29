# Std library
path = require 'path'

# Local dep
{replaceExtension, addCopyRule} = require './helper/filesystem'
{addCoffeeRule} = require './helper/coffeescript'
{createTestRule} = require './helper/test'

Rule = require './helper/rule'
{config} = require './lake/config'

exports.description = "build a rest-api feature"
exports.readme =
    name: 'rest-api'
    path: path.join __dirname, 'rest-api.md'
exports.addRules = (manifest) ->
    return if not manifest.server?

    featurePath = manifest.featurePath

    _local = (target) -> path.join featurePath, target

    rule = new Rule _local 'unit_test'
        .prerequisiteOf _local 'test'
        .prerequisiteOf 'unit_test'
        .phony()

    if manifest.server?.test?.unit?
        for testFile in manifest.server.test.unit
            test = path.join featurePath, testFile
            testRule = createTestRule test, '$(MOCHA_RUNNER)'
                .write()

            new Rule path.join '$(BUILD)/mocha-unit-test.opts'
                .prerequisite test
                .write()
            rule.prerequisite testRule

    rule.write()

