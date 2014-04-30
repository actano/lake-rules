# Std library
path = require 'path'

# Local dep
{concatPaths, addMkdirRule} = require "./rulebook_helper"

exports.title = 'integration tests'
exports.description = "integration tests with mocha-phantom"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    if manifest.server?.test?.integration? or manifest.integrationTests?.casper?
        rb.addToGlobalTarget "integration_test", rb.addRule "integration-test", ["test"], ->
            targets: path.join featurePath ,'integration_test'
            dependencies: [
                rb.getRuleById("server_itest", {}).targets
                rb.getRuleById("casperjs", {}).targets
            ]

    prefix = lake.testReportPath
    reportPath = path.join prefix, featurePath

    if manifest.server?.test?.integration?
        addMkdirRule rb, reportPath

        rb.addRule 'server_itest', [], ->
            targets: path.join featurePath, 'server_itest'
            dependencies: [ '|', reportPath]
            actions: concatPaths manifest.server.test.integration, {pre: featurePath}, (testFile) ->
                basename = path.basename testFile, path.extname testFile
                "PREFIX=#{prefix} REPORT_FILE=#{path.join featurePath, basename}.xml $(MOCHA) -R $(MOCHA_REPORTER) $(MOCHA_COMPILER) #{testFile}"

    if manifest.integrationTests?.casper?
        addMkdirRule rb, reportPath

        rb.addRule 'casperjs', [], ->
            targets: path.join featurePath, 'casper_test'
            dependencies: ['|', reportPath]
            actions: concatPaths manifest.integrationTests.casper, {pre: featurePath}, (testFile) ->
                basename = path.basename testFile, path.extname testFile
                "PREFIX=#{prefix} REPORT_FILE=#{path.join featurePath, basename}.xml $(MOCHACASPERJS) --cookies-file=lib/testutils/casper-cookies.txt --expect --reporter=sternchen #{testFile}"