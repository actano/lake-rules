# Std library
path = require 'path'

# Local dep
{replaceExtension} = require "./rulebook_helper"

exports.title = 'translations'
exports.description = "compile translation phrases from coffee to js"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory 

    if manifest.client?.translations?

        for languageCode, script of manifest.client.translations
            ((languageCode, script) ->
                scriptPath = path.join buildPath, script
                scriptDirPath = path.dirname scriptPath
                rb.addRule "translation-#{languageCode}", ["client", 'component-build-prerequisite'], ->
                    targets: replaceExtension scriptPath, '.js'
                    dependencies: path.join featurePath, script
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{scriptDirPath} $^"
            )(languageCode, script)
