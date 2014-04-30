{addCopyRule} = require './rulebook_helper'

module.exports.addCopyRulesForTests = (ruleBook, manifest, src, dst) ->
    tests = []
    assets = []

    # tests
    if manifest.server?.test?.unit?
        for file in manifest.server.test.unit
            tests.push addCopyRule(ruleBook, src(file), dst(file))

    # integration tests
    if manifest.server?.test?.integration?
        for file in manifest.server.test.integration
            tests.push addCopyRule(ruleBook, src(file), dst(file))

    # test assets
    if manifest.server?.test?.assets?
        for file in manifest.server.test.assets
            assets.push addCopyRule(ruleBook, src(file), dst(file))

    # test exports
    if manifest.server?.test?.exports?
        for file in manifest.server.test.exports
            assets.push addCopyRule(ruleBook, src(file), dst(file))

    return {tests: tests, assets: assets}
