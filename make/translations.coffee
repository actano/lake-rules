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

    _dst = (script) -> path.join buildPath, 'translations', script

    for languageCode, script of manifest.client.translations
        do (languageCode, script) ->
            targetPath = _dst languageCode + '.js'
            targetDir = addMkdirRuleOfFile rb, targetPath
            rb.addRule "translation-#{languageCode}", [], ->
                targets: targetPath
                dependencies: [path.join(featurePath, script), '|', targetDir]
                actions: "$(COFFEEC) $(COFFEE_FLAGS) --compile --stdio < $< > $@"

    indexPath = _dst 'index.js'
    indexDir = addMkdirRuleOfFile rb, indexPath
    rb.addRule 'translation index', [], ->
        targets: indexPath
        dependencies: [manifestPath, '|', indexDir]
        actions: "$(TRANSLATION_INDEX_GENERATOR) < #{manifestPath} > $@"

exports.getTargets = (manifest, tag) ->
    throw new Error("Unknown tag #{tag}") unless tag == 'scripts'
    buildPath = path.join 'build', 'local_components', manifest.featurePath
    targets = ("#{languageCode}.js" for languageCode of manifest.client.translations)
    targets.push 'index.js' unless targets.length == 0
    return (path.join buildPath, 'translations', target for target in targets)
