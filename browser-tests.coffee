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
    _src = (script) -> path.join featurePath, script
    _scriptRuleName = (script) ->
        src = _src script
        src.slice 0, -path.extname(src).length

    _makeArray = (value) -> [].concat(value or [])
    testScripts = _makeArray manifest.client.tests.browser.scripts
    localClientTest = _src 'client_test'

    karmaComponent = ->
        buildPath = path.join config.featureBuildDirectory, featurePath
        componentBuildTargets = componentBuild.getComponentBuildTargets buildPath

        _dest = (script) -> path.join buildPath, script
        _featureDep = (localDep) -> path.normalize(path.join(featurePath, localDep))

        jadeDeps = _makeArray(manifest.client.tests.browser.dependencies)
        localDeps = jadeDeps.map (dep)->
            component.getComponentTarget path.join(config.featureBuildDirectory, _featureDep(dep))

        lDeps = require './local-deps'

        jadeHtmlDependencies = localDeps
        testsBrowserDependencies = manifest.client?.tests?.browser?.dependencies
        if testsBrowserDependencies?
            jadeHtmlDependencies.push lDeps.addDependencyRules manifest.featurePath, testsBrowserDependencies

        clientTestRule = new Rule localClientTest
        for script in testScripts
            src = _src script
            dest = coffee.addCoffeeRule src, _dest script
            ruleName = _scriptRuleName script
            new Rule ruleName
                .prerequisite dest
                .prerequisite componentBuildTargets.target
                .prerequisite jadeHtmlDependencies
                .phony()
                .buildServer 'karma', null, null, "#{src}.xml", componentBuildTargets.targetDst, '$<'
                .write()

            clientTestRule.prerequisite ruleName

        clientTestRule.phony().write()
        new Rule 'client_test'
            .prerequisite localClientTest
            .write()

    karmaWebpack = ->
        clientTestRule = new Rule localClientTest
        for script in testScripts
            src = _src script
            ruleName = _scriptRuleName script

            new Rule "#{ruleName}"
                .buildServer 'karma-webpack', null, '$^'
                .prerequisite src
                .phony()
                .write()

            clientTestRule.prerequisite ruleName

        clientTestRule.phony().write()
        new Rule 'client_test'
            .prerequisite localClientTest
            .write()

    karmaWebpackStatic = ->
        clientTestRule = new Rule localClientTest
        for script in testScripts
            ruleName = _scriptRuleName script

            entry = path.normalize _src script
            entry = entry.replace /\//g, '__'
            entry = entry.substring 0, entry.length - path.extname(entry).length
            pre = path.join '$(BUILD)', 'client', entry

            new Rule ruleName
                .buildServer 'karma-webpack', null, '$^'
                .prerequisite "#{pre}.css"
                .prerequisite "#{pre}.js"
                .phony()
                .write()

            clientTestRule.prerequisite ruleName

        clientTestRule.phony().write()

        new Rule 'client_test'
            .prerequisite localClientTest
            .write()


    karmaWebpackSingle = ->
        globalRule = new Rule '$(BUILD)/karma.coffee'

        clientTestRule = new Rule localClientTest
            .buildServer 'karma-single', null, '$^'

        for script in testScripts
            src = _src script
            ruleName = _scriptRuleName script

            new Rule "#{ruleName}"
                .buildServer 'karma-single', null, '$^'
                .prerequisite src
                .phony()
                .write()

            clientTestRule.prerequisite src
            globalRule.prerequisite src

        clientTestRule.phony().write()
        globalRule.write()

    new Rule _src 'test'
        .prerequisite localClientTest
        .phony()
        .write()

    Rule.writable.write 'ifeq "$(WEBPACK)" "karma-static"\n'
    karmaWebpackStatic()
    Rule.writable.write 'endif\n'

    Rule.writable.write 'ifeq "$(WEBPACK)" "karma-single"\n'
    karmaWebpackSingle()
    Rule.writable.write 'endif\n'

    Rule.writable.write 'ifdef WEBPACK\n'
    Rule.writable.write 'ifneq "$(WEBPACK)" "karma-static"\n'
    Rule.writable.write 'ifneq "$(WEBPACK)" "karma-single"\n'
    karmaWebpack()
    Rule.writable.write 'endif\n'
    Rule.writable.write 'endif\n'
    Rule.writable.write 'endif\n'

    Rule.writable.write 'ifndef WEBPACK\n'
    karmaComponent()
    Rule.writable.write 'endif\n'
