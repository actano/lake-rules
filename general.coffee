# Std library
path = require 'path'

exports.title = 'general'
exports.description = "general rules (build, test-all, clean)"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build

    rb.addToGlobalTarget "build", rb.addRule "feature", [], ->
        targets: featurePath
        dependencies: rule.targets for rule in rb.getRulesByTag("feature")

    rb.addRule "test-all", [], ->
        targets: path.join featurePath, "all_test"
        dependencies: rule.targets for rule in rb.getRulesByTag("test")

    rb.addToGlobalTarget "feature_clean", rb.addRule "clean", [], ->
        targets: path.join featurePath, "clean"
        actions: "rm -rf #{buildPath}"
