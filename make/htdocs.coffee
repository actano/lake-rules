# Std library
path = require 'path'

# Local dep
{addPhonyRule} = require '../helper/phony'
{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'
{addJadeHtmlRule} = require '../helper/jade'

# Rule dep
componentBuild = require('./component-build')

exports.title = 'client htdocs'
exports.description = "build htdocs entries and adds a component build output"
exports.readme =
    name: 'htdocs'
    path: path.join __dirname, 'htdocs.md'
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    return if not manifest.client?.htdocs?.html?

    _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))
    _makeArray = (value) -> [].concat(value or [])

    _compileJadeToHtml = (jadeFile, jadeDeps, componentBuildTargets) ->
        includes = jadeDeps.map((dep) -> "--include #{dep}").join(' ')
        localDeps = jadeDeps.map((dep) -> path.join(dep, 'Manifest.coffee'))
        source = path.join featurePath, jadeFile
        target =  path.join buildPath, replaceExtension(jadeFile, '.html')
        targetDst = path.dirname target
        relativeComponentDir = path.relative targetDst, componentBuildTargets.targetDst
        object = {componentDir: relativeComponentDir}
        extraDeps = [componentBuildTargets.target, jadeDeps].concat localDeps
        addJadeHtmlRule ruleBook, source, target, object, extraDeps, includes
        return target


    buildPath = path.join lake.featureBuildDirectory, featurePath # build/local_component/lib/foobar

    jadeDeps = _makeArray(manifest.client.htdocs.dependencies).map(_featureDep)

    jadeTargets = []
    componentBuildTargets = componentBuild.getTargets(buildPath, 'component-build')
    for jadeFile in [].concat(manifest.client.htdocs.html)
        jadeTarget = _compileJadeToHtml(jadeFile, jadeDeps, componentBuildTargets)
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
