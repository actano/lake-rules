path = require 'path'
fs = require './filesystem'
Rule = require './rule'

prefix = '$(TEST_REPORTS)'

# TODO remove coffee-erros after switching to coffee-script 1.6.4
module.exports.MOCHA_COMPILER = '--compilers coffee:coffee-script,coffee-trc:coffee-errors'

module.exports.addCopyRulesForTests = (addRule, manifest, src, dstTest, dstAsset) ->
    tests = []
    assets = []

    # tests
    if manifest.server?.test?.unit?
        for file in manifest.server.test.unit
            tests.push fs.addCopyRule(addRule, src(file), dstTest(file))

    # integration tests
    if manifest.server?.test?.integration?
        for file in manifest.server.test.integration
            tests.push fs.addCopyRule(addRule, src(file), dstTest(file))

    # test assets
    if manifest.server?.test?.assets?
        for file in manifest.server.test.assets
            assets.push fs.addCopyRule(addRule, src(file), dstAsset(file))

    # test exports
    if manifest.server?.test?.exports?
        for file in manifest.server.test.exports
            assets.push fs.addCopyRule(addRule, src(file), dstAsset(file))

    return {tests: tests, assets: assets}

module.exports.addTestRule = (addRule, options) ->
    options.paramLookup ?= -> ''

    rule = new Rule options.target
    rule.prerequisite options.extraDependencies if options.extraDependencies?
    for test in options.tests
        report = options.report ? fs.replaceExtension test, '.xml'
        p = fs.addMkdirRuleOfFile(addRule, path.join(prefix, report))
        rule.orderOnly p
        params = options.paramLookup test
        rule.action "PREFIX=#{prefix} REPORT_FILE=#{report} MAKE_TARGET=#{options.target} #{options.runner} #{params} #{test}"

    rule.phony() if options.phony == true

    addRule rule
    return options.target
