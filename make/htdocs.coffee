# Std library
path = require 'path'

# Local dep
{
replaceExtension
addPhonyRule
} = require "./rulebook_helper"

{componentBuildRules} = require('./make/component')

exports.title = 'htdocs'
exports.description = "build htdocs entries and adds a component build output"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join lake.featureBuildDirectory, featurePath # lib/foobar/build

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root

    if manifest.htdocs?
        htDocTargets = []
        for key, htDocItem of manifest.htdocs
            continue if not htDocItem.html?
            target =  path.join buildPath, key, path.basename(replaceExtension(htDocItem.html, '.html'))
            htDocTargets.push target
            do (key, htDocItem) ->

                componentBuildRules(rb, manifest.name, buildPath, key)

                rb.addRule "htdocs.#{key}", ["htdocs", "client", "feature"], ->
                    if htDocItem.dependencies?.templates?
                        htDocDependencies = [].concat(htDocItem.dependencies.templates).map (dep) ->
                            path.resolve(path.join(featurePath, dep))
                    else
                        htDocDependencies = []

                    targets: target
                    dependencies: [
                        path.join featurePath, htDocItem.html
                        htDocDependencies
                    ]
                    actions: [
                        "$(JADEC) $< --pretty  --out #{buildPath}/#{key}"
                    ]

            rb.addRule "#{featurePath}/htdocs", [], ->
                targets: "#{featurePath}/htdocs"
                dependencies: htDocTargets
            addPhonyRule ruleBook, "#{featurePath}/htdocs"

            rb.addRule "htdocs", [], ->
                targets: "htdocs"
                dependencies: htDocTargets
            addPhonyRule ruleBook, "htdocs"
