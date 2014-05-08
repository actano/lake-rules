# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'

_targets = (lake, manifest) ->
    buildPath = path.join lake.featureBuildDirectory, manifest.featurePath
    dst = (script) -> path.join buildPath, 'translations', script

    targets = []
    for languageCode, script of manifest.client.translations
        targets.push
            src: path.join manifest.featurePath, script
            dst: dst "#{languageCode}.js"

    # first target is index.js (generated without src)
    targets.unshift {dst: dst 'index.js'} unless targets.length == 0
    return targets

exports.title = 'translations'
exports.description = "compile translation phrases from coffee to js"
exports.addRules = (lake, featurePath, manifest, rb) ->
    return unless manifest.client?.translations?

    manifestPath = path.join featurePath, 'Manifest.coffee'

    targets = _targets lake, manifest

    indexPath = targets.shift().dst
    indexDir = addMkdirRuleOfFile rb, indexPath
    rb.addRule 'translation index', [], ->
        targets: indexPath
        dependencies: [manifestPath, '|', indexDir]
        actions: "$(TRANSLATION_INDEX_GENERATOR) < #{manifestPath} > $@"

    for {src, dst} in targets
        do (src, dst) ->
            dstPath = addMkdirRuleOfFile rb, dst
            rb.addRule dst, [], ->
                targets: dst
                dependencies: [src, '|', dstPath]
                actions: "$(COFFEEC) $(COFFEE_FLAGS) --compile --stdio < $< > $@"

exports.getTargets = (lake, manifest, tag) ->
    throw new Error("Unknown tag #{tag}") unless tag == 'scripts'
    return (target.dst for target in _targets lake, manifest)
