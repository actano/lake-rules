# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'
{addCoffeeRule} = require '../helper/coffeescript'

_targets = (config, manifest) ->
    buildPath = path.join config.featureBuildDirectory, config.featurePath
    src = (script) -> path.join config.featurePath, script
    dst = (script) -> path.join buildPath, script

    targets = []
    for languageCode, script of manifest.client.translations
        targets.push
            src: src script
            dst: replaceExtension dst(script), '.js'

    # first target is index.js (generated without src)
    targets.unshift {dst: dst 'translations/index.js'} unless targets.length == 0
    return targets

exports.title = 'translations'
exports.readme =
    name: 'translations'
    path: path.join __dirname, 'translations.md'
exports.description = "compile translation phrases from coffee to js"
exports.addRules = (config, manifest, rb) ->
    return unless manifest.client?.translations?

    manifestPath = path.join config.featurePath, 'Manifest.coffee'

    targets = _targets config, manifest

    indexPath = targets.shift().dst
    indexDir = addMkdirRuleOfFile rb, indexPath
    rb.addRule
        targets: indexPath
        dependencies: [manifestPath, '|', indexDir]
        actions: "$(NODE_BIN)/coffee $(TOOLS)/rules/make/create_translations_index.coffee #{manifestPath} > $@"

    for {src, dst} in targets
        addCoffeeRule rb, src, dst

exports.getTargets = (config, manifest, tag) ->
    throw new Error("Unknown tag #{tag}") unless tag == 'scripts'
    return (target.dst for target in _targets config, manifest)
