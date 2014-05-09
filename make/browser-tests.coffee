# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRule, addMkdirRuleOfFile} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addJadeHtmlRule} = require '../helper/jade'
coffee = require '../helper/coffeescript'

component = require('./component')

exports.title = 'browser-tests'
exports.readme =
    name: 'browser-tests'
    path: path.join __dirname, 'browser-tests.md'
exports.description =
    "browser tests: compile jade to html, use jquery and sinon"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    return if not (manifest.client?.tests?.browser?.html? and manifest.client?.tests?.browser?.scripts?)

    _src = (script) -> path.join featurePath, script
    _dest = (script) -> path.join buildPath, script


    _compileJadeToHtml = (jadeTarget, jadeFile, jadeDeps, jadeObj, componentBuildTargets) ->
        source = path.join featurePath, jadeFile
        targetDst = path.dirname jadeTarget
        jadeObj.componentDir = path.relative targetDst, componentBuildTargets.targetDst
        extraDeps = [componentBuildTargets.target, jadeDeps]
        addJadeHtmlRule ruleBook, source, jadeTarget, jadeObj, extraDeps

        return target


    buildPath = path.join lake.featureBuildDirectory, featurePath

    clientTestScriptTargets = []
    for script in [].concat manifest.client.tests.browser.scripts
        target = coffee.addCoffeeRule ruleBook, _src(script), _dest(script)
        clientTestScriptTargets.push target
        addMkdirRuleOfFile ruleBook, target


    componentBuildTargets = component.getTargets(buildPath, 'component-build')
    jadeFile = manifest.client.tests.browser.html
    jadeTarget = path.join buildPath, 'test/test.html'
    jadeObj =
        name: manifest.name
        tests: clientTestScriptTargets.map((script) ->
            path.relative(path.dirname(jadeTarget), script)
        ).join(' ')
    _compileJadeToHtml jadeTarget, jadeFile, clientTestScriptTargets, jadeObj, componentBuildTargets
    addMkdirRuleOfFile ruleBook, jadeTarget

    # run the client test
    prefix = lake.testReportPath
    reportPath = path.join prefix, featurePath
    addMkdirRule ruleBook, reportPath
    clientTestTarget = path.join featurePath, 'client_test'
    ruleBook.addRule clientTestTarget, [], ->
        targets: clientTestTarget
        dependencies: [
            componentBuildTargets.target
            jadeTarget
            '|'
            reportPath
        ]
        actions: [
            # manifest.client.tests.browser.html is
            # 'test/test.jade' --convert to--> 'test.html'
            "PREFIX=#{prefix} REPORT_FILE=#{path.join featurePath, 'browser-test.xml'} $(CASPERJS) lib/testutils/browser-wrapper.coffee #{jadeTarget}"
        ]
    addPhonyRule ruleBook, clientTestTarget

    _addPhonyTarget = (target, dependencies) ->
        ruleBook.addRule target + '_bt', [], ->
            targets: target
            dependencies: dependencies
        addPhonyRule ruleBook, target

    _addPhonyTarget path.join(featurePath, 'test'), clientTestTarget
    _addPhonyTarget 'client_test', clientTestTarget


