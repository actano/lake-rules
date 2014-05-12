# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRule, addMkdirRuleOfFile} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addJadeHtmlRule} = require '../helper/jade'
{addTestRule} = require '../helper/test'
coffee = require '../helper/coffeescript'

component = require('./component')

exports.title = 'browser-tests'
exports.readme =
    name: 'browser-tests'
    path: path.join __dirname, 'browser-tests.md'
exports.description = "browser tests: compile jade to html, use jquery and sinon"

exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    return if not (manifest.client?.tests?.browser?.html? and manifest.client?.tests?.browser?.scripts?)

    buildPath = path.join lake.featureBuildDirectory, featurePath
    componentBuildTargets = component.getTargets(buildPath, 'component-build')

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script
    _local = (target) -> path.join featurePath, target

    clientTestScriptTargets = []
    for script in [].concat manifest.client.tests.browser.scripts
        target = coffee.addCoffeeRule ruleBook, _src(script), _dest(script)
        clientTestScriptTargets.push target

    # compile browser html to test/test.html
    jadeTarget = path.join buildPath, 'test/test.html'
    jadeObj =
        name: manifest.name
        tests: clientTestScriptTargets.map((script) ->
            path.relative(path.dirname(jadeTarget), script)
        ).join(' ')
        componentDir: path.relative path.dirname(jadeTarget), componentBuildTargets.targetDst
    addJadeHtmlRule ruleBook,
        path.join(featurePath, manifest.client.tests.browser.html),
        jadeTarget,
        jadeObj,
        clientTestScriptTargets.concat [componentBuildTargets.target]

    # run the client test
    addTestRule ruleBook,
        target: _local 'client_test'
        runner: '$(CASPERJS) lib/testutils/browser-wrapper.coffee'
        tests: [jadeTarget]
        report: path.join(featurePath, 'browser-test.xml')
        extraDependencies: [jadeTarget, componentBuildTargets.target]
        phony: yes

    ruleBook.addRule _local('test'), [], ->
        targets: _local 'test'
        dependencies: _local 'client_test'
    addPhonyRule ruleBook, _local 'test'

    ruleBook.addRule 'client_test', [], ->
        targets: 'client_test'
        dependencies: _local 'client_test'
