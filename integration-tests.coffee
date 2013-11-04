# Std library
path = require 'path'

# Local dep
{concatPaths} = require "./rulebook_helper"

exports.title = 'integration tests'
exports.description = "integration tests with mocha-phantom"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    if manifest.integrationTests?.mocha?
        rb.addToGlobalTarget "integration_test", rb.addRule "integration-test", ["test"], ->
            targets: path.join featurePath ,'integration_test'
            dependencies: rb.getRuleById("feature").targets
            actions: concatPaths manifest.integrationTests.mocha, {pre: featurePath}, (testFile) ->
                "$(MOCHA) -R $(MOCHA_REPORTER) $(MOCHA_COMPILER) #{testFile}"
