# Std library
path = require 'path'

# Local dep
{
    replaceExtension
    addMkdirRuleOfFile
} = require "../rulebook_helper"

exports.title = 'translations'
exports.description = "compile translation phrases from coffee to js"
exports.addRules = (lake, featurePath, manifest, rb) ->
    return unless manifest.client?.translations?

    manifestPath = path.join featurePath, 'Manifest.coffee'
    buildPath = path.join lake.featureBuildDirectory, featurePath

    for languageCode, script of manifest.client.translations
        do (languageCode, script) ->
            targetPath = path.join buildPath, replaceExtension script, '.js'
            # TODO replace with addCoffeeRule once we don't need tags
            targetDir = addMkdirRuleOfFile rb, targetPath
            rb.addRule "translation-#{languageCode}", ["client", 'component-build-prerequisite', 'add-to-component-scripts'], ->
                targets: targetPath
                dependencies: [path.join(featurePath, script), '|', targetDir]
                actions: "$(COFFEEC) $(COFFEE_FLAGS) --output #{targetDir} $^"

    indexPath = path.join buildPath, 'translations', 'index.js'
    indexDir = addMkdirRuleOfFile rb, indexPath
    rb.addRule 'translation index', ["client", 'component-build-prerequisite', 'add-to-component-scripts'], ->
        targets: indexPath
        dependencies: [manifestPath, '|', indexDir]
        actions: "$(TRANSLATION_INDEX_GENERATOR) < #{manifestPath} > $@"
