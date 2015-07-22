# Std library
path = require 'path'

# Local dep
coffee = require './helper/coffeescript'
Rule = require './helper/rule'
{config} = require './lake/config'

# Rule dep
component = require('./component')

exports.title = 'browser-tests'
exports.readme =
    name: 'browser-tests'
    path: path.join __dirname, 'browser-tests.md'
exports.description = "browser tests: run karma tests"

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

    karmaWebpackSingle = ->
        globalRule = new Rule '$(BUILD)/karma.coffee'

        clientTestRule = new Rule localClientTest
            .buildServer 'karma', null, '$^'

        for script in testScripts
            src = _src script
            ruleName = _scriptRuleName script

            new Rule "#{ruleName}"
                .buildServer 'karma', null, '$^'
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

    karmaWebpackSingle()
