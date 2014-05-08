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
