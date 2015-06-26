path = require 'path'
Rule = require './rule'
fs = require './filesystem'

prefix = '$(TEST_REPORTS)'

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

module.exports.createTestRule = (test, runner) ->
    dir = path.dirname test
    base = path.basename test, path.extname test
    new Rule "#{path.join dir, base}"
        .phony()
        .orderOnly fs.addMkdirRule path.join '$(TEST_REPORTS)', dir
        .action "PREFIX=$(TEST_REPORTS) REPORT_FILE=$@.xml MAKE_TARGET=$@ #{runner} #{test}"
