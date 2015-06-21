# Std library
path = require 'path'

# Local dep
Rule = require './helper/rule'
{replaceExtension, addMkdirRuleOfFile, addCopyRule} = require './helper/filesystem'

_targets = (config, manifest) ->
    buildPath = path.join config.featureBuildDirectory, config.featurePath
    src = (script) -> path.join config.featurePath, script
    dst = (script) -> path.join buildPath, script

    targets = []
    for languageCode, script of manifest.client.translations
        targets.push
            src: src script
            dst: dst script

    # first target is index.js (generated without src)
    targets.unshift {dst: dst 'translations/index.js'} unless targets.length == 0
    return targets

exports.title = 'translations'
exports.readme =
    name: 'translations'
    path: path.join __dirname, 'translations.md'
exports.description = "compile translation phrases from coffee to js"
exports.addRules = (config, manifest) ->
    return unless manifest.client?.translations?

    manifestPath = path.join config.featurePath, 'Manifest.coffee'

    targets = _targets config, manifest

    indexPath = targets.shift().dst
    new Rule indexPath
        .prerequisite manifestPath
        .mkdir()
        .action "$(NODE_BIN)/coffee #{path.join __dirname, 'create_translations_index.coffee'}  #{manifestPath} > $@"
        .write()

    for {src, dst} in targets
        addCopyRule src, dst

exports.getTargets = (config, manifest, tag) ->
    throw new Error("Unknown tag #{tag}") unless tag == 'scripts'
    return (target.dst for target in _targets config, manifest)
