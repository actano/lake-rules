path = require 'path'
fs = require './filesystem'

{addPhonyRule} = require './phony'

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
    options.extraDependencies ?= []
    options.paramLookup ?= -> ''

    prefix = '$(TEST_REPORTS)'
    actions =[]
    reportPaths = {}
    for test in options.tests
        report = options.report ? fs.replaceExtension test, '.xml'
        params = options.paramLookup test
        reportPaths[fs.addMkdirRuleOfFile(addRule, path.join(prefix, report))] = true
        action = "PREFIX=#{prefix} REPORT_FILE=#{report} MAKE_TARGET=#{options.target} #{options.runner} #{params} #{test}"
        actions.push action
    addRule
        targets: options.target
        dependencies: options.extraDependencies.concat(['|']).concat(Object.keys(reportPaths))
        actions: actions
    if options.phony == true
        addPhonyRule addRule, options.target
    return options.target
