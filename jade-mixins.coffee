# Std library
path = require 'path'

# Local dep
{
    resolveFeatureRelativePaths
    replaceExtension
    lookup
} = require "./rulebook_helper"

exports.title = 'jade-mixins'
exports.description = "compile jade to js and extract mixins to be requirable"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root

    if manifest.client?.mixins?.export?
        for jadeTemplate in manifest.client.mixins.export
            ((jadeTemplate) ->
                rb.addRule "jade.mixin.#{jadeTemplate}", ["client", "jade-partials", 'component-build-prerequisite', 'add-to-component-scripts'], ->
                    targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                    dependencies: path.join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p $(@D)"
                        "$(JADEMIXIN) < $< > $@"

                    ]
            )(jadeTemplate)

