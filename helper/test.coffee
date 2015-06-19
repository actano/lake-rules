path = require 'path'
fs = require './filesystem'

prefix = '$(TEST_REPORTS)'

module.exports.MOCHA_COMPILER = '--compilers coffee:coffee-script/register'

module.exports.addCopyRulesForTests = (manifest, src, dstTest, dstAsset) ->
    tests = []
    assets = []

    # tests
    if manifest.server?.test?.unit?
        for file in manifest.server.test.unit
            tests.push fs.addCopyRule(src(file), dstTest(file))

    # integration tests
    if manifest.server?.test?.integration?
        for file in manifest.server.test.integration
            tests.push fs.addCopyRule(src(file), dstTest(file))

    # test assets
    if manifest.server?.test?.assets?
        for file in manifest.server.test.assets
            assets.push fs.addCopyRule(src(file), dstAsset(file))

    # test exports
    if manifest.server?.test?.exports?
        for file in manifest.server.test.exports
            assets.push fs.addCopyRule(src(file), dstAsset(file))

    return {tests: tests, assets: assets}

module.exports.addTestRule = (rule, cmd, report) ->
    p = fs.addMkdirRuleOfFile path.join prefix, report
    rule.orderOnly p
    # PREFIX / REPORT_FILE are commonly used by reporters to derive outputFile (prefix + report_file) AND 'class'name (report_file)
    rule.action "PREFIX=$(TEST_REPORTS) REPORT_FILE=#{report} MAKE_TARGET=$@ #{cmd}"

    return rule
