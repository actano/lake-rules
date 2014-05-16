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
exports.addRules = (config, manifest, ruleBook) ->

    return if not manifest.client?.htdocs?.html?

    buildPath = path.join config.featureBuildDirectory, config.featurePath # build/lib/foobar
    _src = (script) -> path.join config.featurePath, script
    _dst = (script) -> path.join buildPath, script
    _featureDep = (localDep) -> path.normalize(_src(localDep))
    _featureBuildDep = (localDep) ->
        component.getTargets(path.normalize(path.join(config.featureBuildDirectory, localDep)), 'component')
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

    ruleBook.addRule
        targets: "#{config.featurePath}/htdocs"
        dependencies: jadeTargets
    addPhonyRule ruleBook, "#{config.featurePath}/htdocs"

    ruleBook.addRule
        targets: "htdocs"
        dependencies: "#{config.featurePath}/htdocs"
    addPhonyRule ruleBook, "htdocs"
