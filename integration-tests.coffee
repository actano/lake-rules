# Std library
path = require 'path'

# Local dep
{concatPaths} = require "./rulebook_helper"

exports.title = 'integration tests'
exports.description = "integration tests with mocha-phantom"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    if manifest.integrationTests?.mocha? or manifest.integrationTests?.casper?
        rb.addToGlobalTarget "integration_test", rb.addRule "integration-test", ["test"], ->
            targets: path.join featurePath ,'integration_test'
            dependencies: [
                rb.getRuleById("server_itest", {}).targets
                rb.getRuleById("casperjs", {}).targets
            ]

    prefix = lake.testReportPath
    reportPath = path.join prefix, featurePath

    if manifest.integrationTests?.mocha?
        rb.addRule 'server_itest', [], ->
            rule = {
                targets: path.join featurePath, 'server_itest'
                dependencies: [rb.getRuleById("feature").targets]
                actions: concatPaths manifest.integrationTests.mocha, {pre: featurePath}, (testFile) ->
                    basename = path.basename testFile, path.extname testFile
                    "PREFIX=#{prefix} REPORT_FILE=#{path.join featurePath, basename}.xml $(MOCHA) -R $(MOCHA_REPORTER) $(MOCHA_COMPILER) #{testFile}"
            }

            rule.actions.unshift "mkdir -p #{reportPath}"

            return rule

    if manifest.integrationTests?.casper?
        rb.addRule 'casperjs', [], ->
            rule = {
                targets: path.join featurePath, 'casper_test'
                dependencies: [rb.getRuleById("feature").targets]
                actions: concatPaths manifest.integrationTests.casper, {pre: featurePath}, (testFile) ->
                    basename = path.basename testFile, path.extname testFile
                    "PREFIX=#{prefix} REPORT_FILE=#{path.join featurePath, basename}.xml $(CASPERJS) --cookies-file=lib/testutils/casper-cookies.txt --expect --reporter=sternchen #{testFile}"
            }

            rule.actions.unshift "mkdir -p #{reportPath}"

            return rule