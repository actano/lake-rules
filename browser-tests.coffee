# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRule, addMkdirRuleOfFile} = require './helper/filesystem'
{addPhonyRule} = require './helper/phony'
{addJadeHtmlRule} = require './helper/jade'
{addTestRule} = require './helper/test'
coffee = require './helper/coffeescript'
Rule = require './helper/rule'

# Rule dep
componentBuild = require('./component-build')
component = require('./component')

exports.title = 'browser-tests'
exports.readme =
    name: 'browser-tests'
    path: path.join __dirname, 'browser-tests.md'
exports.description = "browser tests: compile jade to html, use jquery and sinon"

exports.jadeTarget = (config, manifest) ->
    return if not (manifest.client?.tests?.browser?.html? and manifest.client?.tests?.browser?.scripts?)
    featurePath = config.featurePath
    buildPath = path.join config.featureBuildDirectory, featurePath
    return path.join buildPath, 'test/test.html'

exports.addRules = (config, manifest, addRule) ->

    return if not (manifest.client?.tests?.browser?.html? and manifest.client?.tests?.browser?.scripts?)

    featurePath = config.featurePath
    buildPath = path.join config.featureBuildDirectory, featurePath
    componentBuildTargets = componentBuild.getTargets(buildPath, 'component-build')

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _local = (target) -> path.join featurePath, target
    _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))
    _makeArray = (value) -> [].concat(value or [])

    clientTestScriptTargets = []
    for script in [].concat manifest.client.tests.browser.scripts
        target = coffee.addCoffeeRule addRule, _src(script), _dest(script)
        clientTestScriptTargets.push target

    # compile browser html to test/test.html
    jadeTarget = path.join buildPath, 'test/test.html' # TODO use export
    jadeObj =
        name: manifest.name
        tests: clientTestScriptTargets.map((script) ->
            path.relative(path.dirname(jadeTarget), script)
        ).join(' ')
        componentDir: path.relative path.dirname(jadeTarget), componentBuildTargets.targetDst
    jadeDeps = _makeArray(manifest.client.tests.browser.dependencies)
    includes = jadeDeps.concat(_makeArray(manifest.client?.templates?.dependencies)).concat(['.']).map((dep) -> "--include #{_featureDep(dep)}").join(' ')
    localDeps = jadeDeps.map (dep)->
        component.getTargets(path.join(config.featureBuildDirectory, _featureDep(dep)), 'component')

    lDeps = require './local-deps'

    jadeHtmlDependencies = clientTestScriptTargets.concat(localDeps)
    jadeHtmlDependencies.push componentBuildTargets.target
    testsBrowserDependencies = manifest.client?.tests?.browser?.dependencies
    if testsBrowserDependencies?
        jadeHtmlDependencies.push lDeps.addDependencyRules addRule, config.featurePath, testsBrowserDependencies

    addJadeHtmlRule addRule, _src(manifest.client.tests.browser.html), jadeTarget, jadeObj, jadeHtmlDependencies, includes

    reportFile = _local 'browser-test.xml'

    rule = new Rule _local 'client_test'
        .prerequisite jadeTarget
        .prerequisite clientTestScriptTargets
        .prerequisite componentBuildTargets.target
        .phony()

    rule.buildServer 'karma', null, null, reportFile, componentBuildTargets.targetDst, clientTestScriptTargets...

    addRule rule

    addRule
        targets: _local 'test'
        dependencies: _local 'client_test'
    addPhonyRule addRule, _local 'test'

    addRule
        targets: 'client_test'
        dependencies: _local 'client_test'
