# Std library
path = require 'path'

# Local dep
{
    replaceExtension
} = require "./rulebook_helper"

exports.title = 'jade'
exports.description = "compile jade to js and to HTML"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join lake.featureBuildDirectory, featurePath # lib/foobar/build

    # TODO this belongs to component rules
    if manifest.client?.templates?
        if manifest.client?.mixins?.require
            options = "--obj '#{JSON.stringify(mixins: manifest.client.mixins.require)}'"
        else
            options = ""

        for jadeTemplate in manifest.client.templates
            do (jadeTemplate) ->
                rb.addRule "jade.template.#{jadeTemplate}", ["client", "jade-partials", 'component-build-prerequisite'], ->
                    targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                    dependencies: path.join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p $(@D)"
                        "$(JADEREQUIRE) #{options} --out \"$@\" \"$<\""
                    ]
