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

exports.addRules = (manifest) ->

    return unless manifest.client?.tests?.browser?.scripts?

    featurePath = manifest.featurePath
    buildPath = path.join config.featureBuildDirectory, featurePath
    componentBuildTargets = componentBuild.getComponentBuildTargets buildPath

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _local = (target) -> path.join featurePath, target
    _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))
    _makeArray = (value) -> [].concat(value or [])

    jadeDeps = _makeArray(manifest.client.tests.browser.dependencies)
    localDeps = jadeDeps.map (dep)->
        component.getComponentTarget path.join(config.featureBuildDirectory, _featureDep(dep))

    lDeps = require './local-deps'

    jadeHtmlDependencies = localDeps
    testsBrowserDependencies = manifest.client?.tests?.browser?.dependencies
    if testsBrowserDependencies?
        jadeHtmlDependencies.push lDeps.addDependencyRules manifest.featurePath, testsBrowserDependencies

    clientTestRule = new Rule _local 'client_test'
    for script in _makeArray manifest.client.tests.browser.scripts
        src = _src script
        dest = coffee.addCoffeeRule src, _dest script
        ruleName = src.slice 0, -path.extname(src).length
        new Rule ruleName
            .prerequisite dest
            .prerequisite componentBuildTargets.target
            .prerequisite jadeHtmlDependencies
            .phony()
            .buildServer 'karma', null, null, "#{src}.xml", componentBuildTargets.targetDst, '$<'
            .ifndef 'WEBPACK'
            .write()

        new Rule "#{ruleName}"
            .buildServer 'karma-webpack'
            .prerequisite src
            .phony()
            .ifdef 'WEBPACK'
            .write()

        new Rule 'test/karma'
            .prerequisite src
            .phony()
            .ifdef 'WEBPACK'
            .write()

        clientTestRule.prerequisite ruleName

    clientTestRule.phony().write()

    new Rule _local 'test'
        .prerequisite _local 'client_test'
        .phony()
        .write()

    new Rule 'client_test'
        .prerequisite _local 'client_test'
        .write()
