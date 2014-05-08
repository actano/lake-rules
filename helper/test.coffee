path = require 'path'
fs = require './filesystem'

module.exports.addCopyRulesForTests = (ruleBook, manifest, src, dstTest, dstAsset) ->
    tests = []
    assets = []

    # tests
    if manifest.server?.test?.unit?
        for file in manifest.server.test.unit
            tests.push fs.addCopyRule(ruleBook, src(file), dstTest(file))

    # integration tests
    if manifest.server?.test?.integration?
        for file in manifest.server.test.integration
            tests.push fs.addCopyRule(ruleBook, src(file), dstTest(file))

    # test assets
    if manifest.server?.test?.assets?
        for file in manifest.server.test.assets
            assets.push fs.addCopyRule(ruleBook, src(file), dstAsset(file))

    # test exports
    if manifest.server?.test?.exports?
        for file in manifest.server.test.exports
            assets.push fs.addCopyRule(ruleBook, src(file), dstAsset(file))

    return {tests: tests, assets: assets}

MOCHA_REPORTER = 'sternchen'

# TODO remove coffee-erros after switching to coffee-script 1.6.4
MOCHA_COMPILER = '--compilers coffee:coffee-script,coffee-trc:coffee-errors'

module.exports.getTestAction = (testFile, testParams) ->
    #fullPath = path.join featurePath, testFile
    #report = path.join(featurePath, path.basename(fullPath, path.extname(fullPath))) + '.xml'

    testParams ?= ''
    report = fs.replaceExtension testFile, '.xml'

    "PREFIX=build/test_reports REPORT_FILE=#{report} $(MOCHA)#{testParams} -R #{MOCHA_REPORTER} #{MOCHA_COMPILER} #{testFile}"

module.exports.addTestRule = (ruleBook, target, testFiles, extraDependencies, paramLookup) ->
    extraDependencies ?= []
    paramLookup ?= -> ''
    actions =[]
    reportPaths = []
    prefix = path.join 'build', 'test_reports'
    for testFile in testFiles
        report = fs.replaceExtension testFile, '.xml'
        params = paramLookup testFile
        reportPaths.push fs.addMkdirRuleOfFile ruleBook, path.join prefix, report
        action = "PREFIX=#{prefix} REPORT_FILE=#{report} $(MOCHA)#{params} -R #{MOCHA_REPORTER} #{MOCHA_COMPILER} #{testFile}"
        actions.push action
    ruleBook.addRule target, [], ->
        targets: target
        dependencies: extraDependencies.concat(['|']).concat(reportPaths)
        actions: actions
    return target
