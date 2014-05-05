# Std library
path = require 'path'

# Local dep
{
    replaceExtension
    addPhonyRule
    addMkdirRuleOfFile
} = require "../rulebook_helper"

{componentBuildTarget} = require('./component')

exports.title = 'client htdocs'
exports.description = "build htdocs entries and adds a component build output"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    return if not manifest.client?.htdocs?.html?

    _compileJadeToHtml = (jadeFile, jadeDeps, componentBuild) ->
        target =  path.join buildPath, replaceExtension(jadeFile, '.html')
        targetDst = path.dirname target
        relativeComponentDir = path.relative targetDst, componentBuild.targetDst
        ruleBook.addRule target, [], ->
            targets: target
            dependencies: [
                path.join featurePath, jadeFile
                componentBuild.target
                jadeDeps
            ].concat ['|', targetDst]
            actions: [
                "$(JADEC) $< --pretty --out #{targetDst} --obj '#{JSON.stringify({componentDir: relativeComponentDir})}'"
            ]
        target


    buildPath = path.join lake.featureBuildDirectory, featurePath # build/local_component/lib/foobar
    componentBuild = componentBuildTarget(buildPath)

    if manifest.client.htdocs.dependencies?
        htDocDependencies = [].concat(manifest.client.htdocs.dependencies).map (dep) ->
            path.resolve(path.join(featurePath, dep))
    else
        htDocDependencies = []

    jadeTargets = []
    for jadeFile in [].concat(manifest.client.htdocs.html)
        jadeTarget = _compileJadeToHtml(jadeFile, htDocDependencies, componentBuild)
        addMkdirRuleOfFile ruleBook, jadeTarget
        jadeTargets.push jadeTarget

    ruleBook.addRule "#{featurePath}/htdocs", [], ->
        targets: "#{featurePath}/htdocs"
        dependencies: jadeTargets
    addPhonyRule ruleBook, "#{featurePath}/htdocs"

    ruleBook.addRule "htdocs", [], ->
        targets: "htdocs"
        dependencies: "#{featurePath}/htdocs"
    addPhonyRule ruleBook, "htdocs"
