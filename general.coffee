# Std library
path = require 'path'

{addPhonyRule} = require './helper/phony'

exports.title = 'general'
exports.description = "general rules"
exports.addRules = (lake, featurePath, manifest, rb) ->

    _local = (target) -> path.join featurePath, target

    ###
    rb.addRule "test-all", [], ->
        targets: path.join featurePath, "all_test"
        dependencies: (rule.targets for rule in rb.getRulesByTag("test"))
    ###

    rb.addRule _local('clean'), [], ->
        targets: _local 'clean'
        actions: [
            "rm -rf #{path.join manifest.projectRoot, 'build', 'server', featurePath}"
            "rm -rf #{path.join manifest.projectRoot, 'build', 'client', featurePath}"
            "rm -rf #{path.join manifest.projectRoot, 'build', 'local_components', featurePath}"
        ]

    addPhonyRule rb, _local 'clean'

    rb.addRule 'feature_clean', [], ->
        targets: 'feature_clean'
        dependencies: _local 'clean'
