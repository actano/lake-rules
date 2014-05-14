# Std library
path = require 'path'

# Local dep
{addPhonyRule} = require '../helper/phony'
{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'
{addJadeHtmlRule} = require '../helper/jade'

# Rule dep
componentBuild = require('./component-build')
component = require('./component')

exports.title = 'client htdocs'
exports.description = "build htdocs entries and adds a component build output"
exports.readme =
    name: 'htdocs'
    path: path.join __dirname, 'htdocs.md'
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    return if not manifest.client?.htdocs?.html?

    buildPath = path.join lake.featureBuildDirectory, featurePath # build/lib/foobar
    _src = (script) -> path.join featurePath, script
    _dst = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(_src(localDep))
    _featureBuildDep = (localDep) ->
        component.getTargets(path.normalize(path.join(lake.featureBuildDirectory, localDep)), 'component')
    _makeArray = (value) -> [].concat(value or [])

    jadeDeps = _makeArray(manifest.client.htdocs.dependencies).map(_featureDep)
    componentBuildTargets = componentBuild.getTargets(buildPath, 'component-build')

    _compileJadeToHtml = (jadeFile) ->
        source = _src(jadeFile)
        target =  _dst(replaceExtension(jadeFile, '.html'))
        object =
            componentDir: path.relative(path.dirname(target), componentBuildTargets.targetDst)
        jadeBuildDeps = jadeDeps.map(_featureBuildDep).concat(componentBuildTargets.target)
        includes = jadeDeps.map((dep) -> "--include #{dep}").join(' ')
        addJadeHtmlRule ruleBook, source, target, object, jadeBuildDeps, includes
        return target

    jadeTargets = _makeArray(manifest.client.htdocs.html).map (jadeFile)->
        jadeTarget = _compileJadeToHtml(jadeFile)
        addMkdirRuleOfFile ruleBook, jadeTarget
        return jadeTarget

    ruleBook.addRule "#{featurePath}/htdocs", [], ->
        targets: "#{featurePath}/htdocs"
        dependencies: jadeTargets
    addPhonyRule ruleBook, "#{featurePath}/htdocs"

    ruleBook.addRule "htdocs", [], ->
        targets: "htdocs"
        dependencies: "#{featurePath}/htdocs"
    addPhonyRule ruleBook, "htdocs"
