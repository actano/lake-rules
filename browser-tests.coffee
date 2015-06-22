# Std library
path = require 'path'

# Local dep
coffee = require './helper/coffeescript'
Rule = require './helper/rule'
{config} = require './lake/config'

# Rule dep
componentBuild = require('./component-build')
component = require('./component')

exports.title = 'browser-tests'
exports.readme =
    name: 'browser-tests'
    path: path.join __dirname, 'browser-tests.md'
exports.description = "browser tests: compile jade to html, use jquery and sinon"

exports.addRules = (_config, manifest) ->

    return unless manifest.client?.tests?.browser?.scripts?

    featurePath = manifest.featurePath
    buildPath = path.join config.featureBuildDirectory, featurePath
    componentBuildTargets = componentBuild.getComponentBuildTargets buildPath

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _local = (target) -> path.join featurePath, target
    _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))
    _makeArray = (value) -> [].concat(value or [])

    clientTestScriptTargets = []
    for script in [].concat manifest.client.tests.browser.scripts
        target = coffee.addCoffeeRule _src(script), _dest(script)
        clientTestScriptTargets.push target

    jadeDeps = _makeArray(manifest.client.tests.browser.dependencies)
    includes = jadeDeps.concat(_makeArray(manifest.client?.templates?.dependencies)).concat(['.']).map((dep) -> "--include #{_featureDep(dep)}").join(' ')
    localDeps = jadeDeps.map (dep)->
        component.getComponentTarget path.join(config.featureBuildDirectory, _featureDep(dep))

    lDeps = require './local-deps'

    jadeHtmlDependencies = clientTestScriptTargets.concat(localDeps)
    jadeHtmlDependencies.push componentBuildTargets.target
    testsBrowserDependencies = manifest.client?.tests?.browser?.dependencies
    if testsBrowserDependencies?
        jadeHtmlDependencies.push lDeps.addDependencyRules manifest.featurePath, testsBrowserDependencies

    reportFile = _local 'browser-test.xml'

    new Rule _local 'client_test'
        .prerequisite jadeHtmlDependencies
        .prerequisite clientTestScriptTargets
        .prerequisite componentBuildTargets.target
        .phony()
        .buildServer 'karma', null, null, reportFile, componentBuildTargets.targetDst, clientTestScriptTargets...
        .write()

    new Rule _local 'test'
        .prerequisite _local 'client_test'
        .phony()
        .write()

    new Rule 'client_test'
        .prerequisite _local 'client_test'
        .write()
