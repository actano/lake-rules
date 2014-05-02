# Std library
path = require 'path'

# Local dep
{
    replaceExtension
    addPhonyRule
} = require "../rulebook_helper"

{componentBuildTarget} = require('./component')

exports.title = 'client htdocs'
exports.description = "build htdocs entries and adds a component build output"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    return if not manifest.client?.htdocs?.html?

    buildPath = path.join lake.featureBuildDirectory, featurePath # build/local_component/lib/foobar
    target =  path.join buildPath, replaceExtension(manifest.client.htdocs.html, '.html')
    targetDst = path.dirname target

    componentBuild = componentBuildTarget(buildPath)
    relativeComponentDir = path.relative targetDst, componentBuild.targetDst

    if manifest.client.htdocs.dependencies?
        htDocDependencies = [].concat(manifest.client.htdocs.dependencies).map (dep) ->
            path.resolve(path.join(featurePath, dep))
    else
        htDocDependencies = []

    ruleBook.addRule target, [], ->
        targets: target
        dependencies: [
            path.join featurePath, manifest.client.htdocs.html
            componentBuild.target
            htDocDependencies
        ]
        actions: [
            "$(JADEC) $< --pretty --out #{targetDst} " + \
                "--obj '#{JSON.stringify({componentDir: relativeComponentDir})}'"
        ]

    ruleBook.addRule "#{featurePath}/htdocs", [], ->
        targets: "#{featurePath}/htdocs"
        dependencies: target
    addPhonyRule ruleBook, "#{featurePath}/htdocs"

    ruleBook.addRule "htdocs", [], ->
        targets: "htdocs"
        dependencies: "#{featurePath}/htdocs"
    addPhonyRule ruleBook, "htdocs"
